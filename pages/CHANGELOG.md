# [0.2.1] - 2 May 2018

[0.2.1]: https://gitlab.com/noraj/nvd_api/tags/v0.2.1

- Gitlab-CI: test vith ruby 2.4.x and 2.5.x
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

- Add some contribution guidelines, issue and MR templates.
- Improve the README to be a good entrypoint.
- Improve the FEATURES.

# [0.0.1.rc1] - 4 January 2018

[0.0.1.rc1]: https://gitlab.com/noraj/nvd_api/tags/v0.0.1.rc1

- First release.