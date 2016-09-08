#!/usr/bin/env ruby
require_relative 'demo_base'
require_relative 'open_weather_map'

# This is demonstration of TLAW (The Last API Wrapper) library's behavior
# and opinions.
#
# All of below functionality is created by this API wrapper definition:
# TODO URL

# OK, first thing is: all API wrappers created with TLAW, are
# _discoverable_ by design. In fact, you can understand all you need to
# use the API just from IRB, no need to go to rdoc.info, dig in code,
# or, my favourite thing, "see arguments explanation at original API
# site".

# Let's see:

p TLAW::Examples::OpenWeatherMap
# => #<TLAW::Examples::OpenWeatherMap: call-sequence: TLAW::Examples::OpenWeatherMap.new(appid:, lang: "en", units: :standard); namespaces: current, find, forecast; docs: .describe>

# Let's try this .describe thing which inspect recommends:

p TLAW::Examples::OpenWeatherMap.describe
# TLAW::Examples::OpenWeatherMap.new(appid:, lang: "en", units: :standard)
#   API for [OpenWeatherMap](http://openweathermap.org/). Only parts
#   available for free are implemented (as only them could be tested).
#
#   See full docs at http://openweathermap.org/api
#
#   @param appid You need to receive it at http://openweathermap.org/appid (free)
#   @param lang Language of API responses (affects weather description only).
#     See http://openweathermap.org/current#multi for list of supported languages. (default = "en")
#   @param units Units for temperature and other values. Standard is Kelvin.
#     Possible values: :standard, :metric, :imperial (default = :standard)
#
#   Namespaces:
#
#   .current()
#     Allows to obtain current weather at one place, designated
#     by city, location or zip code.
#
#   .find()
#     Allows to find some place (and weather in it) by set of input
#     parameters.
#
#   .forecast()
#     Allows to obtain weather forecast for 5 days with 3-hour
#     frequency.

# Note that this multiline output is produced by `p`! So, in IRB/pry
# session it would be exactly the same: you just say "something.describe",
# and it is just printed the most convenient way.

# Let's look closer to some of those namespaces:
p TLAW::Examples::OpenWeatherMap.namespaces[:current]
# => #<TLAW::Examples::OpenWeatherMap::Current: call-sequence: current(); endpoints: city, city_id, location, zip, group; docs: .describe>

# .describe, anyone?
p TLAW::Examples::OpenWeatherMap.namespaces[:current].describe
# .current()
#   Allows to obtain current weather at one place, designated
#   by city, location or zip code.
#
#   Docs: http://openweathermap.org/current
#
#
#   Endpoints:
#
#   .city(city, country_code=nil)
#     Current weather by city name (with optional country code
#     specification).
#
#   .city_id(city_id)
#     Current weather by city id. Recommended by OpenWeatherMap
#     docs.
#
#   .location(lat, lng)
#     Current weather by geographic coordinates.
#
#   .zip(zip, country_code=nil)
#     Current weather by ZIP code (with optional country code
#     specification).
#
#   .group(city_ids)
#     Current weather in several cities by their ids.

# And further:
p TLAW::Examples::OpenWeatherMap
  .namespaces[:current].endpoints[:city]
# => #<TLAW::Examples::OpenWeatherMap::Current::City: call-sequence: city(city, country_code=nil); docs: .describe>

p TLAW::Examples::OpenWeatherMap
  .namespaces[:current].endpoints[:city].describe
# .city(city, country_code=nil)
#   Current weather by city name (with optional country code
#   specification).
#
#   Docs: http://openweathermap.org/current#name
#
#   @param city City name
#   @param country_code ISO 3166 2-letter country code

# Note, that all above classes and methods are generated at moment of
# API definition, so there is no cumbersome dispatching at runtime:

p TLAW::Examples::OpenWeatherMap.instance_methods(false)
# => [:current, :find, :forecast]
p TLAW::Examples::OpenWeatherMap::Current.instance_methods(false)
# => [:city, :city_id, :location, :zip, :group]
p TLAW::Examples::OpenWeatherMap::Current.instance_method(:city).parameters
# => [[:req, :city], [:opt, :country_code]]

# E.g. namespace is a class, providing methods for all the child
# namespaces and endpoints! And all params are just method params.

# OK, let's go for some real things, not just documentation reading.

# You need to create key here: http://openweathermap.org/appid
# And run the script this way:
#
#    OPEN_WEATHER_MAP={your_id} examples/open_weather_map_demo.rb
#
weather = TLAW::Examples::OpenWeatherMap
  .new(appid: ENV['OPEN_WEATHER_MAP'], units: :metric)
p weather
# => #<TLAW::Examples::OpenWeatherMap.new(appid: {your id}, lang: nil, units: :metric) namespaces: current, find, forecast; docs: .describe>

# Looks familiar and nothing new.

