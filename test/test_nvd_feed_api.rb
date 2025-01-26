require 'minitest/autorun'
require 'nvd_feed_api'
require 'date'

class NVDAPITest < Minitest::Test
  def setup
    @s = NVDFeedScraper.new
    @s.scrap # needed for feeds method
  end

  def test_scraper_scrap
    assert_operator(0, :<, @s.scrap, 'scrap method returns nothing')
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
    # array arg
    assert_instance_of(Array, @s.feeds(['CVE-2016', 'CVE-Recent']), "feeds doesn't return an array")
    refute_empty(@s.feeds(['CVE-2016', 'CVE-Recent']), 'feeds returns an empty array')
    # bad arg
    assert_nil(@s.feeds('wrong'), 'feeds')
  end

  def test_scraper_available_feeds
    assert_instance_of(Array, @s.available_feeds, "available_feeds doesn't return an array")
    refute_empty(@s.available_feeds, 'available_feeds returns an empty array')
  end

  def test_scraper_available_cves
    assert_instance_of(Array, @s.available_cves, "available_cves doesn't return an array")
    refute_empty(@s.available_cves, 'available_cves returns an empty array')
  end

  def test_scraper_cve
    # one arg
    assert_instance_of(Hash, @s.cve('CVE-2015-0235'), "cve doesn't return a hash")
    # two args
    assert_instance_of(Array, @s.cve('CVE-2015-0235', 'CVE-2013-3893'), "cve doesn't return an array")
    refute_empty(@s.cve('CVE-2015-0235', 'CVE-2013-3893'), 'cve returns an empty array')
    # array arg
    assert_instance_of(Array, @s.cve(['CVE-2014-0160', 'cve-2009-3555']), "cve doesn't return an array")
    refute_empty(@s.cve(['CVE-2014-0160', 'cve-2009-3555']), 'cve returns an empty array')
    # bad arg
    ## string but not a CVE ID
    err = assert_raises(RuntimeError) do
      @s.cve('e')
    end
    assert_equal('bad CVE name', err.message)
    ## correct CVE ID but bad year
    err = assert_raises(RuntimeError) do
      @s.cve('CVE-1800-31337')
    end
    assert_equal('bad CVE year in ["CVE-1800-31337"]', err.message)
    ## correct CVE ID and year but unexisting CVE
    assert_nil(@s.cve('CVE-2004-31337'))
    ## correct CVE ID and year but unexisting CVE with array arg
    err = assert_raises(RuntimeError) do
      @s.cve(['CVE-2004-31337', 'CVE-2005-31337'])
    end
    assert_equal('CVE-2005-31337 are unexisting CVEs in this feed', err.message)
    ## wrong arg type
    err = assert_raises(RuntimeError) do
      @s.cve(1)
    end
    assert_equal('the provided argument (1) is nor a String or an Array', err.message)
  end

  def test_scraper_update_feeds
    f2017, f2016, f_modified = @s.feeds('CVE-2017', 'CVE-2016', 'CVE-Modified')
    # one arg
    # can't use assert_instance_of because there is no boolean class
    assert_includes(['TrueClass', 'FalseClass'], @s.update_feeds(f2017).class.to_s, "update_feeds doesn't return a boolean")
    # two args
    assert_instance_of(Array, @s.update_feeds(f2017, f2016), "update_feeds doesn't return an array")
    refute_empty(@s.update_feeds(f2017, f2016), 'update_feeds returns an empty array')
    # array arg
    assert_instance_of(Array, @s.update_feeds([f2017, f_modified]), "update_feeds doesn't return an array")
    refute_empty(@s.update_feeds([f2017, f_modified]), 'update_feeds returns an empty array')
    # bad arg
    ## wrong arg type
    err = assert_raises(RuntimeError) do
      @s.update_feeds(1)
    end
    assert_equal('the provided argument 1 is not a Feed or an Array', err.message)
    ## empty array
    assert_empty(@s.update_feeds([]))
  end

  def test_feed_default_storage_location
    # save default value / save context
    default_val = NVDFeedScraper::Feed.default_storage_location
    # check type
    assert_instance_of(String, default_val, "default_storage_location doesn't return a string")
    # check new value
    new_val = '/srv/downloads/'

    assert_equal(new_val, NVDFeedScraper::Feed.default_storage_location = new_val, 'the new value was not set properly')
    # put the default value back / restore context
    NVDFeedScraper::Feed.default_storage_location = default_val
  end

  def test_feed_attributes
    name = 'CVE-2010'
    meta_url = 'https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-2010.meta'
    gz_url = 'https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-2010.json.gz'
    zip_url = 'https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-2010.json.zip'
    f = @s.feeds('CVE-2010')
    # Test name
    assert_instance_of(String, f.name, "name doesn't return a string")
    refute_empty(f.name, 'name is empty')
    assert_equal(name, f.name, 'The name of the feed was modified')
    # Test updated
    assert_instance_of(String, f.updated, "updated doesn't return a string")
    refute_empty(f.updated, 'updated is empty')
    # Test gz_url
    assert_instance_of(String, f.gz_url, "gz_url doesn't return a string")
    refute_empty(f.gz_url, 'gz_url is empty')
    assert_equal(gz_url, f.gz_url, 'The gz_url of the feed was modified')
    # Test zip_url
    assert_instance_of(String, f.zip_url, "zip_url doesn't return a string")
    refute_empty(f.zip_url, 'zip_url is empty')
    assert_equal(zip_url, f.zip_url, 'The zip_url url of the feed was modified')
    # Test meta_url
    assert_instance_of(String, f.meta_url, "meta_url doesn't return a string")
    refute_empty(f.meta_url, 'meta_url is empty')
    assert_equal(meta_url, f.meta_url, 'The meta_url url of the feed was modified')
    # Test meta (before json_pull)
    assert_nil(f.meta)
    # Test json_file
    assert_nil(f.json_file)
    f.json_pull

    assert_instance_of(String, f.json_file, "json_file doesn't return a string")
    refute_empty(f.json_file, 'json_file is empty')
    # Test meta (after json_pull)
    f.meta_pull

    assert_instance_of(NVDFeedScraper::Meta, f.meta, "meta doesn't return a Meta object")

    # Test data (require json_pull)
    # Test data_type
    assert_instance_of(String, f.data_type, "data_type doesn't return a String")
    refute_empty(f.data_type, 'data_type is empty')
    # Test data_format
    assert_instance_of(String, f.data_format, "data_format doesn't return a String")
    refute_empty(f.data_format, 'data_format is empty')
    # Test data_version
    assert_instance_of(Float, f.data_version, "data_version doesn't return a Float")
    # Test data_number_of_cves
    assert_instance_of(Integer, f.data_number_of_cves, "data_number_of_cves doesn't return an Integer")
    # Test data_timestamp
    assert_instance_of(Date, f.data_timestamp, "data_timestamp doesn't return a Date")
  end

  def test_feed_available_cves
    f = @s.feeds('CVE-2011')
    f.json_pull

    assert_instance_of(Array, f.available_cves, "available_cves doesn't return an array")
    refute_empty(f.available_cves, 'available_cves returns an empty array')
  end

  def test_feed_cve
    f = @s.feeds('CVE-2012')
    f.json_pull
    # one arg
    assert_instance_of(Hash, f.cve('CVE-2012-4969'), "cve doesn't return a hash")
    # two args
    assert_instance_of(Array, f.cve('CVE-2012-4969', 'cve-2012-1889'), "cve doesn't return an array")
    refute_empty(f.cve('CVE-2012-4969', 'cve-2012-1889'), 'cve returns an empty array')
    # array arg
    assert_instance_of(Array, f.cve(['CVE-2012-4969', 'cve-2012-1889']), "cve doesn't return an array")
    refute_empty(f.cve(['CVE-2012-4969', 'cve-2012-1889']), 'cve returns an empty array')
    # bad arg
    ## string but not a CVE ID
    err = assert_raises(RuntimeError) do
      f.cve('e')
    end
    assert_equal('bad CVE name (e)', err.message)
    ## bad year
    assert_nil(f.cve('CVE-2004-31337'))
    ## bad year not in the feed with array arg
    err = assert_raises(RuntimeError) do
      f.cve(['CVE-2004-31337', 'CVE-2005-31337'])
    end
    assert_equal('CVE-2004-31337, CVE-2005-31337 are unexisting CVEs in this feed', err.message)
    ## wrong arg type
    err = assert_raises(RuntimeError) do
      f.cve(1)
    end
    assert_equal('the provided argument (1) is nor a String or an Array', err.message)
  end

  def test_feed_download_gz
    f = @s.feeds('CVE-2013')
    return_value = f.download_gz

    assert_instance_of(String, return_value, "download_gz doesn't return a string")
    refute_empty(return_value, 'download_gz returns an empty string')
    assert(File.file?(return_value), 'download_gz returns an unexisting file')
  end

  def test_feed_download_zip
    f = @s.feeds('CVE-2003')
    return_value = f.download_zip

    assert_instance_of(String, return_value, "download_zip doesn't return a string")
    refute_empty(return_value, 'download_zip returns an empty string')
    assert(File.file?(return_value), 'download_zip returns an unexisting file')
  end

  def test_feed_json_pull
    f = @s.feeds('CVE-2004')
    return_value = f.json_pull

    assert_instance_of(String, return_value, "json_pull doesn't return a string")
    refute_empty(return_value, 'json_pull returns an empty string')
    assert(File.file?(return_value), 'json_pull returns an unexisting file')
  end

  def test_feed_meta_pull
    f = @s.feeds('CVE-2005')

    assert_instance_of(NVDFeedScraper::Meta, f.meta_pull, "meta_pull doesn't return a Meta object")
  end

  def test_feed_update!
    f = @s.feeds('CVE-2006')
    @s.scrap
    f_new = @s.feeds('CVE-2006')
    # Right arg
    # can't use assert_instance_of because there is no boolean class
    assert_includes(['TrueClass', 'FalseClass'], f.update!(f_new).class.to_s, "update! doesn't return a boolean")
    # Bad arg
    err = assert_raises(RuntimeError) do
      f.update!('bad_arg')
    end
    assert_equal('bad_arg is not a Feed', err.message)
  end

  def test_meta_parse_noarg
    m = NVDFeedScraper::Meta.new('https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-2015.meta')

    assert_equal(0, m.parse, 'parse method return nothing')
  end

  def test_meta_parse_witharg
    m = NVDFeedScraper::Meta.new
    meta_url = 'https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-2015.meta'

    assert_equal(0, m.parse(meta_url), 'parse method return nothing')
  end

  def test_meta_url_setter
    m = NVDFeedScraper::Meta.new
    meta_url = 'https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-2015.meta'

    assert_equal(meta_url, m.url = meta_url, 'the meta URL is not set correctly')
  end

  def test_meta_attributes
    m = NVDFeedScraper::Meta.new
    meta_url = 'https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-2015.meta'
    m.url = meta_url
    m.parse
    # Test gz_size
    assert_instance_of(String, m.gz_size, "Meta gz_size method doesn't return a string")
    assert_match(/[0-9]+/, m.gz_size, 'Meta gz_size is not an integer')
    # Test last_modified_date
    assert_instance_of(String, m.last_modified_date, "Meta last_modified_date method doesn't return a string")
    ## Date and time of day for calendar date (extended) '%FT%T%:z'
    assert(Date.rfc3339(m.last_modified_date), 'Meta last_modified_date is not a rfc3339 date')
    # Test sha256
    assert_instance_of(String, m.sha256, "Meta sha256 method doesn't return a string")
    assert_match(/[0-9A-F]{64}/, m.sha256, 'Meta sha256 is not a sha256 string matching /[0-9A-F]{64}/')
    # Test size
    assert_instance_of(String, m.size, "Meta size method doesn't return a string")
    assert_match(/[0-9]+/, m.size, 'Meta size is not an integer')
    # Test url
    assert_instance_of(String, m.url, "Meta url method doesn't return a string")
    assert_equal(meta_url, m.url, 'The Meta url was modified')
    # Test zip_size
    assert_instance_of(String, m.zip_size, "Meta zip_size method doesn't return a string")
    assert_match(/[0-9]+/, m.zip_size, 'Meta zip_size is not an integer')
  end
end
