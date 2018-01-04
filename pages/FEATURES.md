# Features

More than data feed file management and downloading `nvd_feed_api` let you search for CVEs and automate a lot of tasks.

+ **24/7**: the scraper can run 24/7 without being restarted thanks to update methods
+ **Documentation**: an API documentation with example is provided
+ **FOSS**: Free and open-source software of course
+ **Offline loading**: JSON feed files can be manually downloaded from the NVD website and put in the `destination_path` so:
  - you can safely restart the scraper without having to re-download all feeds
  - you can re-use already downloaded files in case of several scraper deployment
+ **Quality**: we use [rubocop](http://rubocop.readthedocs.io/) and [codacy](https://www.codacy.com/)
+ **Simple**: available as a gem and easy to install
