#!/bin/bash
set -e
set -x

curl -X PUT http://localhost:8081/api/v1/buildjobs/create \
    -H 'Content-Type: application/json' \
    -d '{"reference": "someRef", "target": "someTarget"}'