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

  echo "Installing POST Cat Action"
  cd actions/cat-post-action
  npm install
  zip -rq action.zip *
  wsk action create cat-post --kind nodejs:6 action.zip \
  --param "MYSQL_HOST" $MYSQL_HOST \
  --param "MYSQL_USER" $MYSQL_USER \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE
  wsk api-experimental create -n "Cats API" /v1 /cats post cat-post
  cd ../..

  echo "Installing PUT Cat Action"
  cd actions/cat-put-action
  npm install
  zip -rq action.zip *
  wsk action create cat-put --kind nodejs:6 action.zip \
  --param "MYSQL_HOST" $MYSQL_HOST \
  --param "MYSQL_USER" $MYSQL_USER \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE
  wsk api-experimental create /v1 /cats put cat-put
  cd ../..

  echo "Installing GET Cat Action"
  cd actions/cat-get-action
  npm install
  zip -rq action.zip *
  wsk action create cat-get --kind nodejs:6 action.zip \
  --param "MYSQL_HOST" $MYSQL_HOST \
  --param "MYSQL_USER" $MYSQL_USER \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE
  wsk api-experimental create /v1 /cats get cat-get
  cd ../..

  echo "Installing DELETE Cat Action"
  cd actions/cat-delete-action
  npm install
  zip -rq action.zip *
  wsk action create cat-delete --kind nodejs:6 action.zip \
  --param "MYSQL_HOST" $MYSQL_HOST \
  --param "MYSQL_USER" $MYSQL_USER \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE
  wsk api-experimental create /v1 /cats delete cat-delete
  cd ../..


  echo -e "Install Complete"
}

function uninstall() {
  echo -e "Uninstalling..."

  echo "Removing API actions..."
  wsk api-experimental delete /v1

  echo "Removing actions..."
  wsk action delete cat-post
  wsk action delete cat-put
  wsk action delete cat-get
  wsk action delete cat-delete

  echo -e "Uninstall Complete"
}

function showenv() {
  echo -e MYSQL_HOST="$MYSQL_HOST"
  echo -e MYSQL_USER="$MYSQL_USER"
  echo -e MYSQL_PASSWORD="$MYSQL_PASSWORD"
  echo -e MYSQL_DATABASE="$MYSQL_DATABASE"
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
