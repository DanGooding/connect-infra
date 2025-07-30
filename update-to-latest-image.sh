#!/bin/bash

set -euo pipefail

REV=$(./latest-image.sh)

cat >revisions.auto.tfvars <<EOF
// this file was populated by $0
api_service_container_image_tag    = "$REV"
static_service_container_image_tag = "$REV"
EOF

echo updated configured images to $REV, now run terraform apply
