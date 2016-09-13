# TLAW - The Last API Wrapper

[![Gem Version](https://badge.fury.io/rb/tlaw.svg)](http://badge.fury.io/rb/tlaw)
[![Code Climate](https://codeclimate.com/github/molybdenum-99/tlaw/badges/gpa.svg)](https://codeclimate.com/github/molybdenum-99/tlaw)
[![Build Status](https://travis-ci.org/molybdenum-99/tlaw.svg?branch=master)](https://travis-ci.org/molybdenum-99/tlaw)
[![Coverage Status](https://coveralls.io/repos/molybdenum-99/tlaw/badge.svg?branch=master)](https://coveralls.io/r/molybdenum-99/tlaw?branch=master)

TLAW (pronounce it like "tea+love"... or whatever) is the last (and only) API
wrapper framework for _get-only APIes_<sup>[*](#get-only-api)</sup> (think
weather, search, economical indicators, geonames and so on).

## Table Of Contents

* [Features](#features)
* [Why TLAW?](#why-tlaw)
* [Usage](#usage)
  * [URLs and params description](#urls-and-params-description)
  * [Response processing](#response-processing)
    * [Flat hashes](#flat-hashes)
    * [DataTable](#datatable)
    * [Post-processing](#post-processing)
    * [All at once](#all-at-once)
  * [Documentability](#documentability)
* [Some demos](#some-demos)
* [Installation & compatibility](#installation-&-compatibility)
* [Upcoming features](#upcoming-features)
* [Get-only API](#get-only-api)
* [Current status](#current-status)
* [Links](#links)
* [Author](#author)
* [License](#license)

## Features

* **Pragmatic**: thorougly designed with tens of real world examples in mind,
  not just your textbook's "perfect orthogonal REST API";
* **Opinionated**: goal is clean and logical Ruby libary, not just mechanical
  1-by-1 endpoint-per-method wrapper for every fancy hivemind invention;
* **Easy and readable** definitions;
* **Discoverable**: once API defined in TLAW terms, you can easily investigate
  it in runtime, obtain meaningful errors like "param `foo` is missing
  while trying to access endpoint `bar`" and so on;
* **Sane metaprogramming**: allows to define entire branchy API wrapper with
  tons of pathes and endpoints in really concise manner, while creating
  _all_ corresponding classes/methods at definition time: so, at runtime
  you have no 20-level dynamic dispatching, just your usual method calls
  with clearly defined arguments and compact backtraces.

Take a look at our "model" OpenWeatherMap [wrapper](https://github.com/molybdenum-99/tlaw/blob/master/examples/open_weather_map.rb)
and [demo](https://github.com/molybdenum-99/tlaw/blob/master/examples/open_weather_map_demo.rb)
of its usage, showing how all those things work in reality.

## Why TLAW?

There are ton of small (and not-so-small) useful APIs about world around:
weather, movies, geographical features, dictionaries, world countries
statistics... Typically, when trying to use one of them from Ruby (or,
to be honest, from any programming language), you are stuck with two
options:

1. Study and use (or invent and build) some custom hand-made Wrapper
  Library™ with ton of very custom design decisions (should responses
  be just hashes, or [Hashie](https://github.com/intridea/hashie)s, or
  real classes for each kind of response? What are the inputs? Where should
  api key go, to global param?); or
2. Just "go commando" (sorry for the bad pun): construct URLs yourself,
  parse responses yourself, control params (or ignore the control) yourself.

TLAW tries to close this gap: provide a base for _breath-easy_ API description
which produces solid, fast and reliable wrappers.

## Usage

### URLs and params description

```ruby
class Example < TLAW::API
  base 'http://api.example.com'

  param :api_key, required: true # this would be necessary for API instance creation
  # So, the API instance would be e = Example.new(api_key: '123')
  # ...and parameter ?api_key=123 would be added to any request

  endpoint :foo # The simplest endpoint, will query "http://api.example.com/foo"
  # And then you just do e.foo and obtain result

  endpoint :bar, '/baz.json' # Path to query rewritten, will query "http://api.example.com/baz.json"
  # Method is still e.bar, though.

  # Now, for params definition:
  endpont :movie do
    param :id
  end
  # Method call would be movie(id: '123')
  # Generated URL would be "http://api.example.com/movie?id=123"

  # When param is part of the path, you can use RFC 6570
  # URL template standard:
  endpoint :movie, '/movies/{id}'
  # That would generate method which is called like movie('123')
  # ...and call to "http://api.example.com/movies/123"

  # Now, we can stack endpoints in namespaces
  namespace :foo do # adds /foo to path
    namespace :bar, '/baz' do # optional path parameter works
      endpoint :blah # URL for call would be "http://api.example.com/foo/baz/blah"
      # And method call would be like e.foo.bar.blah(parameters)
    end

    # URL normalization works, so you can stack in namespaces even
    # things not related to them in source API, "redesigning" API on
    # the fly.
    endpoint :books, '/../books.json' # Real URL would be "http://api.example.com/books"
    # Yet method call is still namespaced like e.foo.books
  end

  # Namespaces can have their own input parameters
  namespace :foo, '/foo/{id}' do
    endpoint :bar # URL would be "http://api.example.com/foo/123/bar
    # method call would be e.foo(123).bar
  end

  # ...and everything works in all possible and useful ways, just check
  # docs and demos.
end
```

Links to definition DSL:
* param
* endpoint
* namespace
* API itself

### Response processing

TLAW is really opinionated about response processing. Main things:

1. [Hashes are "flattened"](#flat-hashes);
2. [Arrays of hashes are converted to `DataTable`s](#datatable);
3. [Post-processors for fields are easily defined](#post-processing)

#### Flat hashes

The main (and usually top-level) answer of (JSON) API is a Hash/dictionary.
TLAW takes all multilevel hashes and make them flat.

Here is an example.

Source API responds like:

```json
{
  "meta": {
    "code": "OK",
  },
  "weahter": {
    "temp": 10,
    "precipation": 138
  },
  "location": {
    "lat": 123,
    "lon": 456
  }
  ...
}
```

But TLAW response to `api.endpoint(params)` would return you a Hash looking
this way:

```json
{
  "meta.code": "OK",
  "weahter.temp": 10,
  "weahter.precipation": 138,
  "location.lat": 123,
  "location.lon": 456
  ...
}
```

Reason? If you think of it and experiment with several examples, typically
with new & unexplored API you'll came up with code like:

```ruby
p response
# => 3 screens of VERY IMPORTANT RESPONSE
p response.class
# => Hash, ah, ok
p response.keys
# => ["meta", "weather", "location"], hmmm...
p response['weather']
# => stil 2.5 screens of unintelligible details
p response['weather'].class
# => Hash, ah!
p response['weather'].keys
# => and ad infinitum, real APIs are easily go 6-8 levels down
```

Now, with "opinionated" TLAW's flattening, for _any_ API you just do
the one and final `response.keys` and that's it: you see every available
data key, deep to the deepest depth.

> NB: probably, in the next versions TLAW will return some Hash descendant,
  which would also still allow you to do `response['weather']` and receive
  that "slice". Or it would not :) We are experimenting!

#### DataTable

The second main type of a (JSON) API answer, or of a part of an answer
is an array of homogenous hashes, like:

* list of data points (date - weather at that date);
* list of data objects (city id - city name - latitude - longitude);
* list of views to the data (climate model - projected temperature);
* and so on.

TLAW wraps this kind of data (array of homogenous hashes, or tables with
named columns) into `DataTable` structure, which you can think of as an
Excel spreadsheet (2d array with named columns), or loose DataFrame
pattern implementation (just like [daru](https://github.com/v0dro/daru)
or [pandas](http://pandas.pydata.org/), but seriously simpler—and much
more suited to the case).

Imagine you have an API responding something like:

```json
{
  "meta": {"count": 20},
  "data": [
    {"date": "2016-09-01", "temp": 20, "humidity": 40},
    {"date": "2016-09-02", "temp": 21, "humidity": 40},
    {"date": "2016-09-03", "temp": 16, "humidity": 36},
    ...
  ]
}
```

With TLAW, you'll see this response this way:

```ruby
pp response
{"meta.count"=>20,
 "data"=>#<TLAW::DataTable[date, temp, humidity] x 20>}
# ^ That's all. Small and easy to grasp what is what. 3 named columns,
#   20 similar rows.

d = response['data']
# => #<TLAW::DataTable[date, temp, humidity] x 20>

d.count # Array-alike
# => 20
d.first
# => {"date" => "2016-09-01", "temp" => 20, "humidity" => 40}

d.keys # Hash-alike
# => ["date", "temp", "humidity"]
d["date"]
# => ["2016-09-01", "2016-09-02", "2016-09-03" ...

# And stuff:
d.to_h
# => {"date" => [...], "temp" => [...] ....
d.to_a
# => [{"date" => ..., "temp" => ..., "humidity" => ...}, {"date" => ...

d.columns('date', 'temp') # column-wise slice
# => #<TLAW::DataTable[date, temp] x 20>
d.columns('date', 'temp').first # and so on
# => {"date" => "2016-09-01", "temp" => 20}
```

Take a look at [DataTable docs](http://www.rubydoc.info/gems/tlaw/TLAW/DataTable)
and join designing it!

#### Post-processing

When you are not happy with result representation, you can post-process
them in several ways:

```ruby
# input is entire response, block can mutate it
post_process { |hash| hash['foo'] = 'bar' }

# input is entire response, and response is fully replaced with block's
# return value
post_process { |hash| hash['foo'] } # Now only "foo"s value will be response

# input is value of response's key "some_key", return value of a block
# becames new value of "some_key".
post_process('some_key') { |val| other_val }

# Post-processing each item, if response['foo'] is array:
post_process_items('foo') {
  # mutate entire item
  post_process { |item| item.delete('bar') }

  # if item is a Hash, replace its "bar" value
  post_process('bar') { |val| val.to_s }
}

# More realistic examples:
post_process('meta.count', &:to_i)
post_process('daily') {
  post_process('date', &Date.method(:parse))
}
post_process('auxiliary_value') { nil } # Nil's will be thrown away completely
```

#### All at once

All described response processing steps are performed in this order:
* parsing and initial flattening of JSON (or XML) hash;
* applying post-processors (and flatten the response after _each_ of
  them);
* make `DataTable`s from arrays of hashes.

### Documentability

You do it this way:

```ruby
class MyAPI < TLAW::API
  desc %Q{
    This is API, it works.
  }

  docs 'http://docs.example.com'

  namespace :ns do
    desc %Q{
      It is some interesting thing.
    }

    docs 'http://docs.example.com/ns'

    endpoint :baz do
      desc %Q{
        Should be useful.
      }

      docs 'http://docs.example.com/ns#baz'

      param :param1,
        desc: %Q{
          You don't need it, really.
        }
    end
  end
end
```

All of above is optional, but when provided, allows to investigate
things at runtime (in IRB/pry or test scripts). Again, look at
[OpenWeatherMap demo](https://github.com/molybdenum-99/tlaw/blob/master/examples/open_weather_map_demo.rb),
it shows how docs could be useful at runtime.

## Some demos

* Full-featured API wrappers:
  * OpenWeatherMap: [source API docs](http://openweathermap.org/api),
    [wrapper](https://github.com/molybdenum-99/tlaw/blob/master/examples/open_weather_map.rb),
    extensively documented [demo code](https://github.com/molybdenum-99/tlaw/blob/master/examples/open_weather_map_demo.rb);
  * ForecastIO: [API docs](https://developer.forecast.io/docs/v2),
    [wrapper](https://github.com/molybdenum-99/tlaw/blob/master/examples/forecast_io.rb),
    [demo code](https://github.com/molybdenum-99/tlaw/blob/master/examples/forecast_io_demo.rb);
* Demos of "fire-and-forget" wrappers:
  * Urbandictionary's small and unofficial
    [API wrapper](https://github.com/molybdenum-99/tlaw/blob/master/examples/urbandictionary_demo.rb);
  * [Partial wrapper](https://github.com/molybdenum-99/tlaw/blob/master/examples/tmdb_demo.rb)
    only for some features of large [TMDB API](docs.themoviedb.apiary.io/).

## Installation & compatibility

Just `gem install tlaw` or add it to your `Gemfile`, nothing fancy.

Required Ruby version is 2.1+, JRuby works, Rubinius seems like not.

## Upcoming features

_(in no particular order)_

* [ ] Expose Faraday options (backends, request headers);
* [ ] Request-headers based auth;
* [ ] Responses caching;
* [ ] Response headers processing DSL;
* [ ] Paging support;
* [ ] Frequency-limited API support (requests counting);
* [ ] YARD docs generation for resulting wrappers;
* [ ] More solid wrapper demos (weather sites, geonames, worldbank);
* [ ] Approaches to testing generated wrappers (just good ol' VCR should
      work, probably);
* [ ] Splat parameters.

## Get-only API

What is those "Get-only APIs" TLAW is suited for?

* It is only for _getting_ data, not changing them (though, API may use
  HTTP POST requests in reality—for example, to transfer large request
  objects);
  * It would be cool if our weather APIs could allow things like
    `POST /weather/kharkiv {sky: 'sunny', temp: '+21°C'}` in the middle
    of December, huh? But we are not leaving in the world like this.
    For now.
* It has utterly simple authentication protocol like "give us `api_key`
  param in query" (though, TLAW plans to support more complex authentication);
* It typically returns JSON answers (though, TLAW supports XML via
  awesome [crack](https://github.com/jnunemaker/crack)).

Alongside already mentioned examples (weather and so on), you can build
TLAW-backed "get-only" wrappers for bigger APIs (like Twitter), when
"gathering twits" is all you need. (Though, to be honest, TLAW's current
authorization abilities is far simpler than
[Twitter requirements](https://dev.twitter.com/oauth/application-only)).

## Current status

It is version 0.0.1. It is tested and documented, but not "tested in
battle", just invented. DSL is subject to be refined and validated,
everything could change (or broke suddenly). Tests are lot, though.

We plan to heavily utilize it for [reality](https://github.com/molybdenum-99/reality),
that would be serious evaluation of approaches and weeknesses.

## Links

* [API Docs](http://www.rubydoc.info/gems/tlaw)

## Author

[Victor Shepelev](http://zverok.github.io/)

## License

[MIT](./LICENSE.txt).
