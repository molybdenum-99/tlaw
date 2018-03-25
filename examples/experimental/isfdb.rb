require 'pp'

$:.unshift 'lib'
require 'tlaw'

class ISFDB < TLAW::API
  define do
    base 'http://www.isfdb.org/cgi-bin/rest'

    endpoint :isbn, '/getpub.cgi?{isbn}', xml: true
  end
end

i = ISFDB.new

#pp i.isbn('0399137378')["ISFDB.Publications.Publication"].last
pp i.isbn('038533348X')["ISFDB.Publications.Publication"].to_a