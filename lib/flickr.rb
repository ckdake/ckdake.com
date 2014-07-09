require 'flickraw'

FlickRaw.api_key=ENV['FLICKR_KEY']
FlickRaw.shared_secret=ENV['FLICKR_SECRET']
flickr.access_token=ENV['FLICKR_ACCESS_TOKEN']
flickr.access_secret=ENV['FLICKR_ACCESS_SECRET']

# token = flickr.get_request_token
# auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')
#
# puts "Open this url in your process to complete the authication process : #{auth_url}"
# puts "Copy here the number given when you complete the process."
# verify = gets.strip
#
# begin
#   flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
#   login = flickr.test.login
#   puts "You are now authenticated as #{login.username} with token #{flickr.access_token} and secret #{flickr.access_secret}"
# rescue FlickRaw::FailedResponse => e
#   puts "Authentication failed : #{e.msg}"
# end

def recent_flickr_sets_html
  html = ''
  photosets = flickr.photosets.getList
  (0..19).each do |i|
    if photosets[i]['visibility_can_see_set'] == 1
      html = html + flickr_set_to_html(
        {
          title: photosets[i]['title'],
          id: photosets[i]['id'],
          primary: photosets[i]['primary'],
          secret: photosets[i]['secret'],
          server: photosets[i]['server'],
          farm: photosets[i]['farm'],
        }
      )
    end
  end
  html
end

def flickr_set_to_html(set)
  "<a href='https://www.flickr.com/photos/ckdake/sets/#{set[:id]}'><img src='https://farm#{set[:farm]}.staticflickr.com/#{set[:server]}/#{set[:primary]}_#{set[:secret]}_q.jpg' /></a>"
end
