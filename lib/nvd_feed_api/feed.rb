# frozen_string_literal: true

# Ruby internal
require 'digest'
require 'net/https'
require 'date'
# External
require 'archive/zip'
require 'oj'
# Project internal
require 'nvd_feed_api/meta'

class NVDFeedScraper
  # Feed object.
  class Feed
    class << self
      # Get / set default feed storage location, where will be stored JSON feeds and archives by default.
      # @return [String] default feed storage location. Default to `/tmp/`.
      # @example
      #   NVDFeedScraper::Feed.default_storage_location = '/srv/downloads/'
      attr_accessor :default_storage_location
    end
    @default_storage_location = '/tmp/'

    # @return [String] the name of the feed.
    # @example
    #   'CVE-2007'
    attr_reader :name

    # @return [String] the last update date of the feed information on the NVD website.
    # @example
    #   '10/19/2017 3:27:02 AM -04:00'
    attr_reader :updated

    # @return [String] the URL of the metadata file of the feed.
    # @example
    #   'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2007.meta'
    attr_reader :meta_url

    # @return [String] the URL of the gz archive of the feed.
    # @example
    #   'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2007.json.gz'
    attr_reader :gz_url

    # @return [String] the URL of the zip archive of the feed.
    # @example
    #   'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2007.json.zip'
    attr_reader :zip_url

    # @return [Meta] the {Meta} object of the feed.
    # @note
    #   Return nil if not previously loaded by {#meta_pull}.
    #   Note that {#json_pull} also calls {#meta_pull}.
    # @example
    #   s = NVDFeedScraper.new
    #   s.scrap
    #   f = s.feeds("CVE-2014")
    #   f.meta # => nil
    #   f.meta_pull
    #   f.meta # => #<NVDFeedScraper::Meta:0x00555b53027570 ... >
    attr_reader :meta

    # @return [String] the path of the saved JSON file.
    # @note Return nil if not previously loaded by {#json_pull}.
    # @example
    #   s = NVDFeedScraper.new
    #   s.scrap
    #   f = s.feeds("CVE-2014")
    #   f.json_file # => nil
    #   f.json_pull
    #   f.json_file # => "/tmp/nvdcve-1.0-2014.json"
    attr_reader :json_file

    # @return [String] the type of the feed, should always be `CVE`.
    # @note Return nil if not previously loaded by {#json_pull}.
    attr_reader :data_type

    # @return [String] the format of the feed, should always be `MITRE`.
    # @note Return nil if not previously loaded by {#json_pull}.
    attr_reader :data_format

    # @return [Float] the version of the JSON schema of the feed.
    # @note Return nil if not previously loaded by {#json_pull}.
    attr_reader :data_version

    # @return [Integer] the number of CVEs of in the feed.
    # @note Return nil if not previously loaded by {#json_pull}.
    attr_reader :data_number_of_cves

    # @return [Date] the date of the last update of the feed by the NVD.
    # @note Return nil if not previously loaded by {#json_pull}.
    attr_reader :data_timestamp

    # A new instance of Feed.
    # @param name [String] see {#name}.
    # @param updated [String] see {#updated}.
    # @param meta_url [String] see {#meta_url}.
    # @param gz_url [String] see {#gz_url}.
    # @param zip_url [String] see {#zip_url}.
    def initialize(name, updated, meta_url, gz_url, zip_url)
      # From meta file
      @name = name
      @updated = updated
      @meta_url = meta_url
      @gz_url = gz_url
      @zip_url = zip_url
      # do not pull meta and json automatically for speed and memory footprint
      @meta = nil
      @json_file = nil
      # feed data
      @data_type = nil
      @data_format = nil
      @data_version = nil
      @data_number_of_cves = nil
      @data_timestamp = nil
    end

    # Create or update the {Meta} object (fill the attribute).
    # @return [Meta] the updated {Meta} object of the feed.
    # @see #meta
    def meta_pull
      meta_content = NVDFeedScraper::Meta.new(@meta_url)
      meta_content.parse
      # update @meta
      @meta = meta_content
    end

    # Download the gz archive of the feed.
    # @param opts [Hash] see {#download_file}.
    # @return [String] the saved gz file path.
    # @example
    #   afeed.download_gz
    #   afeed.download_gz(destination_path: '/srv/save/')
    def download_gz(opts = {})
      download_file(@gz_url, opts)
    end

    # Download the zip archive of the feed.
    # @param opts [Hash] see {#download_file}.
    # @return [String] the saved zip file path.
    # @example
    #   afeed.download_zip
    #   afeed.download_zip(destination_path: '/srv/save/')
    def download_zip(opts = {})
      download_file(@zip_url, opts)
    end

    # Download the JSON feed and fill the attribute.
    # @param opts [Hash] see {#download_file}.
    # @return [String] the path of the saved JSON file. Default use {Feed#default_storage_location}.
    # @note Will download and save the zip of the JSON file, unzip and save it. This massively consume time.
    # @see #json_file
    def json_pull(opts = {})
      opts[:destination_path] ||= Feed.default_storage_location

      skip_download = false
      destination_path = opts[:destination_path]
      destination_path += '/' unless destination_path[-1] == '/'
      filename = URI(@zip_url).path.split('/').last.chomp('.zip')
      # do not use @json_file for destination_file because of offline loading
      destination_file = destination_path + filename
      meta_pull
      if File.file?(destination_file)
        # Verify hash to see if it is the latest
        computed_h = Digest::SHA256.file(destination_file)
        skip_download = true if meta.sha256.casecmp(computed_h.hexdigest).zero?
      end
      if skip_download
        @json_file = destination_file
        # Set data
        if @data_type.nil?
          doc = Oj::Doc.open(File.read(@json_file))
          @data_type = doc.fetch('/CVE_data_type')
          @data_format = doc.fetch('/CVE_data_format')
          @data_version = doc.fetch('/CVE_data_version').to_f
          @data_number_of_cves = doc.fetch('/CVE_data_numberOfCVEs').to_i
          @data_timestamp = Date.strptime(doc.fetch('/CVE_data_timestamp'), '%FT%RZ')
          doc.close
        end
      else
        zip_path = download_zip(opts)
        Archive::Zip.open(zip_path) do |z|
          z.extract(destination_path, flatten: true)
        end
        @json_file = zip_path.chomp('.zip')
        # Verify hash integrity
        computed_h = Digest::SHA256.file(@json_file)
        raise "File corruption: #{@json_file}" unless meta.sha256.casecmp(computed_h.hexdigest).zero?

        # update data
        doc = Oj::Doc.open(File.read(@json_file))
        @data_type = doc.fetch('/CVE_data_type')
        @data_format = doc.fetch('/CVE_data_format')
        @data_version = doc.fetch('/CVE_data_version').to_f
        @data_number_of_cves = doc.fetch('/CVE_data_numberOfCVEs').to_i
        @data_timestamp = Date.strptime(doc.fetch('/CVE_data_timestamp'), '%FT%RZ')
        doc.close
      end
      return @json_file
    end

    # Search for CVE in the feed.
    # @overload cve(cve)
    #   One CVE.
    #   @param cve [String] CVE ID, case insensitive.
    #   @return [Hash] a Ruby Hash corresponding to the CVE.
    # @overload cve(cve_arr)
    #   An array of CVEs.
    #   @param cve_arr [Array<String>] Array of CVE ID, case insensitive.
    #   @return [Array] an Array of CVE, each CVE is a Ruby Hash. May not be in the same order as provided.
    # @overload cve(cve, *)
    #   Multiple CVEs.
    #   @param cve [String] CVE ID, case insensitive.
    #   @param * [String] As many CVE ID as you want.
    #   @return [Array] an Array of CVE, each CVE is a Ruby Hash. May not be in the same order as provided.
    # @note {#json_pull} is needed before using this method. Remember you're searching only in the current feed.
    # @todo implement a CVE Class instead of returning a Hash.
    # @see https://scap.nist.gov/schema/nvd/feed/0.1/nvd_cve_feed_json_0.1_beta.schema
    # @see https://scap.nist.gov/schema/nvd/feed/0.1/CVE_JSON_4.0_min.schema
    # @example
    #   s = NVDFeedScraper.new
    #   s.scrap
    #   f = s.feeds("CVE-2014")
    #   f.json_pull
    #   f.cve("CVE-2014-0002", "cve-2014-0001")
    def cve(*arg_cve)
      raise 'json_file is nil, it needs to be populated with json_pull' if @json_file.nil?
      raise "json_file (#{@json_file}) doesn't exist" unless File.file?(@json_file)

      return_value = nil
      raise 'no argument provided, 1 or more expected' if arg_cve.empty?

      if arg_cve.length == 1
        case arg_cve[0]
        when String
          raise "bad CVE name (#{arg_cve[0]})" unless /^CVE-[0-9]{4}-[0-9]{4,}$/i.match?(arg_cve[0])

          doc = Oj::Doc.open(File.read(@json_file))
          # Quicker than doc.fetch('/CVE_Items').size
          (1..@data_number_of_cves).each do |i|
            if arg_cve[0].upcase == doc.fetch("/CVE_Items/#{i}/cve/CVE_data_meta/ID")
              return_value = doc.fetch("/CVE_Items/#{i}")
              break
            end
          end
          doc.close
        when Array
          return_value = []
          # Sorting CVE can allow us to parse quicker
          # Upcase to be sure include? works
          cves_to_find = arg_cve[0].map(&:upcase).sort
          raise 'one of the provided arguments is not a String' unless cves_to_find.all? { |x| x.is_a?(String) }
          raise 'bad CVE name' unless cves_to_find.all? { |x| /^CVE-[0-9]{4}-[0-9]{4,}$/i.match?(x) }

          doc = Oj::Doc.open(File.read(@json_file))
          # Quicker than doc.fetch('/CVE_Items').size
          (1..@data_number_of_cves).each do |i|
            doc.move("/CVE_Items/#{i}")
            cve_id = doc.fetch('cve/CVE_data_meta/ID')
            if cves_to_find.include?(cve_id)
              return_value.push(doc.fetch)
              cves_to_find.delete(cve_id)
            elsif cves_to_find.empty?
              break
            end
          end
          raise "#{cves_to_find.join(', ')} are unexisting CVEs in this feed" unless cves_to_find.empty?
        else
          raise "the provided argument (#{arg_cve[0]}) is nor a String or an Array"
        end
      else
        # Overloading a list of arguments as one array argument
        return_value = cve(arg_cve)
      end
      return return_value
    end

    # Return a list with the name of all available CVEs in the feed.
    # Can only be called after {#json_pull}.
    # @return [Array<String>] List with the name of all available CVEs. May return thousands CVEs.
    def available_cves
      raise 'json_file is nil, it needs to be populated with json_pull' if @json_file.nil?
      raise "json_file (#{@json_file}) doesn't exist" unless File.file?(@json_file)

      doc = Oj::Doc.open(File.read(@json_file))
      # Quicker than doc.fetch('/CVE_Items').size
      cve_names = []
      (1..@data_number_of_cves).each do |i|
        doc.move("/CVE_Items/#{i}")
        cve_names.push(doc.fetch('cve/CVE_data_meta/ID'))
      end
      doc.close
      return cve_names
    end

    # @param arg_name [String] the new name of the feed.
    # @return [String] the new name of the feed.
    # @example
    #   'CVE-2007'
    def name=(arg_name)
      raise "name (#{arg_name}) is not a string" unless arg_name.is_a?(String)

      @name = arg_name
    end

    # @param arg_updated [String] the last update date of the feed information on the NVD website.
    # @return [String] the new date.
    # @example
    #   '10/19/2017 3:27:02 AM -04:00'
    def updated=(arg_updated)
      raise "updated date (#{arg_updated}) is not a string" unless arg_updated.is_a?(String)

      @updated = arg_updated
    end

    # @param arg_meta_url [String] the new URL of the metadata file of the feed.
    # @return [String] the new URL of the metadata file of the feed.
    # @example
    #   'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2007.meta'
    def meta_url=(arg_meta_url)
      raise "meta_url (#{arg_meta_url}) is not a string" unless arg_meta_url.is_a?(String)

      @meta_url = arg_meta_url
    end

    # @param arg_gz_url [String] the new URL of the gz archive of the feed.
    # @return [String] the new URL of the gz archive of the feed.
    # @example
    #   'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2007.json.gz'
    def gz_url=(arg_gz_url)
      raise "gz_url (#{arg_gz_url}) is not a string" unless arg_gz_url.is_a?(String)

      @gz_url = arg_gz_url
    end

    # @param arg_zip_url [String] the new URL of the zip archive of the feed.
    # @return [String] the new URL of the zip archive of the feed.
    # @example
    #   'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2007.json.zip'
    def zip_url=(arg_zip_url)
      raise "zip_url (#{arg_zip_url}) is not a string" unless arg_zip_url.is_a?(String)

      @zip_url = arg_zip_url
    end

    # Download a file.
    # @param file_url [String] the URL of the file.
    # @param opts [Hash] the optional downlaod parameters.
    # @option opts [String] :destination_path the destination path (may
    #   overwrite existing file).
    #   Default use {Feed#default_storage_location}.
    # @option opts [String] :sha256 the SHA256 hash to check, if the file
    #   already exist and the hash matches then the download will be skipped.
    # @return [String] the saved file path.
    # @example
    #   download_file('https://example.org/example.zip') # => '/tmp/example.zip'
    #   download_file('https://example.org/example.zip', destination_path: '/srv/save/') # => '/srv/save/example.zip'
    #   download_file('https://example.org/example.zip', {destination_path: '/srv/save/', sha256: '70d6ea136d5036b6ce771921a949357216866c6442f44cea8497f0528c54642d'}) # => '/srv/save/example.zip'
    def download_file(file_url, opts = {})
      opts[:destination_path] ||= Feed.default_storage_location
      opts[:sha256] ||= nil

      destination_path = opts[:destination_path]
      destination_path += '/' unless destination_path[-1] == '/'
      skip_download = false
      uri = URI(file_url)
      filename = uri.path.split('/').last
      destination_file = destination_path + filename
      if !opts[:sha256].nil? && File.file?(destination_file)
        # Verify hash to see if it is the latest
        computed_h = Digest::SHA256.file(destination_file)
        skip_download = true if opts[:sha256].casecmp(computed_h.hexdigest).zero?
      end
      unless skip_download
        res = Net::HTTP.get_response(uri)
        raise "#{file_url} ended with #{res.code} #{res.message}" unless res.is_a?(Net::HTTPSuccess)

        File.binwrite(destination_file, res.body)
      end
      return destination_file
    end

    # Update the feed
    # @param fresh_feed [Feed] the fresh feed from which the feed will be updated.
    # @return [Boolean] `true` if the feed was updated, `false` if it wasn't.
    # @note Is not intended to be used directly, use {NVDFeedScraper#update_feeds} instead.
    def update!(fresh_feed)
      return_value = false
      raise "#{fresh_feed} is not a Feed" unless fresh_feed.is_a?(Feed)

      # update attributes
      if updated != fresh_feed.updated
        self.name = fresh_feed.name
        self.updated = fresh_feed.updated
        self.meta_url = fresh_feed.meta_url
        self.gz_url = fresh_feed.gz_url
        self.zip_url = fresh_feed.zip_url
        # update if @meta was set
        meta_pull unless @meta.nil?
        # update if @json_file was set, this will also update @data_*
        json_pull unless @json_file.nil?
        return_value = true
      end
      return return_value
    end

    protected :name=, :updated=, :meta_url=, :gz_url=, :zip_url=, :download_file
  end
end
