# [0.7.0] - 01 January 2026

- Breaking changes:
  - Drop support for Ruby 3.1
- Chore:
  - Add support for Ruby 4.0
  - Update dependencies

# [0.6.0] - 29 May 2025

- Enhancements and fixes:
  - migrating from CVE JSON 1.1 to 2.0 spec
    - 1.1 feeds will be removed in the future
    - 1.1 feeds do not contain Deferred status CVEs
- Chore:
  - Update dependencies

# [0.5.0] - 30 March 2025

- Breaking changes:
  - Drop support for Ruby 2.7 and 3.0
- Chore:
  - Add support for Ruby 3.2 & 3.3 & 3.4
  - Update dependencies
  - Add freeze literal string comment

# [0.4.0] - 31 January 2021

- Dependencies:
  - Update to yard [v0.9.27](https://github.com/lsegal/yard/releases/tag/v0.9.27)
    - Move from Redcarpet to CommonMarker markdown provider
    - Move doc syntax from Rdoc to markdown
  - Move dev dependencies from gemspec to gemfile
- Chore:
  - Add support for Ruby 3.1
  - Update rubocop rules

# [0.3.1] - 13 October 2020

[0.3.1]: https://gitlab.com/noraj/nvd_api/tags/v0.3.1

- fix scrap method to reflect NVD feeds page changes
- update dependencies
- update rubocop rules

# [0.3.0] - 22 January 2019

[0.3.0]: https://gitlab.com/noraj/nvd_api/tags/v0.3.0

- update dependencies: updated gemspec, ruby 2.6 support, fix gem doc flag, fix oj crash (seg fault)
- Gemfile.lock: now Gemfile.lock is not ignored anymore
- gitlab-ci: add ruby 2.6 test, add caching key, and anchors for better reuse, always use bundle
- NVDFeedScraper `scrap` method: change return value
- rubocop: fix lint

# [0.2.1] - 2 May 2018

[0.2.1]: https://gitlab.com/noraj/nvd_api/tags/v0.2.1

- Gitlab-CI: test with ruby 2.4.x and 2.5.x
- style: fix Style/ExpandPathArguments cop
- security: fix Security/Open cop, protect from pipe command injection
- test: fix NVD URL after NVD changed it

# [0.2.0] - 20 January 2018

[0.2.0]: https://gitlab.com/noraj/nvd_api/tags/v0.2.0

- new attributes for the Feed class:
  + `data_type`
  + `data_format`
  + `data_version`
  + `data_number_of_cves`
  + `data_timestamp`
- fix `update_feeds` method by using the new `update!` method from the Feed class
- split source code in several files, one by class
- improve tests and documentation

# [0.1.0] - 17 January 2018

[0.1.0]: https://gitlab.com/noraj/nvd_api/tags/v0.1.0

- add support for CVE from 1999 to 2001
- fix tests

# [0.0.3] - 6 January 2018

[0.0.3]: https://gitlab.com/noraj/nvd_api/tags/v0.0.3

- Gitlab-ci supports
- new badges on README
- As rubydoc.info seems bug, use gitlab pages instead for hosting YARD doc

# [0.0.2.pre] - 5 January 2018

[0.0.2.pre]: https://gitlab.com/noraj/nvd_api/tags/v0.0.2.pre

- Test a new version number to fix a bug with rubygems.org
- Correct month name in the dates in the CHANGELOG

# [0.0.1.rc2] - 4 January 2018

[0.0.1.rc2]: https://gitlab.com/noraj/nvd_api/tags/v0.0.1.rc2

- Add some contribution guidelines, issues and MR templates.
- Improve the README to be a good entrypoint.
- Improve the FEATURES.

# [0.0.1.rc1] - 4 January 2018

[0.0.1.rc1]: https://gitlab.com/noraj/nvd_api/tags/v0.0.1.rc1

- First release.
