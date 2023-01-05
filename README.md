# fluent-plugin-seq

[Fluentd](https://fluentd.org/) output plugin for [Seq](https://datalust.co/seq).

This plugin takes the following parameters:

- `host`: The Seq server's hostname (required)
- `port`: The Seq server's port (default: `5341`)
- `scheme`: "http" or "https" (default: `http`)
- `path`: The base path for the Seq server, if not in the URL root (optional, default: `nil`)
- `api_key`: An API key for the Seq HTTP API (optional, default: `nil`)
- `default_level`: The default level for records with unknown levels (default: `DEBUG`)

## Installation

### RubyGems

``` shell
$ gem install fluent-plugin-seq
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-seq"
```

And then execute:

```
$ bundle
```

## Configuration

You can generate configuration template:

``` shell
$ fluent-plugin-config-format output seq
```

You can copy and paste generated documents here.

## Copyright

* Copyright &copy; 2023 - Kryon Systems
* License
  * Apache License, Version 2.0