p weather.current
# => #<current() endpoints: city, city_id, location, zip, group; docs: .describe>

# Saem.

pp weather.current.city('Kharkiv')
# {"weather.id"=>800,
#  "weather.main"=>"Clear",
#  "weather.description"=>"clear sky",
#  "weather.icon"=>"http://openweathermap.org/img/w/01n.png",
#  "base"=>"cmc stations",
#  "main.temp"=>23,
#  "main.pressure"=>1013,
#  "main.humidity"=>40,
#  "main.temp_min"=>23,
#  "main.temp_max"=>23,
#  "wind.speed"=>2,
#  "wind.deg"=>190,
#  "clouds.all"=>0,
#  "dt"=>2016-09-05 20:30:00 +0300,
#  "sys.type"=>1,
#  "sys.id"=>7355,
#  "sys.message"=>0.0115,
#  "sys.country"=>"UA",
#  "sys.sunrise"=>2016-09-05 05:57:26 +0300,
#  "sys.sunset"=>2016-09-05 19:08:13 +0300,
#  "id"=>706483,
#  "name"=>"Kharkiv",
#  "cod"=>200,
#  "coord"=>#<Geo::Coord 50.000000,36.250000>}

# Whoa!
#
# What we see here (except for "OK, it works")?
#
# Several pretty improtant things:
#
# * TLAW response processing is _highly opinionated_. It tends do flatten
#   all the hashes: original has something like
#      {weather: {...}, main: {...}, sys: {...}
# * It is done, again, for the sake of _discoverability_. You, like, see
#   at once all things API response proposes; you can do `response.keys`
#   to understand what you got instead of `response.keys`, hm,
#   `response['weather'].class`, ah, ok, `response['weather'].keys` and
#   so on;
# * TLAW allows easy postprocessing of response: our example API parses
#   timestamps into proper ruby times, and (just to promote related gem),
#   converts "coord.lat" and "coord.lng" to one instance of a Geo::Coord,
#   from https://github.com/zverok/geo_coord
#

# Finally, one HUGE design decision related to "opinionated response
# processing":
pp weather.forecast.city('Kharkiv')
# {"city.id"=>706483,
#  "city.name"=>"Kharkiv",
#  "city.country"=>"UA",
#  "city.population"=>0,
#  "city.sys.population"=>0,
#  "cod"=>"200",
#  "message"=>0.0276,
#  "cnt"=>40,
#  "list"=>
#   #<TLAW::DataTable[dt, main.temp, main.temp_min, main.temp_max, main.pressure, main.sea_level, main.grnd_level, main.humidity, main.temp_kf, weather.id, weather.main, weather.description, weather.icon, clouds.all, wind.speed, wind.deg, sys.pod] x 40>,
#  "city.coord"=>#<Geo::Coord 50.000000,36.250000>}

# Hmm? What is this DataTable thingy? It is (loosy) implementation of
# DataFrame data type. You can think of it as an array of homogenous
# hashes -- which could be considered the main type of useful JSON API
# data.
forecasts = weather.forecast.city('Kharkiv')['list']

p forecasts.count
# => 40
p forecasts.keys
# => ["dt", "main.temp", "main.temp_min", "main.temp_max", "main.pressure", "main.sea_level", "main.grnd_level", "main.humidity", "main.temp_kf", "weather.id", "weather.main", "weather.description", "weather.icon", "clouds.all", "wind.speed", "wind.deg", "sys.pod"]
p forecasts.first
# => {"dt"=>2016-09-06 00:00:00 +0300, "main.temp"=>12.67, "main.temp_min"=>12.67, "main.temp_max"=>15.84, "main.pressure"=>1006.67, "main.sea_level"=>1026.62, "main.grnd_level"=>1006.67, "main.humidity"=>74, "main.temp_kf"=>-3.17, "weather.id"=>800, "weather.main"=>"Clear", "weather.description"=>"clear sky", "weather.icon"=>"http://openweathermap.org/img/w/01n.png", "clouds.all"=>0, "wind.speed"=>1.26, "wind.deg"=>218.509, "sys.pod"=>"n"}

p forecasts['dt'].first(3)
# => [2016-09-06 00:00:00 +0300, 2016-09-06 03:00:00 +0300, 2016-09-06 06:00:00 +0300]

p forecasts.columns('dt', 'main.temp').to_a.first(3)
# => [{"dt"=>2016-09-06 00:00:00 +0300, "main.temp"=>12.67}, {"dt"=>2016-09-06 03:00:00 +0300, "main.temp"=>11.65}, {"dt"=>2016-09-06 06:00:00 +0300, "main.temp"=>12.41}]

# All of it works and you can check it by yourself.
#
# Again, EVERYTHING you can see in this example is created by short and
# focused API definition: TODO URL

pp weather.forecast.city_id(524901)['list']
