#!/bin/bash
set -x
docker build -t nirmata/hello-world:latest .
docker push nirmata/hello-world
