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
    # @param destination_path [String] the destination path (may overwrite existing file).
    #   Need the trailing slash +/+.
    #   If not provided will use +/tmp/+ (see {#download_file}).
    # @return [String] the saved gz file path.
    # @example
    #   download('~/Downloads/')
    def download_gz(destination_path = nil)
      if destination_path.nil?
        download_file(@gz_url)
      else
        download_file(@gz_url, destination_path)
      end
    end

    # Download the zip archive of the feed.
    # @param destination_path [String] the destination path (may overwrite existing file).
    #   Need the trailing slash +/+.
    #   If not provided will use +/tmp/+ (see {#download_file}).
    # @return [String] the saved zip file path.
    # @example
    #   download_zip('~/Downloads/')
    def download_zip(destination_path = nil)
      if destination_path.nil?
        download_file(@zip_url)
      else
        download_file(@zip_url, destination_path)
      end
    end

    # Download the JSON feed and fill the attribute.
    # @param destination_path [String] the destination path (may overwrite existing file).
    # @return [String] the path of teh saved JSON file.
    # @note Will downlaod and save the zip of the JSON file, unzip and save it. This massively consume time.
    # @see #json_file
    def json_pull(destination_path = '/tmp/')
      zip_path = download_zip(destination_path)
      destination_path += '/' unless destination_path[-1] == '/'
      Archive::Zip.open(zip_path) do |z|
        z.extract(destination_path, flatten: true)
      end
      @json_file = zip_path.chomp('.zip')
      # Verify hash integrity
      computed_h = Digest::SHA256.file(@json_file)
      meta_pull
      raise 'File corruption' unless meta.sha256.casecmp(computed_h.hexdigest).zero?
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
    #   @return [Array] an Array of CVE, each CVE is a Ruby Hash.
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
      raise "json_file doesn't exist" unless File.file?(@json_file)
      return_value = nil
      raise ArgumentError 'no argument provided, 1 or more expected' if arg_cve.empty?
      if arg_cve.length == 1
        raise TypeError 'the provided argument is not a String' unless arg_cve[0].is_a?(String)
        raise ArgumentError 'bad CVE name' unless /^CVE-[0-9]{4}-[0-9]{4,}$/i.match?(arg_cve[0])
        doc = Oj::Doc.open(File.read(@json_file))
        doc_size = doc.size
        (1..doc_size).each do |i|
          if arg_cve[0].upcase == doc.fetch("/CVE_Items/#{i}/cve/CVE_data_meta/ID")
            return_value = doc.fetch("/CVE_Items/#{i}")
            break
          end
        end
        doc.close
      else
        return_value = []
        arg_cve.each do |cve|
          res = cve(cve)
          puts "#{cve} not found" if res.nil?
          return_value.push(res)
        end
        return return_value
      end
      return return_value
    end

    private

    # @param arg_name [String] the new name of the feed.
    # @return [String] the new name of the feed.
    # @example
    #   'CVE-2007'
    def name=(arg_name)
      raise ArgumentError 'name is not a string' unless arg_name.is_a(String)
      @name = arg_name
    end

    # @param arg_updated [String] the last update date of the feed information on the NVD website.
    # @return [String] the new date.
    # @example
    #   '10/19/2017 3:27:02 AM -04:00'
    def updated=(arg_updated)
      raise ArgumentError 'updated date is not a string' unless arg_updated.is_a(String)
      @updated = arg_updated
    end

    # @param arg_meta_url [String] the new URL of the metadata file of the feed.
    # @return [String] the new URL of the metadata file of the feed.
    # @example
    #   'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2007.meta'
    def meta_url=(arg_meta_url)
      raise ArgumentError 'meta_url is not a string' unless arg_meta_url.is_a(String)
      @meta_url = arg_meta_url
    end

    # @param arg_gz_url [String] the new URL of the gz archive of the feed.
    # @return [String] the new URL of the gz archive of the feed.
    # @example
    #   'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2007.json.gz'
    def gz_url=(arg_gz_url)
      raise ArgumentError 'gz_url is not a string' unless arg_gz_url.is_a(String)
      @gz_url = arg_gz_url
    end

    # @param arg_zip_url [String] the new URL of the zip archive of the feed.
    # @return [String] the new URL of the zip archive of the feed.
    # @example
    #   'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2007.json.zip'
    def zip_url=(arg_zip_url)
      raise ArgumentError 'zip_url is not a string' unless arg_zip_url.is_a(String)
      @zip_url = arg_zip_url
    end

    # Download a file.
    # @param file_url [String] the URL of the file.
    # @param destination_path [String] the destination path (may overwrite existing file).
    # @return [String] the saved file path.
    # @example
    #   download_file('https://example.org/example.zip') # => '/tmp/example.zip'
    def download_file(file_url, destination_path = '/tmp/')
      uri = URI(file_url)
      filename = uri.path.split('/').last
      destination_file = if destination_path[-1] == '/'
                           destination_path + filename
                         else
                           destination_path + '/' + filename
                         end
      res = Net::HTTP.get_response(uri)
      raise "#{file_url} ended with #{res.code} #{res.message}" unless res.is_a?(Net::HTTPSuccess)
      open(destination_file, 'wb') do |file|
        file.write(res.body)
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
  # @return [Integer] Returns +0+ when there is no error.
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
    raise ArgumentError 'no argument provided, 1 or more expected' if arg_cve.empty?
    if arg_cve.length == 1
      raise TypeError 'the provided argument is not a String' unless arg_cve[0].is_a?(String)
      raise ArgumentError 'bad CVE name' unless /^CVE-[0-9]{4}-[0-9]{4,}$/i.match?(arg_cve[0])
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
      raise 'bad CVE year' if matched_feed.nil?
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
    raise ArgumentError 'no argument provided, 1 or more expected' if arg_feed.empty?
    scrap
    if arg_feed.length == 1
      raise TypeError 'the provided argument is not a Feed' unless arg_feed[0].is_a?(Feed)
      raise ArgumentError 'bad CVE name' unless /^CVE-[0-9]{4}$/.match?(arg_feed[0].name) # case sensitive as it comes from NVD feeds
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
        # update @json_file was set
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
