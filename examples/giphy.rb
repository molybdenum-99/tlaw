require 'pp'

$:.unshift 'lib'
require 'tlaw'


module TLAW
  module Examples
    class Giphy < TLAW::API
      define do
        desc %Q{
          Wrapper for [Giphy](https://giphy.com/) GIF hosting service API.
        }

        docs 'https://developers.giphy.com/docs/'

        base 'http://api.giphy.com/v1'

        param :api_key, required: true,
          desc: %Q{For development, create it at your [dashboard](https://developers.giphy.com/dashboard/?create=true).
                   Note that you'll need to request different key for production use.}
        param :lang,
          desc: %Q{2-letter ISO 639-1 language code.
                  [Full list of supported languages](https://developers.giphy.com/docs/)}

        %i[gifs stickers].each do |ns|
          namespace ns do
            if ns == :gifs
              desc 'Fetch GIPHY GIFs.'
            else
              desc 'Fetch GIPHY stickers (GIFs with transparent background).'
            end

            endpoint :search do
              desc 'Search all GIFs by word or phrase.'

              param :query, field: :q, keyword: false, required: true, desc: 'Search string'
              param :limit, :to_i, desc: 'Max number of results to return'
              param :offset, :to_i, desc: 'Results offset'
              param :rating, enum: %w[y g pg pg-13 r unrated nsfw], desc: 'Parental advisory rating'
            end

            endpoint :trending do
              desc 'Fetch GIFs currently trending online. Hand curated by the GIPHY editorial team.'

              param :limit, :to_i, desc: 'Max number of results to return'
              param :rating, enum: %w[y g pg pg-13 r unrated nsfw], desc: 'Parental advisory rating'
            end

            endpoint :translate do
              desc 'Translates phrase to GIFs "vocabulary".'

              param :phrase, field: :s, keyword: false, required: true, desc: 'Phrase to translate'

              post_process(/\.(size|mp4_size|webp_size|width|height|frames)/, &:to_i)
            end

            endpoint :random do
              desc 'Returns a random GIF, optionally limited by tag.'

              param :tag
              param :rating, desc: 'Parental advisory rating'
            end

            post_process_items('data') do
              post_process(/\.(size|mp4_size|webp_size|width|height|frames)/, &:to_i)
            end
          end
        end

        namespace :gifs do
          endpoint :[], '/{id}' do
            desc 'One GIF by unique id.'

            param :id, required: true
          end

          endpoint :multiple, '/?ids={ids}' do
            desc 'Sevaral GIFs by unique ids.'

            param :ids, :to_a, required: true
          end
        end
      end
    end
  end
end
