# Installation

## Production

### Install from rubygems.org

```
$ gem install nvd_feed_api
```

### Build from git

Just replace `x.x.x` with the gem version you see after `gem build`.

```
$ git clone https://gitlab.com/noraj/nvd_api.git nvd_feed_api
$ cd nvd_feed_api
$ gem build nvd_feed_api.gemspec
$ gem install nvd_feed_api-x.x.x.gem
```

Note: if an automatic install is needed you can get the version with `$ gem build nvd_feed_api.gemspec | grep Version | cut -d' ' -f4`.

## Development

### Install from rubygems.org

```
$ gem install --development nvd_feed_api
```

### Build from git

Just replace `x.x.x` with the gem version you see after `gem build`.

```
$ git clone https://gitlab.com/noraj/nvd_api.git nvd_feed_api
$ cd nvd_feed_api
$ gem build nvd_feed_api.gemspec
$ gem install --development nvd_feed_api-x.x.x.gem
```

Note: if an automatic install is needed you can get the version with `$ gem build nvd_feed_api.gemspec | grep Version | cut -d' ' -f4`.
