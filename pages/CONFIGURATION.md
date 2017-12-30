# Configuration

For configuration `nvd_feed_api` use [configatron](https://github.com/markbates/configatron) gem.

So all configuration parameters can be accessed with `configatron.param_name` or set with `configatron.param_name = 'value'`.

Here is the list of all configuration parameters:
+ `configatron.NVDFeedScraper.feed.default_storage_location` <span id="configatron_NVDFeedScraper_feed_default_storage_location"></span>
  - **default value**: `'/tmp/'`
  - **type**: `String`
  - **description**: default feed storage location, where will be stored JSON feeds and archives by default.
