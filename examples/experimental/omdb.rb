require 'pp'

$:.unshift 'lib'
require 'tlaw'

#http://docs.themoviedb.apiary.io/#reference/movies/movielatest

class OMDB < TLAW::API
  define do
    base 'http://www.omdbapi.com'
    #param :api_key, required: true

    SPLIT = ->(v) { v.split(/\s*,\s*/) }

    endpoint :by_id, path: '/?i={imdb_id}' do
      param :imdb_id, required: true

      param :type, enum: %i[movie series episode]
      param :year, :to_i, field: :y
      param :plot, enum: %i[short full]
      param :tomatoes, enum: [true, false]

      post_process('Released', &Date.method(:parse))
      post_process('imdbRating', &:to_f)
      post_process('imdbVotes') { |v| v.gsub(',', '').to_i }
      post_process('totalSeasons', &:to_i)
    end

    endpoint :by_title, path: '/?t={title}' do
      param :title, required: true

      param :type, enum: %i[movie series episode]
      param :year, :to_i, field: :y
      param :plot, enum: %i[short full]
      param :tomatoes, enum: [true, false]

      post_process('Released', &Date.method(:parse))
      post_process('imdbRating', &:to_f)
      post_process('imdbVotes') { |v| v.gsub(',', '').to_i }

      post_process('Metascore', &:to_i)

      post_process('totalSeasons', &:to_i)

      post_process('Genre', &SPLIT)
      post_process('Country', &SPLIT)
      post_process('Writer', &SPLIT)
      post_process('Actors', &SPLIT)
    end

    endpoint :search, path: '/?s={search}' do
      param :search, required: true

      param :type, enum: %i[movie series episode]
      param :year, :to_i, field: :y
      param :page, :to_i
    end

    post_process do |response|
      response.delete('Response') == 'False' and fail(response['Error'])
    end
  end
end

o = OMDB.new

#pp o.by_id("tt0944947")
pp o.by_title('Suicide Squad', tomatoes: true, plot: :full)
#pp o.search('Game of')['Search'].first
