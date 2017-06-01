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

set -e

# Load configuration variables
source local.env

function usage() {
  echo -e "Usage: $0 [--install,--uninstall,--env]"
}

function install() {
  echo -e "Installing OpenWhisk actions, triggers, and rules for openwhisk-serverless-apis..."

  echo -e "Setting Bluemix credentials and logging in to provision API Gateway"

  # Edit these to match your Bluemix credentials (needed for the API Gateway)
  wsk bluemix login \
    --user $BLUEMIX_USERNAME \
    --password $BLUEMIX_PASSWORD \
    --namespace $BLUEMIX_NAMESPACE

  echo -e "\n"
  echo "Installing POST Cat Action"
  cd actions/cat-post-action
  npm install
  zip -rq action.zip *
  wsk action create cat-post \
    --kind nodejs:6 action.zip \
    --web true \
    --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
    --param "MYSQL_USERNAME" $MYSQL_USERNAME \
    --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
    --param "MYSQL_DATABASE" $MYSQL_DATABASE
  wsk api create -n "Cats API" /v1 /cat POST cat-post
  cd ../..

  echo "Installing PUT Cat Action"
  cd actions/cat-put-action
  npm install
  zip -rq action.zip *
  wsk action create cat-put \
    --kind nodejs:6 action.zip \
    --web true \
    --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
    --param "MYSQL_USERNAME" $MYSQL_USERNAME \
    --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
    --param "MYSQL_DATABASE" $MYSQL_DATABASE
  wsk api create /v1 /cat PUT cat-put
  cd ../..

  echo "Installing GET Cat Action"
  cd actions/cat-get-action
  npm install
  zip -rq action.zip *
  wsk action create cat-get \
    --kind nodejs:6 action.zip \
    --web true \
    --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
    --param "MYSQL_USERNAME" $MYSQL_USERNAME \
    --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
    --param "MYSQL_DATABASE" $MYSQL_DATABASE
  wsk api create /v1 /cat GET cat-get
  cd ../..

  echo "Installing DELETE Cat Action"
  cd actions/cat-delete-action
  npm install
  zip -rq action.zip *
  wsk action create cat-delete \
    --kind nodejs:6 action.zip \
    --web true \
    --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
    --param "MYSQL_USERNAME" $MYSQL_USERNAME \
    --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
    --param "MYSQL_DATABASE" $MYSQL_DATABASE
  wsk api create /v1 /cat DELETE cat-delete
  cd ../..

  echo -e "Install Complete"
}

function uninstall() {
  echo -e "Uninstalling..."

  echo "Removing API actions..."
  wsk api delete /v1

  echo "Removing actions..."
  wsk action delete cat-post
  wsk action delete cat-put
  wsk action delete cat-get
  wsk action delete cat-delete

  echo -e "Uninstall Complete"
}

function showenv() {
  echo -e MYSQL_HOSTNAME="$MYSQL_HOSTNAME"
  echo -e MYSQL_USERNAME="$MYSQL_USERNAME"
  echo -e MYSQL_PASSWORD="$MYSQL_PASSWORD"
  echo -e MYSQL_DATABASE="$MYSQL_DATABASE"
  echo -e BLUEMIX_USERNAME="$BLUEMIX_USERNAME"
  echo -e BLUEMIX_PASSWORD="$BLUEMIX_PASSWORD"
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
