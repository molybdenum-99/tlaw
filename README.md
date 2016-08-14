# TLAW - The Last API Wrapper

TLAW (pronounce it like tea+love, or whatever) is.

Look at weather gems:

```ruby
# https://github.com/darkskyapp/forecast-ruby
forecast = ForecastIO.forecast(37.8267, -122.423)
# => Hashie with summary, hourly/daily/minutely - Hashies with summaries and data

# https://github.com/coderhs/ruby_open_weather_map
OpenWeather::Current.city("Cochin, IN")
OpenWeather::Current.city_id("1273874")
OpenWeather::Current.geocode(9.94, 76.26)
OpenWeather::Current.rectangle_zone(12, 32, 15, 37, 10)
OpenWeather::Forecast.city("Cochin, IN")
# => hash, f['list'] - array of hashes of hashes, date is number

# https://github.com/stewart/weather-api
response = Weather.lookup(9830, Weather::Units::CELSIUS)
Weather::Response - set of deeply nested objects, not hashes

# https://github.com/nick-aschenbach/accuweather
location_array = Accuweather.city_search(name: 'kharkiv')
res = Accuweather.get_conditions(location_id: 'cityId:53286')
# => fetches data, but returns Parser object
res.forecast
# => Array of custom objects, deeply nested

# https://github.com/wnadeau/wunderground
api.[feature]_and_[another feature]_for("location string")
api.history20101231_for("77789")
api.forecast_for('Kharkiv')
# => bunch of hashes
```

1-level hashes (flat hash)
data tables (array of hashes = data table)
ultimate inspectability
self-documentability
discoverability

Absolutely easy to define dicsoverable low-level API (~method-per-endpoint,
no complicated data postprocessing)
Helpers for defining hi-level API

paging helpers

There is no such thing as a "perfect orthogonal REST API" in real world.
