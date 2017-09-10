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

class Scraper
    attr_reader :url, :feed
    def initialize
        @url = "https://nvd.nist.gov/vuln/data-feeds"
        @feed = Array.new
    end

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
            @feed.push({"name" => name, "updated" => updated, "meta" => meta, "gz" => gz, "zip" => zip})
        end
    end
end
