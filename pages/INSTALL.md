# Installation

## Production

### Install from rubygems.org

```
$ gem install nvd_feed_api
```

## Development

It's better to use [RVM](https://rvm.io/) to have latests version of ruby and to avoid trashing your system ruby.

To keep clean gem dependencies create a gemset with rvm:

```
$ rvm gemset create nvd_feed_api
$ rvm gemset use nvd_feed_api
```

### Install from rubygems.org

```
$ gem install --development nvd_feed_api
```

### Build from git

Just replace `x.x.x` with the gem version you see after `gem build`.

```
$ git clone https://gitlab.com/noraj/nvd_api.git nvd_feed_api
$ cd nvd_feed_api
$ gem install bundle
$ ./bin/nvd_feed_api_setup
$ rake install
```

You can use `nvd_feed_api_console` to launch `irb` with the API required.

Alternatively to build you can use:

```
$ git clone https://gitlab.com/noraj/nvd_api.git nvd_feed_api
$ cd nvd_feed_api
$ gem install bundle
$ gem build nvd_feed_api.gemspec
$ gem install --development nvd_feed_api-x.x.x.gem
```

Note: if an automatic install is needed you can get the version with `$ gem build nvd_feed_api.gemspec | grep Version | cut -d' ' -f4`.

### Run the API in irb without installing the gem

Usefull when you want to try your changes without building the gem and re-installing it each time.

```
$ git clone https://gitlab.com/noraj/nvd_api.git nvd_feed_api
$ cd nvd_feed_api
$ gem install bundle
$ ./bin/nvd_feed_api_setup
$ irb -Ilib -rnvd_feed_api
```
