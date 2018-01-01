# @author Alexandre ZANNI <alexandre.zanni@engineer.com>

require 'net/https'
require 'nokogiri'
require 'nvd_feed_api/version'
require 'archive/zip'
require 'oj'
require 'digest'

# The class that parse NVD website to get information.
# @example Initialize a NVDFeedScraper object, get the feeds and see them:
#   scraper = NVDFeedScraper.new
#   scraper.scrap
#   scraper.available_feeds
#   scraper.feeds
#   scraper.feeds("CVE-2007")
#   cve2007, cve2015 = scraper.feeds("CVE-2007", "CVE-2015")
class NVDFeedScraper
  # The NVD url where is located the data feeds.
  URL = 'https://nvd.nist.gov/vuln/data-feeds'.freeze
  # Load constants
  include NvdFeedApi

  # Feed object.
  class Feed
    class << self
      # Get / set default feed storage location, where will be stored JSON feeds and archives by default.
      # @return [String] default feed storage location. Default to +/tmp/+.
      # @example
      #   NVDFeedScraper::Feed.default_storage_location = '/srv/downloads/'
      attr_accessor :default_storage_location
    end
    @default_storage_location = '/tmp'

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

    # A new instance of Feed.
    # @param name [String] see {#name}.
    # @param updated [String] see {#updated}.
    # @param meta_url [String] see {#meta_url}.
    # @param gz_url [String] see {#gz_url}.
    # @param zip_url [String] see {#zip_url}.
    def initialize(name, updated, meta_url, gz_url, zip_url)
      @name = name
      @updated = updated
      @meta_url = meta_url
      @gz_url = gz_url
      @zip_url = zip_url
      # do not pull meta and json automatically for speed and memory footprint
      @meta = nil
      @json_file = nil
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
    #   download('~/Downloads/')
    def download_gz(opts = {})
      download_file(@gz_url, opts)
    end

    # Download the zip archive of the feed.
    # @param opts [Hash] see {#download_file}.
    # @return [String] the saved zip file path.
    # @example
    #   download_zip('~/Downloads/')
    def download_zip(opts = {})
      download_file(@zip_url, opts)
    end

    # Download the JSON feed and fill the attribute.
    # @param opts [Hash] see {#download_file}.
    # @return [String] the path of the saved JSON file. Default use {Feed#default_storage_location}.
    # @note Will downlaod and save the zip of the JSON file, unzip and save it. This massively consume time.
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
      else
        zip_path = download_zip(opts)
        Archive::Zip.open(zip_path) do |z|
          z.extract(destination_path, flatten: true)
        end
        @json_file = zip_path.chomp('.zip')
        # Verify hash integrity
        computed_h = Digest::SHA256.file(@json_file)
        raise "File corruption: #{@json_file}" unless meta.sha256.casecmp(computed_h.hexdigest).zero?
      end
      return @json_file
    end

    # Search for CVE in the feed.
    # @overload cve(cve)
    #   One CVE.
    #   @param cve [String] CVE ID, case insensitive.
    #   @return [Hash] a Ruby Hash corresponding to the CVE.
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
        raise TypeError "the provided argument (#{arg_cve[0]}) is not a String" unless arg_cve[0].is_a?(String)
        raise "bad CVE name (#{arg_cve[0]})" unless /^CVE-[0-9]{4}-[0-9]{4,}$/i.match?(arg_cve[0])
        doc = Oj::Doc.open(File.read(@json_file))
        # Quicker than doc.fetch('/CVE_Items').size
        doc_size = doc.fetch('/CVE_data_numberOfCVEs').to_i
        (1..doc_size).each do |i|
          if arg_cve[0].upcase == doc.fetch("/CVE_Items/#{i}/cve/CVE_data_meta/ID")
            return_value = doc.fetch("/CVE_Items/#{i}")
            break
          end
        end
        doc.close
      else
        return_value = []
        # Sorting CVE can allow us to parse the JSON only 1 time instead of severals
        # Upcase to be sure include? works
        cves_to_find = arg_cve.sort.map(&:upcase)
        raise TypeError 'one of the provided arguments is not a String' unless cves_to_find.all? { |x| x.is_a?(String) }
        raise 'bad CVE name' unless cves_to_find.all? { |x| /^CVE-[0-9]{4}-[0-9]{4,}$/i.match?(x) }
        doc = Oj::Doc.open(File.read(@json_file))
        # Quicker than doc.fetch('/CVE_Items').size
        doc_size = doc.fetch('/CVE_data_numberOfCVEs').to_i
        (1..doc_size).each do |i|
          doc.move("/CVE_Items/#{i}")
          cve_id = doc.fetch('cve/CVE_data_meta/ID')
          if cves_to_find.include?(cve_id)
            return_value.push(doc.fetch)
            cves_to_find.delete(cve_id)
          elsif cves_to_find.empty?
            break
          end
        end
        # Because JSON are sorted and that we sorted arguments, we only need
        # to parse the JSON file one time.
        raise "#{cves_to_find.join(', ')} are unexisting CVEs" unless cves_to_find.empty?
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
      doc_size = doc.fetch('/CVE_data_numberOfCVEs').to_i
      cve_names = []
      (1..doc_size).each do |i|
        doc.move("/CVE_Items/#{i}")
        cve_names.push(doc.fetch('cve/CVE_data_meta/ID'))
      end
      doc.close
      return cve_names
    end

    private

    # @param arg_name [String] the new name of the feed.
    # @return [String] the new name of the feed.
    # @example
    #   'CVE-2007'
    def name=(arg_name)
      raise TypeError "name (#{arg_name}) is not a string" unless arg_name.is_a(String)
      @name = arg_name
    end

    # @param arg_updated [String] the last update date of the feed information on the NVD website.
    # @return [String] the new date.
    # @example
    #   '10/19/2017 3:27:02 AM -04:00'
    def updated=(arg_updated)
      raise TypeError "updated date (#{arg_updated}) is not a string" unless arg_updated.is_a(String)
      @updated = arg_updated
    end

    # @param arg_meta_url [String] the new URL of the metadata file of the feed.
    # @return [String] the new URL of the metadata file of the feed.
    # @example
    #   'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2007.meta'
    def meta_url=(arg_meta_url)
      raise TypeError "meta_url (#{arg_meta_url}) is not a string" unless arg_meta_url.is_a(String)
      @meta_url = arg_meta_url
    end

    # @param arg_gz_url [String] the new URL of the gz archive of the feed.
    # @return [String] the new URL of the gz archive of the feed.
    # @example
    #   'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2007.json.gz'
    def gz_url=(arg_gz_url)
      raise TypeError "gz_url (#{arg_gz_url}) is not a string" unless arg_gz_url.is_a(String)
      @gz_url = arg_gz_url
    end

    # @param arg_zip_url [String] the new URL of the zip archive of the feed.
    # @return [String] the new URL of the zip archive of the feed.
    # @example
    #   'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2007.json.zip'
    def zip_url=(arg_zip_url)
      raise TypeError "zip_url (#{arg_zip_url}) is not a string" unless arg_zip_url.is_a(String)
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
      unless opts[:sha256].nil?
        if File.file?(destination_file)
          # Verify hash to see if it is the latest
          computed_h = Digest::SHA256.file(destination_file)
          skip_download = true if opts[:sha256].casecmp(computed_h.hexdigest).zero?
        end
      end
      unless skip_download
        res = Net::HTTP.get_response(uri)
        raise "#{file_url} ended with #{res.code} #{res.message}" unless res.is_a?(Net::HTTPSuccess)
        open(destination_file, 'wb') do |file|
          file.write(res.body)
        end
      end
      return destination_file
    end
  end

  # Initialize the scraper
  def initialize
    @url = URL
    @feeds = nil
  end

  # Scrap / parse the website to get the feeds and fill the {#feeds} attribute.
  # @note {#scrap} need to be called only once but you can be called more to update if the NVD feed page changed.
  # @return [Integer] +0+ when there is no error.
  def scrap
    uri = URI(@url)
    html = Net::HTTP.get(uri)

    doc = Nokogiri::HTML(html)
    @feeds = []
    doc.css('h3#JSON_FEED ~ div.row:first-of-type table.xml-feed-table > tbody > tr[data-testid*=desc]').each do |tr|
      name = tr.css('td')[0].text
      updated = tr.css('td')[1].text
      meta = tr.css('td')[2].css('> a').attr('href').value
      gz = tr.css('+ tr > td > a').attr('href').value
      zip = tr.css('+ tr + tr > td > a').attr('href').value
      @feeds.push(Feed.new(name, updated, meta, gz, zip))
    end
  end

  # Return feeds. Can only be called after {#scrap}.
  # @overload feeds
  #   All the feeds.
  #   @return [Array<Feed>] Attributes of all feeds. It's an array of {Feed} object.
  # @overload feeds(feed)
  #   One feed and its attributes.
  #   @param feed [String] Feed name as written on NVD website. Names can be obtains with {#available_feeds}.
  #   @return [Feed] Attributes of one feed. It's a {Feed} object.
  # @overload feeds(feed, *)
  #   List of feeds and their attributes.
  #   @param feed [String] Feed name as written on NVD website. Names can be obtains with {#available_feeds}.
  #   @param * [String] As many feeds as you want.
  #   @return [Array<Feed>] Attributes of a list of feeds. It's an array of {Feed} object.
  # @example
  #   scraper.feeds => all feeds
  #   scraper.feeds('CVE-2010') => return only CVE-2010 feed
  #   scraper.feeds("CVE-2005", "CVE-2002") => return CVE-2005 and CVE-2002 feeds
  # @see https://nvd.nist.gov/vuln/data-feeds
  def feeds(*arg_feeds)
    raise 'call scrap method before using feeds method' if @feeds.nil?
    return_value = nil
    if arg_feeds.empty?
      return_value = @feeds
    elsif arg_feeds.length == 1
      @feeds.each do |feed| # feed is an object
        return_value = feed if arg_feeds.include?(feed.name)
      end
      # if nothing found return nil
    else
      matched_feeds = []
      @feeds.each do |feed| # feed is an object
        matched_feeds.push(feed) if arg_feeds.include?(feed.name)
      end
      return_value = matched_feeds
    end
    return return_value
  end

  # Return a list with the name of all available feeds. Returned feed names can be use as argument for {#feeds} method. Can only be called after {#scrap}.
  # @return [Array<String>] List with the name of all available feeds.
  # @example
  #   scraper.available_feeds => ["CVE-Modified", "CVE-Recent", "CVE-2017", "CVE-2016", "CVE-2015", "CVE-2014", "CVE-2013", "CVE-2012", "CVE-2011", "CVE-2010", "CVE-2009", "CVE-2008", "CVE-2007", "CVE-2006", "CVE-2005", "CVE-2004", "CVE-2003", "CVE-2002"]
  def available_feeds
    raise 'call scrap method before using available_feeds method' if @feeds.nil?
    feed_names = []
    @feeds.each do |feed| # feed is an objet
      feed_names.push(feed.name)
    end
    feed_names
  end

  # Search for CVE in all year feeds.
  # @overload cve(cve)
  #   One CVE.
  #   @param cve [String] CVE ID, case insensitive.
  #   @return [Hash] a Ruby Hash corresponding to the CVE.
  # @overload cve(cve, *)
  #   Multiple CVEs.
  #   @param cve [String] CVE ID, case insensitive.
  #   @param * [String] As many CVE ID as you want.
  #   @return [Array] an Array of CVE, each CVE is a Ruby Hash.
  # @todo implement a CVE Class instead of returning a Hash.
  # @note {#scrap} is needed before using this method.
  # @see https://scap.nist.gov/schema/nvd/feed/0.1/nvd_cve_feed_json_0.1_beta.schema
  # @see https://scap.nist.gov/schema/nvd/feed/0.1/CVE_JSON_4.0_min.schema
  # @example
  #   s = NVDFeedScraper.new
  #   s.scrap
  #   s.cve("CVE-2014-0002", "cve-2014-0001")
  def cve(*arg_cve)
    return_value = nil
    raise 'no argument provided, 1 or more expected' if arg_cve.empty?
    if arg_cve.length == 1
      raise TypeError "the provided argument (#{arg_cve}) is not a String" unless arg_cve[0].is_a?(String)
      raise 'bad CVE name' unless /^CVE-[0-9]{4}-[0-9]{4,}$/i.match?(arg_cve[0])
      year = /^CVE-([0-9]{4})-[0-9]{4,}$/i.match(arg_cve[0]).captures[0]
      matched_feed = nil
      feed_names = available_feeds
      feed_names.delete('CVE-Modified')
      feed_names.delete('CVE-Recent')
      feed_names.each do |feed|
        if /#{year}/.match?(feed)
          matched_feed = feed
          break
        end
      end
      raise "bad CVE year in #{arg_cve}" if matched_feed.nil?
      f = feeds(matched_feed)
      f.json_pull
      return_value = f.cve(arg_cve[0])
    else
      return_value = []
      arg_cve.each do |cve|
        res = cve(cve)
        puts "#{cve} not found" if res.nil?
        return_value.push(res)
      end
    end
    return return_value
  end

  # Update the feeds
  # @overload update_feeds(feed)
  #   One feed
  #   @param feed [Feed] feed object to update.
  #   @return [Boolean] +true+ if the feed was updated, +false+ if it wasn't
  # @overload update_feeds(feed, *)
  #   Multiple feeds
  #   @param feed [Feed] feed object to update.
  #   @param * [Feed] As many feed objects as you want.
  #   @return [Array<Boolean>] +true+ if the feed was updated, +false+ if it wasn't
  # @example
  #   s = NVDFeedScraper.new
  #   s.scrap
  #   f2015, f2017 = s.feeds("CVE-2015", "CVE-2017")
  #   s.update_feeds(f2015, f2017) # => [false, false]
  def update_feeds(*arg_feed)
    return_value = false
    raise 'no argument provided, 1 or more expected' if arg_feed.empty?
    scrap
    if arg_feed.length == 1
      raise TypeError "the provided argument #{arg_feed[0]} is not a Feed" unless arg_feed[0].is_a?(Feed)
      raise "bad CVE name: #{arg_feed[0].name}" unless /^CVE-[0-9]{4}$/.match?(arg_feed[0].name) # case sensitive as it comes from NVD feeds
      new_feed = feeds(arg_feed[0].name)
      # update attributes
      if arg_feed[0].updated != new_feed.updated
        arg_feed[0].name = new_feed.name
        arg_feed[0].updated = new_feed.updated
        arg_feed[0].meta_url = new_feed.meta_url
        arg_feed[0].gz_url = new_feed.gz_url
        arg_feed[0].zip_url = new_feed.zip_url
        # update if @meta was set
        arg_feed[0].meta_pull unless feed.meta.nil?
        # update if @json_file was set
        arg_feed[0].json_pull unless feed.json_file.nil?
        return_value = true
      end
    else
      return_value = []
      arg_feed.each do |f|
        res = update_feeds(f)
        puts "#{f} not found" if res.nil?
        return_value.push(res)
      end
    end
    return return_value
  end

  # Return a list with the name of all available CVEs in the feed.
  # Can only be called after {#scrap}.
  # @return [Array<String>] List with the name of all available CVEs. May return tens thousands CVEs.
  def available_cves
    cve_names = []
    feed_names = available_feeds
    feed_names.delete('CVE-Modified')
    feed_names.delete('CVE-Recent')
    feed_names.each do |feed_name|
      f = feeds(feed_name)
      f.json_pull
      # merge removing duplicates
      cve_names |= f.available_cves
    end
    return cve_names
  end

  # Manage the meta file from a feed.
  #
  # == Usage
  #
  # @example
  #   s = NVDFeedScraper.new
  #   s.scrap
  #   metaUrl = s.feeds("CVE-2014").meta_url
  #   m = NVDFeedScraper::Meta.new
  #   m.url = metaUrl
  #   m.parse
  #   m.sha256
  #
  # Several ways to set the url:
  #
  #   m = NVDFeedScraper::Meta.new(metaUrl)
  #   m.parse
  #   # or
  #   m = NVDFeedScraper::Meta.new
  #   m.url = metaUrl
  #   m.parse
  #   # or
  #   m = NVDFeedScraper::Meta.new
  #   m.parse(metaUrl)
  class Meta
    # {Meta} last modified date getter
    # @return [String] the last modified date and time.
    # @example
    #   '2017-10-19T03:27:02-04:00'
    attr_reader :last_modified_date

    # {Meta} JSON size getter
    # @return [String] the size of the JSON file uncompressed.
    # @example
    #   '29443314'
    attr_reader :size

    # {Meta} zip size getter
    # @return [String] the size of the zip file.
    # @example
    #   '2008493'
    attr_reader :zip_size

    # {Meta} gz size getter
    # @return [String] the size of the gz file.
    # @example
    #   '2008357'
    attr_reader :gz_size

    # {Meta} JSON sha256 getter
    # @return [String] the SHA256 value of the uncompressed JSON file.
    # @example
    #   '33ED52D451692596D644F23742ED42B4E350258B11ACB900F969F148FCE3777B'
    attr_reader :sha256

    # @param url [String, nil] see {Feed#meta_url}.
    def initialize(url = nil)
      @url = url
    end

    # {Meta} URL getter.
    # @return [String] The URL of the meta file of the feed.
    attr_reader :url

    # {Meta} URL setter.
    # @param url [String] see {Feed#meta_url}.
    def url=(url)
      @url = url
      @last_modified_date = @size = @zip_size = @gz_size = @sha256 = nil
    end

    # Parse the meta file from the URL and set the attributes.
    # @overload parse
    #   Parse the meta file from the URL and set the attributes.
    #   @return [Integer] Returns +0+ when there is no error.
    # @overload parse(url)
    #   Set the URL of the meta file of the feed and
    #   parse the meta file from the URL and set the attributes.
    #   @param url [String] see {Feed.meta_url}
    #   @return [Integer] Returns +0+ when there is no error.
    def parse(*arg)
      if arg.empty?
      elsif arg.length == 1 # arg = url
        self.url = arg[0]
      else
        raise 'Too much arguments'
      end

      raise "Can't parse if the URL is empty" if @url.nil?
      uri = URI(@url)

      meta = Net::HTTP.get(uri)

      meta = Hash[meta.split.map { |x| x.split(':', 2) }]

      raise 'no lastModifiedDate attribute found' unless meta['lastModifiedDate']
      raise 'no valid size attribute found' unless /[0-9]+/.match?(meta['size'])
      raise 'no valid zipSize attribute found' unless /[0-9]+/.match?(meta['zipSize'])
      raise 'no valid gzSize attribute found' unless /[0-9]+/.match?(meta['gzSize'])
      raise 'no valid sha256 attribute found' unless /[0-9A-F]{64}/.match?(meta['sha256'])

      @last_modified_date = meta['lastModifiedDate']
      @size = meta['size']
      @zip_size = meta['zipSize']
      @gz_size = meta['gzSize']
      @sha256 = meta['sha256']

      0
    end
  end
end
