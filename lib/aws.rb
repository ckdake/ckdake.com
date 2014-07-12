require 'vacuum'
require 'pp'

# API is throttled to 1 per second :(
# TODO: spreadsheet of Year, ASIN

$req = Vacuum.new('US', true)
$req.configure(
  aws_access_key_id: ENV['AWS_ACCSS_KEY_ID'],
  aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  associate_tag: 'ckdake-20'
)

def amazon_book_to_html(params)
  sleep 1
  url = params[:link]
  image = params[:image_url]

  params = {
    'SearchIndex' => 'Books',
    'Author' => params[:author],
    'Title' => params[:title],
    'ResponseGroup' => 'ItemAttributes,Images',
  }

  response = $req.item_search(query: params).to_h

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
