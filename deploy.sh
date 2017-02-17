#!/bin/bash
#
# Copyright 2017 IBM Corp. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the “License”);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Load configuration variables
source local.env

function usage() {
  echo -e "Usage: $0 [--install,--uninstall,--env]"
}

function install() {
  echo -e "Installing OpenWhisk actions, triggers, and rules for openwhisk-serverless-apis..."

  echo "Binding Cloudant package"
  wsk package bind /whisk.system/cloudant "$CLOUDANT_INSTANCE" \
    --param username "$CLOUDANT_USERNAME" \
    --param password "$CLOUDANT_PASSWORD" \
    --param host "$CLOUDANT_USERNAME.cloudant.com" \
    --param dbname "$CLOUDANT_DATABASE"

  echo "Creating actions"
  wsk action create transform-data-for-write actions/transform-data-for-write.js

  wsk action create --sequence create-document-sequence \
    transform-data-for-write,/_/$CLOUDANT_INSTANCE/create-document

  wsk action create --sequence update-document-sequence \
    transform-data-for-write,/_/$CLOUDANT_INSTANCE/update-document

  echo "Creating REST API actions"
  wsk api-experimental create -n "Cats API" /v1 /cats get /_/$CLOUDANT_INSTANCE/read-document
  wsk api-experimental create /v1 /cats delete /_/$CLOUDANT_INSTANCE/delete-document
  wsk api-experimental create /v1 /cats put update-document-sequence
  wsk api-experimental create /v1 /cats post create-document-sequence

  echo -e "Install Complete"
}

function uninstall() {
  echo -e "Uninstalling..."

  echo "Removing API actions..."
  wsk api-experimental delete /v1

  echo "Removing actions..."
  wsk action delete create-document-sequence
  wsk action delete update-document-sequence
  wsk action delete transform-data-for-write

  echo "Removing packages..."
  wsk package delete "$CLOUDANT_INSTANCE"

  echo -e "Uninstall Complete"
}

function showenv() {
  echo -e CLOUDANT_INSTANCE="$CLOUDANT_INSTANCE"
  echo -e CLOUDANT_USERNAME="$CLOUDANT_USERNAME"
  echo -e CLOUDANT_PASSWORD="$CLOUDANT_PASSWORD"
  echo -e CLOUDANT_DATABASE="$CLOUDANT_DATABASE"
}

case "$1" in
"--install" )
install
;;
"--uninstall" )
uninstall
;;
"--env" )
showenv
;;
* )
usage
;;
esac
