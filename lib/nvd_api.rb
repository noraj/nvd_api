# @author Alexandre ZANNI <alexandre.zanni@engineer.com>

require 'net/https'
require 'nokogiri'

class Download
    attr_accessor :url
    attr_reader :meta
    def initialize(url)
        @url = url
        @meta = Meta.new
    end

    def download_meta
        uri = URI(@url)
        meta = Net::HTTP.get(uri)

        meta = Hash[meta.split.map{|x| x.split(':',2)}]

        raise "no lastModifiedDate attribute found" unless meta["lastModifiedDate"]
        raise "no valid size attribute found" unless /[0-9]+/.match?(meta["size"])
        raise "no valid zipSize attribute found" unless /[0-9]+/.match?(meta["zipSize"])
        raise "no valid gzSize attribute found" unless /[0-9]+/.match?(meta["gzSize"])
        raise "no valid sha256 attribute found" unless /[0-9A-F]{64}/.match?(meta["sha256"])

        @meta.lastModifiedDate = meta["lastModifiedDate"]
        @meta.size = meta["size"]
        @meta.zipSize = meta["zipSize"]
        @meta.gzSize = meta["gzSize"]
        @meta.sha256 = meta["sha256"]

        return meta
    end
end

class Meta
    attr_accessor :lastModifiedDate, :size, :zipSize, :gzSize, :sha256
    def initialize
        @lastModifiedDate = @size = @zipSize = @gzSize = @sha256 = ""
    end
end

# The class that parse NVD website to get information.
# @attr_reader [String] url The NVD url where is located the data feeds.
# @example Initialize a Scraper object, get the feeds and see them:
#   scraper = Scraper.new
#   scraper.scrap
#   scraper.feeds
#   scraper.feeds("CVE-2007")
class Scraper
    attr_reader :url

    def initialize
        @url = "https://nvd.nist.gov/vuln/data-feeds"
        @feeds = Array.new
    end

    # Scrap / parse the website to get the feeds and fill the {#feeds} attribute
    # @return [Integer] Returns +0+ when there is no error.
    def scrap
        uri = URI(@url)
        html = Net::HTTP.get(uri)

        doc = Nokogiri::HTML(html)
        doc.css('h3#JSON_FEED ~ div:first-of-type table.xml-feed-table > tbody > tr[data-testid$=desc]').each do |tr|
            name = tr.css('td')[0].text
            updated = tr.css('td')[1].text
            meta = tr.css('td')[2].css('> a').attr('href').value
            gz = tr.css('+ tr > td > a').attr('href').value
            zip = tr.css('+ tr + tr > td > a').attr('href').value
            @feeds.push({:name => name, :updated => updated, :meta => meta, :gz => gz, :zip => zip})
        end
    end

    # Return feeds.
    # @overload feeds
    #   All the feeds.
    #   @return [Array<Hash{}>] Attributes of all feeds. It's an array of hashes.
    #       Hash structure:
    #       * :name [String] Name of the feed.
    #       * :updated [String] Last update date of the feed.
    #       * :meta [String] URL of the metadata file of the feed.
    #       * :gz [String] URL of the gz archive of the feed.
    #       * :zip [String] RL of the zip archive of the feed.
    # @overload feeds(feed)
    #   One feed and its attributes.
    #   @param feed [String] Feed name as written on NVD website.
    #   @return [Array<Hash{}>] Attributes of one feed.
    #   @see #feeds for Hash structure.
    # @overload feeds(feed, feed)
    #   List of feeds and their attributes.
    #   @param feed [String] Feed name as written on NVD website.
    #   @return [Array<Hash{}>] Attributes of a list of feeds.
    #   @see #feeds for Hash structure.
    # @example
    #   scraper.feeds => all feeds
    #   scraper.feeds("CVE-2005") => return only CVE-2005
    #   scraper.feeds("CVE-2005", "CVE-2002") => return CVE-2005 and CVE-2002
    #   scraper.feeds("wrong") => empty array
    # @todo +list_feeds+ feeds name list
    def feeds(*arg_feeds)
        if arg_feeds.length == 0
            return @feeds
        else
            matched_feeds = []
            @feeds.each do |feed| # feed is a hash
                if arg_feeds.include?(feed["name"])
                    matched_feeds.push(feed)
                end
            end
            return matched_feeds
        end
    end
end
