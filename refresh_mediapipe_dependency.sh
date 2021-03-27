#!/bin/bash -eu

set -o pipefail

## Refresh MediaPipe dependency


commit=$(ag '(?ms)git_repository\(\s+name = "mediapipe",\s+commit = ' WORKSPACE | tail -n1 | cut -d'"' -f2)
mkdir -p third_party
rm -r third_party/*
curl -#fSL https://github.com/google/mediapipe/archive/"$commit".tar.gz | tar xvz -C third_party/
mv third_party/mediapipe-"$commit"/third_party/* third_party/
rm -r third_party/mediapipe-"$commit"
