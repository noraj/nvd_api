require 'minitest/autorun'
require 'nvd_feed_api'

# @todo WRITE NEW TESTS
class NVDAPITest < Minitest::Test
  def setup
    @s = Scraper.new
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
    assert_instance_of(Scraper::Feed, @s.feeds('CVE-2017'), "feeds doesn't return a Feed object")
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
    f = Scraper::Feed.new(name, updated, meta, gz, zip)
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
end
