#!/bin/bash

curl -X POST -H "Content-Type: application/json" http://10.0.40.43:8080/v2/apps -d@inky.json
