require 'minitest/autorun'
require 'nvd_api'

# @todo WRITE NEW TESTS
class NVDAPITest < Minitest::Test
    def setup
        @s = Scraper.new
        @s.scrap # needed for feeds method
    end

    def test_Scraper_scrap
        assert_equal(@s.scrap, 0, "scrap method return nothing")
    end

    def test_Scraper_feeds_noarg
        assert_instance_of(Array, @s.feeds, "feeds doesn't return an array") # same as #assert(@s.feeds.instance_of?(Array), "error")
        refute_empty(@s.feeds, "feeds returns an empty array")
    end

    def test_Scraper_feeds_witharg
        # one arg
        assert_instance_of(Array, @s.feeds("CVE-2017"), "feeds doesn't return an array")
        refute_empty(@s.feeds("CVE-2017"), "feeds returns an empty array")
        # two args
        assert_instance_of(Array, @s.feeds("CVE-2017", "CVE-Modified"), "feeds doesn't return an array")
        refute_empty(@s.feeds("CVE-2017", "CVE-Modified"), "feeds returns an empty array")
        # bad arg
        assert_instance_of(Array, @s.feeds("wrong"), "feeds doesn't return an array")
        assert_empty(@s.feeds("wrong"), "feeds doesn't return an empty array")
    end
end
