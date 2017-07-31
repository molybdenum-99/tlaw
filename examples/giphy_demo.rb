#!/usr/bin/env ruby
require_relative 'demo_base'
require_relative 'giphy'

giphy = TLAW::Examples::Giphy.new(api_key: ENV['GIPHY'])

pp giphy.gifs.search('tardis')
# => {"data"=>
#  #<TLAW::DataTable[type, id, slug, url, bitly_gif_url, bitly_url, embed_url, username, source, rating, content_url, source_tld, source_post_url, is_indexable, import_datetime, trending_datetime, images.fixed_height_still.url, images.fixed_height_still.width, images.fixed_height_still.height, images.original_still.url, images.original_still.width, images.original_still.height, images.fixed_width.url, images.fixed_width.width, images.fixed_width.height, images.fixed_width.size, images.fixed_width.mp4, images.fixed_width.mp4_size, images.fixed_width.webp, images.fixed_width.webp_size, images.fixed_height_small_still.url, images.fixed_height_small_still.width, images.fixed_height_small_still.height, images.fixed_height_downsampled.url, images.fixed_height_downsampled.width, images.fixed_height_downsampled.height, images.fixed_height_downsampled.size, images.fixed_height_downsampled.webp, images.fixed_height_downsampled.webp_size, images.preview.width, images.preview.height, images.preview.mp4, images.preview.mp4_size, images.fixed_height_small.url, images.fixed_height_small.width, images.fixed_height_small.height, images.fixed_height_small.size, images.fixed_height_small.mp4, images.fixed_height_small.mp4_size, images.fixed_height_small.webp, images.fixed_height_small.webp_size, images.downsized_still.url, images.downsized_still.width, images.downsized_still.height, images.downsized_still.size, images.downsized.url, images.downsized.width, images.downsized.height, images.downsized.size, images.downsized_large.url, images.downsized_large.width, images.downsized_large.height, images.downsized_large.size, images.fixed_width_small_still.url, images.fixed_width_small_still.width, images.fixed_width_small_still.height, images.preview_webp.url, images.preview_webp.width, images.preview_webp.height, images.preview_webp.size, images.fixed_width_still.url, images.fixed_width_still.width, images.fixed_width_still.height, images.fixed_width_small.url, images.fixed_width_small.width, images.fixed_width_small.height, images.fixed_width_small.size, images.fixed_width_small.mp4, images.fixed_width_small.mp4_size, images.fixed_width_small.webp, images.fixed_width_small.webp_size, images.downsized_small.width, images.downsized_small.height, images.downsized_small.mp4, images.downsized_small.mp4_size, images.fixed_width_downsampled.url, images.fixed_width_downsampled.width, images.fixed_width_downsampled.height, images.fixed_width_downsampled.size, images.fixed_width_downsampled.webp, images.fixed_width_downsampled.webp_size, images.downsized_medium.url, images.downsized_medium.width, images.downsized_medium.height, images.downsized_medium.size, images.original.url, images.original.width, images.original.height, images.original.size, images.original.frames, images.original.mp4, images.original.mp4_size, images.original.webp, images.original.webp_size, images.fixed_height.url, images.fixed_height.width, images.fixed_height.height, images.fixed_height.size, images.fixed_height.mp4, images.fixed_height.mp4_size, images.fixed_height.webp, images.fixed_height.webp_size, images.looping.mp4, images.looping.mp4_size, images.original_mp4.width, images.original_mp4.height, images.original_mp4.mp4, images.original_mp4.mp4_size, images.preview_gif.url, images.preview_gif.width, images.preview_gif.height, images.preview_gif.size, user.avatar_url, user.banner_url, user.profile_url, user.username, user.display_name, user.twitter, images.fixed_height_still.size, images.original_still.size, images.fixed_height_small_still.size, images.fixed_width_small_still.size, images.fixed_width_still.size, images.original.hash, images.hd.width, images.hd.height, images.hd.mp4, images.hd.mp4_size, images.480w_still.url, images.480w_still.width, images.480w_still.height, images.480w_still.size] x 25>,
# "pagination.total_count"=>1559,
# "pagination.count"=>25,
# "pagination.offset"=>0,
# "meta.status"=>200,
# "meta.msg"=>"OK",
# "meta.response_id"=>"597d9b7b6b56594f3259f254"}
#

