# Examples

For all examples don't forget to add `require 'nvd_feed_api'`.

## Download all feeds on disk

```ruby
# Initialize the scraper.
s = NVDFeedScraper.new
# Scrap the NVD website to get the feeds attributes.
s.scrap
# Change the default feed storage location beacause default value is '/tmp/'.
# '/tmp/' is mounted as tmpFS and is cleaned at every start.
# This will considerably speed up your performance is you have to reboot.
NVDFeedScraper::Feed.default_storage_location = "/home/user/Dev/cve_feeds"
# Create a {Feed} object for all available feeds
# and for each one download the JSON file and fill the attributes.
s.feeds(s.available_feeds).each(&:json_pull)
```
