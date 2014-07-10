require 'goodreads'

client = Goodreads::Client.new(
  :api_key => ENV['GOODREADS_KEY'],
  :api_secret => ENV['GOODREADS_SECRET']
)

$shelf = client.shelf('17714914', 'read', per_page: 200, sort: 'date_read')

$books = nil

def recent_books_html(count = 500)
  html = ''
  $books ||= $shelf.books
  (0..(count.to_i - 1)).each do |i|
    if $books[i]
      html = html + book_to_html(
        {
          image_url: $books[i]['book']['image_url'],
          link: $books[i]['book']['link'],
        }
      )
    end
  end
  html
end

def book_to_html(data)
  "<a href='#{data[:link]}'><img src='#{data[:image_url]}' /></a>"
end
