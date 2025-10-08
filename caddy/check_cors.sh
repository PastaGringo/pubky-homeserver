#!/bin/bash

URL="https://httprelay.pubky.fractalized.net/link"
ORIGIN="https://app.pubky.fractalized.net"

echo "Sending OPTIONS preflight request to $URL with Origin $ORIGIN"
echo "---------------------------------------------------------"

curl -i -X OPTIONS \
  -H "Origin: $ORIGIN" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: X-Requested-With" \
  $URL