require_relative 'base'
require_relative '../examples/open_weather_map'

weather = OpenWeatherMap.new(appid: '90d73c1188829195d023b5a5fc6399e1', units: :metric)

#p weather.namespaces[:current]
#p weather.describe
#pp weather.forecast.city('Kharkiv')['list']['dt']
#pp weather.batch_current.around(49.999892, 36.242392, cnt: 30)
#pp weather.batch_current.endpoints[:around].class.to_code
#pp weather.current.city('Kharkiv')
#pp weather.current.city('Chiang Mai')
#pp weather.current.city('Sofia')
#pp weather.batch_current.around(49.999892, 36.242392, cnt: 30)['list']['name'].sort
#pp weather.batch_current.group([707860,519188,1283378,708546])['list']['name']
#p weather.current.describe
#puts weather.current.endpoints.values.map(&:describe).join("\n----\n")

#pp weather.find(:like).city('London')['list']

#pp weather.forecast.city('London')['list']

#pp weather.current.city('Chiang Mai')
#pp weather.current.city('London')

#pp weather.find.city_id(1153671)

#pp weather.find(:like).city('London')
#pp weather.find(:like).method(:city).parameters
#pp weather.find(:like, cnt: 20).by_name('kha')['list']['name']
#pp weather.find.around(51.51, -0.13)['list']['name']
#pp weather.find.around(151.51, -0.13)['list']['name']
#pp weather.find.inside(lng_left: 12, lat_bottom: 32, lng_right: 15, lat_top: 37)
#pp weather.namespaces[:find].endpoints[:by_name] #.inside(12, 32, 15, 37)

#pp weather.current.group([707860,519188,1283378,708546])['list']['sys.country']

pp weather.find.by_name('London', accurate: false)['list']['name']
