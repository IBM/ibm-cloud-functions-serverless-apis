#!/bin/bash

##############################################################################
# Copyright 2017-2018 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##############################################################################
set -e

OPEN_WHISK_BIN=/home/ubuntu/bin
LINK=https://openwhisk.ng.bluemix.net/cli/go/download/linux/amd64/wsk

echo "Downloading OpenWhisk CLI from '$LINK'...\n"
curl -O $LINK
chmod u+x wsk
export PATH=$PATH:`pwd`

echo "Configuring CLI from apihost and API key\n"
wsk property set --apihost openwhisk.ng.bluemix.net --auth $OPEN_WHISK_KEY > /dev/null 2>&1

echo "Configure local.env"
touch local.env # Configurations defined in travis-ci console

echo "Deploying wsk actions, etc."
./deploy.sh --install

echo "Find and set Cat API URL"
export CAT_API_URL=`wsk api list | tail -1 | awk '{print $5}'`

echo "Running pythontests"
python3 --version
sudo pip install requests --upgrade
sudo -H pip install 'requests[security]'
python travis-test.py

echo "Uninstalling wsk actions, etc."
./deploy.sh --uninstall
