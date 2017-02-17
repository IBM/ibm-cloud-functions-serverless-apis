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
  wsk action create transformDataForWrite actions/transformDataForWrite.js

  wsk action create --sequence createDocumentSequence \
    transformDataForWrite,/_/$CLOUDANT_INSTANCE/create-document

  wsk action create --sequence updateDocumentSequence \
    transformDataForWrite,/_/$CLOUDANT_INSTANCE/update-document

  echo "Creating REST API actions"
  wsk api-experimental create -n "Cats API" /example /cats get /_/$CLOUDANT_INSTANCE/read-document
  wsk api-experimental create /example /cats delete /_/$CLOUDANT_INSTANCE/delete-document
  wsk api-experimental create /example /cats put updateDocumentSequence
  wsk api-experimental create /example /cats post createDocumentSequence

  echo -e "Install Complete"
}

function uninstall() {
  echo -e "Uninstalling..."

  echo "Removing API actions..."
  wsk api-experimental delete /example

  echo "Removing actions..."
  wsk action delete createDocumentSequence
  wsk action delete updateDocumentSequence
  wsk action delete transformDataForWrite

  echo "Removing packages..."
  wsk package delete "$CLOUDANT_INSTANCE"

  echo -e "Uninstall Complete"
}

function showenv() {
  echo -e "$CLOUDANT_INSTANCE"
  echo -e "$CLOUDANT_USERNAME"
  echo -e "$CLOUDANT_PASSWORD"
  echo -e "$CLOUDANT_DATABASE"
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
