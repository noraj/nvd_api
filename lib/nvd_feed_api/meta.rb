# Ruby internal
require 'net/https'

class NVDFeedScraper
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
    #   @return [Integer] Returns `0` when there is no error.
    # @overload parse(url)
    #   Set the URL of the meta file of the feed and
    #   parse the meta file from the URL and set the attributes.
    #   @param url [String] see {Feed.meta_url}
    #   @return [Integer] Returns `0` when there is no error.
    def parse(*arg)
      if arg.length == 1 # arg = url
        self.url = arg[0]
      elsif arg.length > 1
        raise 'Too much arguments'
      end

      raise "Can't parse if the URL is empty" if @url.nil?

      uri = URI(@url)

      meta = Net::HTTP.get(uri)

      meta = meta.split.map { |x| x.split(':', 2) }.to_h

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
