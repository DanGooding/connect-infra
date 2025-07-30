#!/bin/bash

set -euo pipefail

# get rev40 tag of latest uploaded image
latest-prod-image-tag() {
  aws ecr describe-images \
    --no-paginate \
    --repository-name $1 \
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
  aws ecr describe-images \
    --no-paginate \
    --repository-name $1 \
  | jq --exit-status -f <(cat <<EOF
  .imageDetails
  | map(select(.imageTags | select(. != null) | .[] == "$2"))
  | .[0] != null
EOF
  ) >/dev/null
}

REPOS=(connect-api-server connect-static-server)

# find the latest from an arbitrary repo, then assert both have it.
# getting the latest from the intersection of both is a bit awkward
# since we'd have to intersect and then lookup timestamps again.
LATEST_PROD_TAG=$(latest-prod-image-tag ${REPOS[0]})

for REPO in ${REPOS[@]}; do
  if ! image-exists $REPO $LATEST_PROD_TAG; then
    echo image $LATEST_PROD_TAG missing from $REPO >&2
    exit 1
  fi
done

echo $LATEST_PROD_TAG
