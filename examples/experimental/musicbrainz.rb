require 'pp'

$:.unshift 'lib'
require 'tlaw'

class MusicBrainz < TLAW::API
  define do
    base 'http://musicbrainz.org/ws/2'

    endpoint :area, '/area/{id}?fmt=json'

    namespace :artist do
      endpoint :area, '?area={area_id}&fmt=json'
      endpoint :get, '/{id}?fmt=json' do
        param :inc, :to_a, format: ->(a) { a.join('+') }
      end
    end
  end
end

mb = MusicBrainz.new

#pp mb.area '37572420-4b2c-47e5-bf2b-536c9a50a362'
#pp mb.artist.area('904768d0-61ca-3c40-93ac-93adc36fef4b')['artists'].first
res = mb.artist.get('00496bc8-93bf-4284-a3ea-cfd97eb99b2f', inc: %w[recordings releases release-groups works])
pp res['recordings'].first
pp res['releases'].first
