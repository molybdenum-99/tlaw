require 'pp'

$:.unshift 'lib'
require 'tlaw'

class Reddit < TLAW::API
  define do
    base 'https://www.reddit.com'

    post_process_items 'data.children' do
      post_process("data.permalink") { |v| "https://www.reddit.com#{v}" }
      post_process("data.created", &Time.method(:at))
    end

    namespace :r, '/r/{subreddit}' do
      endpoint :new, '/new.json' do
      end
    end
  end
end

r = Reddit.new
res = r.r(:ruby).new
p res['data.children']['data.ups']
p res['data.children']['data.num_comments']
