require_relative 'cache'
require 'vimeo'

$videos = nil

def update_videos
  $videos ||= cache_fetch 'vimeo-videos' do
    Vimeo::Simple::User.videos("ckdake").to_a
  end
end

def recent_vimeo_videos_embed_html(count)
  html = ''
  update_videos
  (0..(count.to_i - 1)).each do |i|
    html = html + vimeo_video_to_embed_html(
      {
        id: $videos[i]['id'],
        width: $videos[i]['width'],
        height: $videos[i]['height']
      }
    )
  end
  html
end

def recent_vimeo_videos_link_html(count)
  html = ''
  update_videos
  (0..(count.to_i - 1)).each do |i|
    html = html + vimeo_video_to_link_html(
      {
        title: $videos[i]['title'],
        thumbnail: $videos[i]['thumbnail_medium'],
        url: $videos[i]['url']
      }
    )
  end
  html
end

def vimeo_video_to_link_html(info)
  "<div><a href='#{info[:url]}'><img src='#{info[:thumbnail]}'><br />#{info[:title]}</div>"
end

def vimeo_video_to_embed_html(info)
  "<iframe src='//player.vimeo.com/video/#{info[:id]}' width='#{info[:width].to_i/4}' height='#{info[:height].to_i/4}' frameborder='0' webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>"
end
