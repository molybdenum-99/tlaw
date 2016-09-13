#!/usr/bin/env ruby
require_relative 'demo_base'

# That's an example of TLAW's strength.
#
# Urbandictionary API is really small (just two endpoints, only one of
# which is actually useful, because /random is more like a joke).
#
# But you still need to remember the protocol, parse the answer and so
# on.
#
# There is even separate gem: https://github.com/ryangreenberg/urban_dictionary
# Its `lib` folder contains 7 files, 9 classes/modules and 300 lines of
# code, I kid you not.
#
# I have no intention to offend that gem's author! I just saying that's
# what you get when you need to design everything from scratch, like HTTP
# client and params processing and response parsing and whatnot.
#
# Here is our version (17 codelines, including namespacing and bit of docs):
#
module TLAW
  module Examples
    class UrbanDictionary < TLAW::API
      define do
        desc %Q{
          Really small API. Described as "official but undocumented"
          by some.
        }

        base 'http://api.urbandictionary.com/v0'

        endpoint :define, '/define?term={term}' do
          param :term, required: true
        end

        endpoint :random, '/random'
      end
    end
  end
end

d = TLAW::Examples::UrbanDictionary.new

p d.describe
# TLAW::Examples::UrbanDictionary.new()
#   Really small API. Described as "official but undocumented"
#   by some.
#
#
#   Endpoints:
#
#   .define(term)
#
#   .random()


res = d.define('trollface')

pp res
# {"tags"=>
#   ["troll",
#    "trolling",
#    "meme",
#    "4chan",
#    "troll face",
#    "coolface",
#    "trollfacing",
#    "trolls",
#    "backpfeifengesicht",
#    "derp"],
#  "result_type"=>"exact",
#  "list"=>
#   #<TLAW::DataTable[definition, permalink, thumbs_up, author, word, defid, current_vote, example, thumbs_down] x 7>,
#  "sounds"=>[]}

pp res['list'].columns('word', 'thumbs_up', 'thumbs_down').to_a
[{"word"=>"Trollface", "thumbs_up"=>418, "thumbs_down"=>99},
 {"word"=>"Troll Face", "thumbs_up"=>481, "thumbs_down"=>318},
 {"word"=>"Troll Face", "thumbs_up"=>340, "thumbs_down"=>184},
 {"word"=>"trollface", "thumbs_up"=>115, "thumbs_down"=>35},
 {"word"=>"trollface", "thumbs_up"=>94, "thumbs_down"=>30},
 {"word"=>"trollface", "thumbs_up"=>61, "thumbs_down"=>54},
 {"word"=>"Troll Face", "thumbs_up"=>81, "thumbs_down"=>181}]

pp d.random['list'].columns('word', 'example').first(3).to_a
[{"word"=>"pH", "example"=>"Get that ph out of the shower.\r\n\r\n "},
 {"word"=>"spocking",
  "example"=>
   "The dirty bitch couldn’t get enough so I gave her a damn good spocking"},
 {"word"=>"mormon",
  "example"=>
   "Oh my gosh are the Smiths mormons?! We better have a party so they can bring some frickin' sweet green jello!..."}]

# That's it  ¯\_(ツ)_/¯
