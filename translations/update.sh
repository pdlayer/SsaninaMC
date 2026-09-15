#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

lupdate -locations absolute ../launcher -ts ./*.ts ./.template.ts
