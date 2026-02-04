Running ckdake.com
==================

1. Open in Codespaces or VS Code
1. Run `bundle install`
1. Use `bundle exec nanoc live` to preview locally
1. Use `bundle exec nanoc compile` for a full build

Deployment
==================

Main is automatically deployed on Netlify.

[![Netlify Status](https://api.netlify.com/api/v1/badges/31305084-0222-492d-b2ae-45676889a599/deploy-status)](https://app.netlify.com/sites/ckdake-com-prod/deploys)


Videos
=================

Add to videos.json appropriately, then:

```bash
source .env
aws s3api list-objects-v2 --bucket ckvideos --query 'Contents[].Key' --output text --endpoint-url https://atl1.digitaloceanspaces.com | \
tr '\t' '\n' | while read -r key; do
  aws s3api put-object-acl --bucket ckvideos --key "$key" --acl public-read --endpoint-url https://atl1.digitaloceanspaces.com
done
```

TODO:
make this perform better for big videos, do some re-encoding?