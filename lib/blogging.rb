def grouped_articles
    sorted_articles.group_by do |a|
      [ a[:created_at].year ]
    end.sort.reverse
end