pp giphy.gifs.search('tardis')['data'].first
# =>
# {"type"=>"gif",
#  "id"=>"yp2qzMjcEQVB6",
#  "slug"=>"tardis-doctor-who-deer-yp2qzMjcEQVB6",
#  "url"=>"https://giphy.com/gifs/tardis-doctor-who-deer-yp2qzMjcEQVB6",
#  "bitly_gif_url"=>"http://gph.is/XN3l6K",
#  "bitly_url"=>"http://gph.is/XN3l6K",
#  "embed_url"=>"https://giphy.com/embed/yp2qzMjcEQVB6",
#  "username"=>"",
#  "source"=>"http://doctorwhogifs.tumblr.com/post/38804044036",
#  "rating"=>"y",
#  "content_url"=>"",
#  "source_tld"=>"doctorwhogifs.tumblr.com",
#  "source_post_url"=>"http://doctorwhogifs.tumblr.com/post/38804044036",
#  "is_indexable"=>0,
#  "import_datetime"=>"2013-03-21 05:57:22",
#  "trending_datetime"=>"1970-01-01 00:00:00",
#  "images.fixed_height_still.url"=>
#   "https://media0.giphy.com/media/yp2qzMjcEQVB6/200_s.gif",
#  "images.fixed_height_still.width"=>346,
#  "images.fixed_height_still.height"=>200,
#  "images.original_still.url"=>
#   "https://media2.giphy.com/media/yp2qzMjcEQVB6/giphy_s.gif",
#  "images.original_still.width"=>360,
#  "images.original_still.height"=>208,
#  "images.fixed_width.url"=>
#   "https://media1.giphy.com/media/yp2qzMjcEQVB6/200w.gif",
#  "images.fixed_width.width"=>200,
#  "images.fixed_width.height"=>116,
#  "images.fixed_width.size"=>37396,
#  "images.fixed_width.mp4"=>
#   "https://media2.giphy.com/media/yp2qzMjcEQVB6/200w.mp4",
#  "images.fixed_width.mp4_size"=>13349,
#  "images.fixed_width.webp"=>
#   "https://media2.giphy.com/media/yp2qzMjcEQVB6/200w.webp",
#  "images.fixed_width.webp_size"=>61238,
#  ...and so on, there are several types of images

# Inspectability:

TLAW::Examples::Giphy
# => #<TLAW::Examples::Giphy: call-sequence: TLAW::Examples::Giphy.new(api_key:, lang: nil); namespaces: gifs, stickers; docs: .describe>

giphy
# => #<TLAW::Examples::Giphy.new(api_key: nil, lang: nil) namespaces: gifs, stickers; docs: .describe>

giphy.describe
# => TLAW::Examples::Giphy.new(api_key: nil, lang: nil)
#  Wrapper for [Giphy](https://giphy.com/) GIF hosting service API.
#
#  Docs: https://developers.giphy.com/docs/
#
#  @param api_key For development, create it at your [dashboard](https://developers.giphy.com/dashboard/?create=true).
#    Note that you'll need to request different key for production use.
#  @param lang 2-letter ISO 639-1 language code.
#    [Full list of supported languages](https://developers.giphy.com/docs/)
#
#  Namespaces:
#
#  .gifs()
#    Fetch GIPHY GIFs.
#
#  .stickers()
#    Fetch GIPHY stickers (GIFs with transparent background).

giphy.namespaces[:gifs].describe
# => .gifs()
#  Fetch GIPHY GIFs.
#
#  Endpoints:
#
#  .search(query, limit: nil, offset: nil, rating: nil)
#    Search all GIFs by word or phrase.
#
#  .trending(limit: nil, rating: nil)
#    Fetch GIFs currently trending online. Hand curated by the GIPHY editorial team.
#
#  .translate(phrase)
#    Translates phrase to GIFs "vocabulary".
#
#  .random(tag: nil, rating: nil)
#    Returns a random GIF, optionally limited by tag.
#
#  .[](id)
#    One GIF by unique id.
#
#  .multiple(ids)
#    Sevaral GIFs by unique ids.
