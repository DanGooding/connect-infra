#!/bin/bash

set -euo pipefail
set -x

# get rev40 tag of latest uploaded image
latest-prod-image-tag() {
  REPO=$1

  aws ecr describe-images \
    --no-paginate \
    --repository-name $REPO \
  | jq --raw-output -f <(cat <<EOF
  .imageDetails
  | sort_by(.imagePushedAt) | reverse 
  | map(.imageTags | select(. != null)) | flatten 
  | map(select(test("^[A-Za-z0-9]{40}$"))) 
  | .[0]
EOF
  )
}

# assert image with this tag exists
image-exists() {
  REPO=$1
  TAG=$2

  aws ecr describe-images \
    --no-paginate \
    --repository-name $REPO \
  | jq -f <(cat <<EOF
  .imageDetails
  | map(select(.imageTags | select(. != null) | .[] == "$TAG"))
  | .[0]
EOF
  )
}

API_SERVER_REPO=connect-api-server
STATIC_SERVER_REPO=connect-static-server

TAG=$(latest-prod-image-tag $API_SERVER_REPO)

image-exists $API_SERVER_REPO $TAG
image-exists $STATIC_SERVER_REPO $TAG

