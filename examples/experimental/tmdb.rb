require 'pp'

$:.unshift 'lib'
require 'tlaw'

#http://docs.themoviedb.apiary.io/#reference/movies/movielatest

class TMDB < TLAW::API
  define do
    base 'http://api.themoviedb.org/3'
    param :api_key, required: true
    param :language, default: 'en'

    namespace :movies, '/movie' do
      namespace :[], '/{id}' do
        param :id, required: true

        endpoint :get, ''

        endpoint :alt_titles

        endpoint :images
      end

      endpoint :latest
      endpoint :now_playing do
        param :page, enum: 1..1000, default: 1
      end

      endpoint :upcoming
    end

    namespace :search do
      endpoint :movie do
        param :query, required: true, keyword_argument: false

        #post_process_items 'results', 'release_date', &Date.method(:parse)
        # TODO: post-process image pathes!
      end
    end

    # TODO: should work!
    #post_process_items 'results', 'release_date', &Date.method(:parse)
  end
end

tmdb = TMDB.new(api_key: ENV['TMDB'], language: 'uk')

#pp tmdb.movies.upcoming['results'].columns(:release_date, :title).to_a
#pp tmdb.movies[413898].images
#p tmdb.describe
#pp tmdb.search.movie('Terminator')['results'].first
p tmdb.movies[1187043].get
