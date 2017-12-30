# Features

More than data feed file management and downloading `nvd_feed_api` let you search for CVEs and automate a lot of tasks.

+ **Deamon**: the scraper can run 24/7 without being restarted thanks to update methods
+ **Documentation**: an API documentation with example is provided
+ **Offline loading**: JSON feed files can be manually downloaded from the NVD website and put in the `destination_path` so:
  - you can safely restart the scraper without having to re-download all feeds
  - you can re-use already downloaded files in case of several scraper deployment
