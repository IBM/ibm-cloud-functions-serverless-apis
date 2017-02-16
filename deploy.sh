#!/bin/bash
#
# Copyright 2016 IBM Corp. All Rights Reserved.
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

# Color vars to be used in shell script output
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Load configuration variables
source local.env

# Capture the namespace where actions will be created
WSK='wsk'
CURRENT_NAMESPACE=`$WSK property get --namespace | sed -n -e 's/^whisk namespace//p' | tr -d '\t '`
echo "Current namespace is $CURRENT_NAMESPACE."

function usage() {
  echo -e "${YELLOW}Usage: $0 [--install,--uninstall,--env]${NC}"
}

function install() {
  echo -e "${YELLOW}Installing OpenWhisk actions, triggers, and rules for check-deposit..."

  echo "Binding package"
  wsk package bind /whisk.system/cloudant "$CLOUDANT_INSTANCE" \
  --param username "$CLOUDANT_USER" \
  --param password "$CLOUDANT_PASS" \
  --param host "$CLOUDANT_USER.cloudant.com" \
  --param dbname "$CLOUDANT_DATABASE"

  echo "Creating actions"
  wsk action create transformDataForWrite actions/transformDataForWrite.js 

  wsk action create --sequence createDocumentSequence \
    transformDataForWrite,/$CURRENT_NAMESPACE/$CLOUDANT_INSTANCE/create-document
  wsk action create --sequence updateDocumentSequence \
    transformDataForWrite,/$CURRENT_NAMESPACE/$CLOUDANT_INSTANCE/update-document

  echo "Creating API actions"
  wsk api-experimental create -n "Cats API" /example /cats get /$CURRENT_NAMESPACE/$CLOUDANT_INSTANCE/read-document
  wsk api-experimental create /example /cats delete /$CURRENT_NAMESPACE/$CLOUDANT_INSTANCE/delete-document

  wsk api-experimental create /example /cats put updateDocumentSequence
  wsk api-experimental create /example /cats post createDocumentSequence

  echo -e "${GREEN}Install Complete${NC}"
}

function uninstall() {
  echo -e "${RED}Uninstalling..."

  echo "Removing API actions..."
  wsk api-experimental delete /example

  echo "Removing actions..."
  wsk action delete createDocumentSequence
  wsk action delete updateDocumentSequence
  wsk action delete transformDataForWrite

  echo "Removing packages..."
  $WSK package delete "$CLOUDANT_INSTANCE"

  echo -e "${GREEN}Uninstall Complete${NC}"
}

function showenv() {
  echo -e "${YELLOW}"
  echo -e "${NC}"
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
