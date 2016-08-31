# All files in the 'lib' directory will be loaded
# before nanoc starts compiling.
include Nanoc::Helpers::Blogging
include Nanoc::Helpers::Tagging
include Nanoc::Helpers::Rendering
include Nanoc::Helpers::LinkTo
include Nanoc::Helpers::XMLSitemap

def previous_link
  prev = sorted_articles.index(@item) + 1
  prev_article = sorted_articles[prev]
  if prev_article.nil?
    ''
  else
    title = prev_article[:title]
    html = "&larr; Previous"
    link_to(html, prev_article.reps[:default], :class => "previous", :title => title)
  end
end

def next_link
  nxt = sorted_articles.index(@item) - 1
  if nxt < 0
    ''
  else
    post = sorted_articles[nxt]
    title = post[:title]
    html = "Next &rarr;"
    link_to(html, post.reps[:default], :class => "next", :title => title)
  end
end
