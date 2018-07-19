#!/bin/bash
#
# Copyright 2017-2018 IBM Corp. All Rights Reserved.
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

  # Exit if any command fails
  set -e

  echo -e "Installing OpenWhisk actions, triggers, and rules for openwhisk-serverless-apis..."

  echo -e "Setting Bluemix credentials and logging in to provision API Gateway"

  # Edit these to match your Bluemix credentials (needed to provision the API Gateway)
  bx login \
    --u $IBM_CLOUD_USERNAME \
    --p $IBM_CLOUD_PASSWORD \
    --o $IBM_CLOUD_USERNAME \
    --s $IBM_CLOUD_NAMESPACE

  echo -e "\n"

  echo "Creating a package (here used as a namespace for shared environment variables)"
  bx wsk package create cat \
    --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
    --param "MYSQL_PORT" $MYSQL_PORT \
    --param "MYSQL_USERNAME" $MYSQL_USERNAME \
    --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
    --param "MYSQL_DATABASE" $MYSQL_DATABASE

  echo "Installing POST Cat Action"
  cd actions/cat-post-action
  npm install
  zip -rq action.zip *
  bx wsk action create cat/cat-post \
    --kind nodejs:6 action.zip \
    --web true
  bx wsk api create -n "Cats API" /v1 /cat POST cat/cat-post
  cd ../..

  echo "Installing PUT Cat Action"
  cd actions/cat-put-action
  npm install
  zip -rq action.zip *
  bx wsk action create cat/cat-put \
    --kind nodejs:6 action.zip \
    --web true
  bx wsk api create /v1 /cat PUT cat/cat-put
  cd ../..

  echo "Installing GET Cat Action"
  cd actions/cat-get-action
  npm install
  zip -rq action.zip *
  bx wsk action create cat/cat-get \
    --kind nodejs:6 action.zip \
    --web true
  bx wsk api create /v1 /cat GET cat/cat-get
  cd ../..

  echo "Installing DELETE Cat Action"
  cd actions/cat-delete-action
  npm install
  zip -rq action.zip *
  bx wsk action create cat/cat-delete \
    --kind nodejs:6 action.zip \
    --web true
  bx wsk api create /v1 /cat DELETE cat/cat-delete
  cd ../..

  echo -e "Install Complete"
}

function uninstall() {
  echo -e "Uninstalling..."

  echo "Removing API actions..."
  bx wsk api delete /v1

  echo "Removing actions..."
  bx wsk action delete cat/cat-post
  bx wsk action delete cat/cat-put
  bx wsk action delete cat/cat-get
  bx wsk action delete cat/cat-delete

  echo "Removing package..."
  bx wsk package delete cat

  echo -e "Uninstall Complete"
}

function showenv() {
  echo -e MYSQL_HOSTNAME="$MYSQL_HOSTNAME"
  echo -e MYSQL_USERNAME="$MYSQL_USERNAME"
  echo -e MYSQL_PASSWORD="$MYSQL_PASSWORD"
  echo -e MYSQL_DATABASE="$MYSQL_DATABASE"
  echo -e MYSQL_PORT="$MYSQL_PORT"
  echo -e IBM_CLOUD_USERNAME="$IBM_CLOUD_USERNAME"
  echo -e IBM_CLOUD_PASSWORD="$IBM_CLOUD_PASSWORD"
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
