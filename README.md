# TLAW - The Last API Wrapper

TLAW (pronounce it like "tea+love", or whatever) is the last (and only) API
wrapper framework for _get-only APIes_<sup>[*](#get-only-api)</sup> (think
weather, search, economical indicators, geonames and so on).

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

Take a look at our "model" OpenWeatherMap [wrapper]() and [demo]() of its usage,
showing how all those things work in reality.

## Why TLAW?

There are ton of small (and not-so-small) useful APIs about world around:
weather, movies, geographical features, dictionaries, world countries
statistics... Typically, when trying to use one of them from Ruby (or,
to be honest, from any programming language), you are stuck with two
options:

* Study and use (or invent and build) some custom hand-made Wrapper
  Library™ with ton of very custom design decisions (should responses
  be just hashes, or [Hashie](https://github.com/intridea/hashie)s, or
  real classes for each kind of response? What are the inputs? Where should
  api key go, to global param?);
* Just "ride bareback" (forgive the boldness): construct URLs yourself,
  parse responses yourself, control params (or ignore the control) yourself.

TLAW tries to close this gap: provide a base for _breath-easy_ API description
which produces solid, fast and reliable wrappers.

## What it does

### Input/URLs description

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

  # When param is part of the path
  # You can use RFC-{TODO} URL template standard:
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
* API itself
* namespace
* endpoint
* param

### Output processing

TLAW is really opinionated about response processing. Main things:

1. [Hashes are "flattened"](#flat-hashes);
2. [Arrays of hashes are converted to dataframes](#dataframes);
3. [Post-processors for single and multiple fields are easily defined](#post-processing)

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

Reason: if you think of it and experiment with several examples, typically
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

#### Dataframes

The second main type of (JSON) API answer, or part of an answer is an
array of homogenous hashes, like:

* list of data points (date - weather at that date);
* list of data objects (city id - city name - latitude - longitude);
* list of views to the data (climate model - projected temperature);
* and so on.

TLAW wraps this kind of data (array of homogenous hashes, or tables with
named columns) into `DataTable` structure, which you can think of as an
Excel spreadsheet, or loose DataFrame pattern implementation (just like
pandas or daru, but seriously simpler—and much more suited to the case).

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

Take a look at [DataTable docs]() and invest into its development!

#### Post-processing

#### All at once

### Documentability

## Some demos

* OpenWeatherMap
* ForecastIO
* TMDB

## Upcoming features

_(in no particular order)_

* [ ] Expose Faraday options (backends, request headers);
* [ ] Responses caching;
* [ ] Response headers processing DSL;
* [ ] Paging support;
* [ ] Frequency-limited API support (requests counting);
* [ ] YARD docs generation for resulting wrappers;
* [ ] More solid wrapper demos (weather sites, geonames, worldbank);
* [ ] splat parameters.

## Get-only API

"GET-only API" is an API that is characterised by those properties:

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

## Current status

## Links

* [API Docs](http://www.rubydoc.info/gems/tlaw)

## Author

[Victor Shepelev](http://zverok.github.io/)

## License

[MIT](./LICENSE.txt).
