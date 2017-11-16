require 'minitest/autorun'
require 'nvd_feed_api'
require 'date'

# @todo WRITE NEW TESTS
class NVDAPITest < Minitest::Test
  def setup
    @s = NVDFeedScraper.new
    @s.scrap # needed for feeds method
  end

  def test_scraper_scrap
    assert_equal(@s.scrap, 0, 'scrap method return nothing')
  end

  def test_scraper_feeds_noarg
    assert_instance_of(Array, @s.feeds, "feeds doesn't return an array") # same as #assert(@s.feeds.instance_of?(Array), 'error')
    refute_empty(@s.feeds, 'feeds returns an empty array')
  end

  def test_scraper_feeds_witharg
    # one arg
    assert_instance_of(NVDFeedScraper::Feed, @s.feeds('CVE-2017'), "feeds doesn't return a Feed object")
    # two args
    assert_instance_of(Array, @s.feeds('CVE-2017', 'CVE-Modified'), "feeds doesn't return an array")
    refute_empty(@s.feeds('CVE-2017', 'CVE-Modified'), 'feeds returns an empty array')
    # bad arg
    assert_nil(@s.feeds('wrong'), 'feeds')
  end

  def test_scraper_available_feeds
    assert_instance_of(Array, @s.available_feeds, "available_feeds doesn't return an array")
    refute_empty(@s.available_feeds, 'available_feeds returns an empty array')
  end

  def test_feed_attributes
    name = 'CVE-2010'
    updated = '10/27/2017 3:17:23 AM -04:00'
    meta = 'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2010.meta'
    gz = 'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2010.json.gz'
    zip = 'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2010.json.zip'
    f = NVDFeedScraper::Feed.new(name, updated, meta, gz, zip)
    # Test name
    assert_instance_of(String, f.name, "Feed.name doesn't return a string")
    refute_empty(f.name, 'Feed.name is empty')
    assert_equal(f.name, name, 'The name of the feed was modified')
    # Test updated
    assert_instance_of(String, f.updated, "Feed.updated doesn't return a string")
    refute_empty(f.updated, 'Feed.updated is empty')
    assert_equal(f.updated, updated, 'The updated date of the feed was modified')
    # Test meta
    assert_instance_of(String, f.meta, "Feed.meta doesn't return a string")
    refute_empty(f.meta, 'Feed.meta is empty')
    assert_equal(f.meta, meta, 'The meta url of the feed was modified')
    # Test gz
    assert_instance_of(String, f.gz, "Feed.gz doesn't return a string")
    refute_empty(f.gz, 'Feed.gz is empty')
    assert_equal(f.gz, gz, 'The gz url of the feed was modified')
    # Test zip
    assert_instance_of(String, f.zip, "Feed.zip doesn't return a string")
    refute_empty(f.zip, 'Feed.zip is empty')
    assert_equal(f.zip, zip, 'The zip url of the feed was modified')
  end

  def test_meta_parse_noarg
    m = NVDFeedScraper::Meta.new('https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2015.meta')
    assert_equal(m.parse, 0, 'parse method return nothing')
  end

  def test_meta_parse_witharg
    m = NVDFeedScraper::Meta.new
    meta_url = 'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2015.meta'
    assert_equal(m.parse(meta_url), 0, 'parse method return nothing')
  end

  def test_meta_url_setter
    m = NVDFeedScraper::Meta.new
    meta_url = 'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2015.meta'
    assert_equal(m.url = meta_url, meta_url, 'the meta URL is not set correctly')
  end

  def test_meta_attributes
    m = NVDFeedScraper::Meta.new
    meta_url = 'https://static.nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-2015.meta'
    m.url = meta_url
    m.parse
    # Test gz_size
    assert_instance_of(String, m.gz_size, "Meta gz_size method doesn't return a string")
    assert(m.gz_size.match?(/[0-9]+/), 'Meta gz_size is not an integer')
    # Test last_modified_date
    assert_instance_of(String, m.last_modified_date, "Meta last_modified_date method doesn't return a string")
    ## Date and time of day for calendar date (extended) '%FT%T%:z'
    assert(Date.rfc3339(m.last_modified_date), 'Meta last_modified_date is not a rfc3339 date')
    # Test sha256
    assert_instance_of(String, m.sha256, "Meta sha256 method doesn't return a string")
    assert(m.sha256.match?(/[0-9A-F]{64}/), 'Meta sha256 is not a sha256 string matching /[0-9A-F]{64}/')
    # Test size
    assert_instance_of(String, m.size, "Meta size method doesn't return a string")
    assert(m.size.match?(/[0-9]+/), 'Meta size is not an integer')
    # Test url
    assert_instance_of(String, m.url, "Meta url method doesn't return a string")
    assert_equal(m.url, meta_url, 'The Meta url was modified')
    # Test zip_size
    assert_instance_of(String, m.zip_size, "Meta zip_size method doesn't return a string")
    assert(m.zip_size.match?(/[0-9]+/), 'Meta zip_size is not an integer')
  end
end
