require 'vacuum'
require 'digest/md5'

# API is throttled to 1 per second :(
# TODO: spreadsheet of Year, ASIN from Goodreads

$req = Vacuum.new(
  access_key: ENV['AWS_ACCSS_KEY_ID'],
  secret_key: ENV['AWS_SECRET_ACCESS_KEY'],
  partner_tag: 'ckdake-20'
)

def amazon_book_to_html(params)
  url = params[:link]
  image = params[:image_url]

  response = cache_fetch Digest::MD5.hexdigest(params.to_s) do
    sleep 1

    params = {
      'SearchIndex' => 'Books',
      'Author' => params[:author],
      'Title' => params[:title],
      'ResponseGroup' => 'ItemAttributes,Images',
    }

    $req.item_search(query: params).to_h
  end

  if (response['ItemSearchResponse'] &&
      response['ItemSearchResponse']['Items'] &&
      response['ItemSearchResponse']['Items']['Item'])

    if (response['ItemSearchResponse']['Items']['Item'].class == Array)
      url = response['ItemSearchResponse']['Items']['Item'][0]['DetailPageURL']
      if (response['ItemSearchResponse']['Items']['Item'][0]['ImageSets'])
        if (response['ItemSearchResponse']['Items']['Item'][0]['ImageSets']['ImageSet'].class == Array)
          image = response['ItemSearchResponse']['Items']['Item'][0]['ImageSets']['ImageSet'][0]['MediumImage']['URL']
        else
          image = response['ItemSearchResponse']['Items']['Item'][0]['ImageSets']['ImageSet']['MediumImage']['URL']
        end
      end
    else
      url = response['ItemSearchResponse']['Items']['Item']['DetailPageURL']
      if (response['ItemSearchResponse']['Items']['Item']['ImageSets'])
        if (response['ItemSearchResponse']['Items']['Item']['ImageSets']['ImageSet'].class == Array)
          image = response['ItemSearchResponse']['Items']['Item']['ImageSets']['ImageSet'][0]['MediumImage']['URL']
        else
          image = response['ItemSearchResponse']['Items']['Item']['ImageSets']['ImageSet']['MediumImage']['URL']
        end
      end
    end
  end

  "<a href='#{url}'><img src='#{image}' /></a>"
end
