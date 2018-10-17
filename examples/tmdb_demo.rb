#!/usr/bin/env ruby
require_relative 'demo_base'

# This example demonstrates how TLAW allows you to define and redefine
# API wrappers on the fly—to the extent you need and without much
# bothering—and still have all the goodies.

# For example, you have pretty large and complicated TheMoviesDatabase API:
# http://docs.themoviedb.apiary.io/
# ...and all you want is just to search for movies and get their posters.
# All existing TMDB Ruby wrappers (I know at least three) are strange.
#
# What you'll do?
#
# That's what:

class TMDB < TLAW::API
  define do
    base 'http://api.themoviedb.org/3'
    param :api_key, required: true
    param :language, default: 'en'

    namespace :movies, '/movie' do
      namespace :[], '/{id}' do
        param :id, required: true

        endpoint :images
      end
    end

    namespace :search do
      endpoint :movie do
        param :query, required: true, keyword: false

        post_process_items('results') {
          post_process 'release_date', &Date.method(:parse)
        }
      end
    end
  end
end

# You need to run it like TMDB={your_key} ./examples/tmdb_demo.rb
tmdb = TMDB.new(api_key: ENV['TMDB'])

pp tmdb.search.movie('guardians of the galaxy')
# {"page"=>1,
#  "results"=>
#   #<TLAW::DataTable[poster_path, adult, overview, release_date, genre_ids, id, original_title, original_language, title, backdrop_path, popularity, vote_count, video, vote_average] x 2>,
#  "total_results"=>2,
#  "total_pages"=>1}

pp tmdb.search.movie('guardians of the galaxy')['results'].first
# {"poster_path"=>"/y31QB9kn3XSudA15tV7UWQ9XLuW.jpg",
#  "adult"=>false,
#  "overview"=>
#   "Light years from Earth, 26 years after being abducted, Peter Quill finds himself the prime target of a manhunt after discovering an orb wanted by Ronan the Accuser.",
#  "release_date"=>#<Date: 2014-07-30 ((2456869j,0s,0n),+0s,2299161j)>,
#  "genre_ids"=>[28, 878, 12],
#  "id"=>118340,
#  "original_title"=>"Guardians of the Galaxy",
#  "original_language"=>"en",
#  "title"=>"Guardians of the Galaxy",
#  "backdrop_path"=>"/bHarw8xrmQeqf3t8HpuMY7zoK4x.jpg",
#  "popularity"=>12.287455,
#  "vote_count"=>5067,
#  "video"=>false,
#  "vote_average"=>7.96}

# OK, now we have an id
pp tmdb.movies[118340].images

# Note, that [] is also namespace accessor here :) With param. See API
# description above.

pp tmdb.movies[118340].images['posters'].last
# {"aspect_ratio"=>0.666666666666667,
#  "file_path"=>"/6YUodKKkqIIDx6Hk7ZkaVOxnWND.jpg",
#  "height"=>1500,
#  "iso_639_1"=>"ru",
#  "vote_average"=>0.0,
#  "vote_count"=>0,
#  "width"=>1000}

# Hmm, maybe we need some path post-processing?.. How about adding it
# right now? Assuming our API is already described by someone else...
tmdb.class.define do
  namespace :movies do
    namespace :[] do
      endpoint :images do
        post_process_items 'posters' do
          post_process('file_path') { |p| 'https://image.tmdb.org/t/p/original' + p }
        end
      end
    end
  end
end

pp tmdb.movies[118340].images['posters'].last
# Ah, much better!
#
# {"aspect_ratio"=>0.666666666666667,
#  "file_path"=>
#   "https://image.tmdb.org/t/p/original/6YUodKKkqIIDx6Hk7ZkaVOxnWND.jpg",
#  "height"=>1500,
#  "iso_639_1"=>"ru",
#  "vote_average"=>0.0,
#  "vote_count"=>0,
#  "width"=>1000}


# Note, that despite not adding a bit of documentation, you still have
# your API wrapper discoverable:
p TMDB
# #<TMDB: call-sequence: TMDB.new(api_key:, language: "en"); namespaces: movies, search; docs: .describe>
p tmdb.movies.describe
# .movies()
#
#
#   Namespaces:
#
#   .[](id)

p tmdb.movies.namespace(:[]).describe
# .[](id)
#   @param id
#
#   Endpoints:
#
#   .images()

# So, you can still investigate, navigate and get meaningful API errors
# with backtraces... While you spent only like 15 lines on API description.
