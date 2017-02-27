#!/bin/bash

##############################################################################
# Copyright 2017 IBM Corporation
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

source env.sh

LINK=https://openwhisk.ng.bluemix.net/cli/go/download/linux/amd64/wsk
echo_my "Downloading OpenWhisk CLI from '$LINK'...\n"
curl -O $LINK
chmod u+x wsk

echo_my "Install OpenWhisk CLI into '$OPEN_WHISK_BIN'...\n"
mkdir $OPEN_WHISK_BIN || true # ignore the error if the directory exists
mv wsk $OPEN_WHISK_BIN

echo_my "All done!\n"