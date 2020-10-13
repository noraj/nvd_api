# @author Alexandre ZANNI <alexandre.zanni@engineer.com>

# Ruby internal
require 'net/https'
require 'set'
# External
require 'nokogiri'
# Project internal
require 'nvd_feed_api/version'
require 'nvd_feed_api/feed'

# The class that parse NVD website to get information.
# @example Initialize a NVDFeedScraper object, get the feeds and see them:
#   scraper = NVDFeedScraper.new
#   scraper.scrap
#   scraper.available_feeds
#   scraper.feeds
#   scraper.feeds("CVE-2007")
#   cve2007, cve2015 = scraper.feeds("CVE-2007", "CVE-2015")
class NVDFeedScraper
  BASE = 'https://nvd.nist.gov'.freeze
  # The NVD url where is located the data feeds.
  URL = "#{BASE}/vuln/data-feeds".freeze
  # Load constants
  include NvdFeedApi

  # Initialize the scraper
  def initialize
    @url = URL
    @feeds = nil
  end

  # Scrap / parse the website to get the feeds and fill the {#feeds} attribute.
  # @note {#scrap} need to be called only once but can be called again to update if the NVD feed page changed.
  # @return [Integer] Number of scrapped feeds.
  def scrap
    uri = URI(@url)
    html = Net::HTTP.get(uri)

    doc = Nokogiri::HTML(html)
    @feeds = []
    tmp_feeds = {}
    doc.css('#vuln-feed-table table.xml-feed-table tr[data-testid]').each do |tr|
      num, type = tr.attr('data-testid')[13..].split('-')
      if type == 'meta'
        tmp_feeds[num] = {}
        tmp_feeds[num][:name] = tr.css('td')[0].text
        tmp_feeds[num][:updated] = tr.css('td')[1].text
        tmp_feeds[num][:meta] = BASE + tr.css('td')[2].css('> a').attr('href').value
      elsif type == 'gz'
        tmp_feeds[num][:gz] = BASE + tr.css('td > a').attr('href').value
      elsif type == 'zip'
        tmp_feeds[num][:zip] = BASE + tr.css('td > a').attr('href').value
        @feeds.push(Feed.new(tmp_feeds[num][:name],
                             tmp_feeds[num][:updated],
                             tmp_feeds[num][:meta],
                             tmp_feeds[num][:gz],
                             tmp_feeds[num][:zip]))
      end
    end
    return @feeds.size
  end

  # Return feeds. Can only be called after {#scrap}.
  # @overload feeds
  #   All the feeds.
  #   @return [Array<Feed>] Attributes of all feeds. It's an array of {Feed} object.
  # @overload feeds(feed)
  #   One feed.
  #   @param feed [String] Feed name as written on NVD website. Names can be obtains with {#available_feeds}.
  #   @return [Feed] Attributes of one feed. It's a {Feed} object.
  # @overload feeds(feed_arr)
  #   An array of feeds.
  #   @param feed_arr [Array<String>] An array of feed names as written on NVD website. Names can be obtains with {#available_feeds}.
  #   @return [Array<Feed>] Attributes of the feeds. It's an array of {Feed} object.
  # @overload feeds(feed, *)
  #   Multiple feeds.
  #   @param feed [String] Feed name as written on NVD website. Names can be obtains with {#available_feeds}.
  #   @param * [String] As many feeds as you want.
  #   @return [Array<Feed>] Attributes of the feeds. It's an array of {Feed} object.
  # @example
  #   scraper.feeds # => all feeds
  #   scraper.feeds('CVE-2010') # => return only CVE-2010 feed
  #   scraper.feeds("CVE-2005", "CVE-2002") # => return CVE-2005 and CVE-2002 feeds
  # @see https://nvd.nist.gov/vuln/data-feeds
  def feeds(*arg_feeds)
    raise 'call scrap method before using feeds method' if @feeds.nil?

    return_value = nil
    if arg_feeds.empty?
      return_value = @feeds
    elsif arg_feeds.length == 1
      if arg_feeds[0].is_a?(String)
        @feeds.each do |feed| # feed is an object
          return_value = feed if arg_feeds.include?(feed.name)
        end
        # if nothing found return nil
      elsif arg_feeds[0].is_a?(Array)
        raise 'one of the provided arguments is not a String' unless arg_feeds[0].all? { |x| x.is_a?(String) }

        # Sorting CVE can allow us to parse quicker
        # Upcase to be sure include? works
        # Does not use map(&:upcase) to preserve CVE-Recent and CVE-Modified
        feeds_to_find = arg_feeds[0].map { |x| x[0..2].upcase.concat(x[3..x.size]) }.sort
        matched_feeds = []
        @feeds.each do |feed| # feed is an object
          if feeds_to_find.include?(feed.name)
            matched_feeds.push(feed)
            feeds_to_find.delete(feed.name)
          elsif feeds_to_find.empty?
            break
          end
        end
        return_value = matched_feeds
        raise "#{feeds_to_find.join(', ')} are unexisting feeds" unless feeds_to_find.empty?
      else
        raise "the provided argument (#{arg_feeds[0]}) is nor a String or an Array"
      end
    else
      # Overloading a list of arguments as one array argument
      return_value = feeds(arg_feeds)
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
  # @overload cve(cve_arr)
  #   An array of CVEs.
  #   @param cve_arr [Array<String>] Array of CVE ID, case insensitive.
  #   @return [Array] an Array of CVE, each CVE is a Ruby Hash. May not be in the same order as provided.
  # @overload cve(cve, *)
  #   Multiple CVEs.
  #   @param cve [String] CVE ID, case insensitive.
  #   @param * [String] As many CVE ID as you want.
  #   @return [Array] an Array of CVE, each CVE is a Ruby Hash.
  # @todo implement a CVE Class instead of returning a Hash. May not be in the same order as provided.
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
      if arg_cve[0].is_a?(String)
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
        # CVE-2002 feed (the 1st one) contains CVE from 1999 to 2002
        matched_feed = 'CVE-2002' if matched_feed.nil? && ('1999'..'2001').to_a.include?(year)
        raise "bad CVE year in #{arg_cve}" if matched_feed.nil?

        f = feeds(matched_feed)
        f.json_pull
        return_value = f.cve(arg_cve[0])
      elsif arg_cve[0].is_a?(Array)
        raise 'one of the provided arguments is not a String' unless arg_cve[0].all? { |x| x.is_a?(String) }
        raise 'bad CVE name' unless arg_cve[0].all? { |x| /^CVE-[0-9]{4}-[0-9]{4,}$/i.match?(x) }

        return_value = []
        # Sorting CVE can allow us to parse quicker
        # Upcase to be sure include? works
        cves_to_find = arg_cve[0].map(&:upcase).sort
        feeds_to_match = Set[]
        cves_to_find.each do |cve|
          feeds_to_match.add?(/^(CVE-[0-9]{4})-[0-9]{4,}$/i.match(cve).captures[0])
        end
        feed_names = available_feeds.to_set
        feed_names.delete('CVE-Modified')
        feed_names.delete('CVE-Recent')
        # CVE-2002 feed (the 1st one) contains CVE from 1999 to 2002
        virtual_feeds = ['CVE-1999', 'CVE-2000', 'CVE-2001']
        # So virtually add those feed...
        feed_names.merge(virtual_feeds)
        raise 'unexisting CVE year was provided in some CVE' unless feeds_to_match.subset?(feed_names)

        matched_feeds = feeds_to_match.intersection(feed_names)
        # and now that the intersection is done remove those virtual feeds and add CVE-2002 instead if needed
        unless matched_feeds.intersection(virtual_feeds.to_set).empty?
          matched_feeds.subtract(virtual_feeds)
          matched_feeds.add('CVE-2002')
        end
        feeds_arr = feeds(matched_feeds.to_a)
        feeds_arr.each do |feed|
          feed.json_pull
          cves_obj = feed.cve(cves_to_find.select { |cve| cve.include?(feed.name) })
          if cves_obj.is_a?(Hash)
            return_value.push(cves_obj)
          elsif cves_obj.is_a?(Array)
            return_value.push(*cves_obj)
          else
            raise 'cve() method of the feed instance returns wrong value'
          end
        end
      else
        raise "the provided argument (#{arg_cve[0]}) is nor a String or an Array"
      end
    else
      # Overloading a list of arguments as one array argument
      return_value = cve(arg_cve)
    end
    return return_value
  end

  # Update the feeds
  # @overload update_feeds(feed)
  #   One feed.
  #   @param feed [Feed] feed object to update.
  #   @return [Boolean] +true+ if the feed was updated, +false+ if it wasn't.
  # @overload update_feeds(feed_arr)
  #   An array of feed.
  #   @param feed_arr [Array<Feed>] array of feed objects to update.
  #   @return [Array<Boolean>] +true+ if the feed was updated, +false+ if it wasn't.
  # @overload update_feeds(feed, *)
  #   Multiple feeds.
  #   @param feed [Feed] feed object to update.
  #   @param * [Feed] As many feed objects as you want.
  #   @return [Array<Boolean>] +true+ if the feed was updated, +false+ if it wasn't.
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
      if arg_feed[0].is_a?(Feed)
        new_feed = feeds(arg_feed[0].name)
        # update attributes
        return_value = arg_feed[0].update!(new_feed)
      elsif arg_feed[0].is_a?(Array)
        return_value = []
        arg_feed[0].each do |f|
          res = update_feeds(f)
          puts "#{f} not found" if res.nil?
          return_value.push(res)
        end
      else
        raise "the provided argument #{arg_feed[0]} is not a Feed or an Array"
      end
    else
      # Overloading a list of arguments as one array argument
      return_value = update_feeds(arg_feed)
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
end
