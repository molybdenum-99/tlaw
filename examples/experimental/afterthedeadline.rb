require 'pp'

$:.unshift 'lib'
require 'tlaw'

#http://docs.themoviedb.apiary.io/#reference/movies/movielatest

class AfterTheDeadline < TLAW::API
  define do
    base 'http://service.afterthedeadline.com'

    param :key, required: true

    endpoint :document, '/checkDocument', xml: true do
      param :data, keyword: false
    end
  end
end

atd = AfterTheDeadline.new(key: 'test-tlaw')

pp atd.document("Isn't it cool and cute and awesme? Yepx it is.")['results.error'].to_a
