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

import os
import requests
import json
import time
from subprocess import call

CAT_API_URL = os.environ['CAT_API_URL']
print "CAT_API_URL is: " + CAT_API_URL

def main():
	global catID
	global henryURL

	henry = addHenry("Black")

	catID = henry["id"]
	henryURL = CAT_API_URL+"?id=" + str(catID)

	# checkHenry(henry, "Black")
	henry = updateHenry(henry, "Grey")
	checkHenry(henry, "Grey")
	deleteHenry(henry)
	# checkDeadHenry(henry) Spark (free) plan for ClearDB only allows 4 connections

def addHenry(color):
	print("Add Henry, the black cat. (POST)")
	catToAdd = {'name': 'Henry', 'color': color}
	response = requests.post(CAT_API_URL, json=catToAdd)
	result = json.loads(response.text)

	if response.status_code != 201 or not 'id' in result:
	   	print("Failed to add Henry. Response: " + response.text)
	   	exit(1)

	print("success")
	return result

def checkHenry(result, color):
	print("Verify that Henry has been added/updated (GET)")
	response=requests.get(henryURL)
	result = json.loads(response.text)

	if response.status_code != 200 or \
	   not 'id' in result or \
	   result["name"] != "Henry" or \
	   result["color"] != color or \
	   result["id"] != catID:
	   	print("Failed to verify Henry's addition/update. Response: " + response.text)
	   	exit(1)

	print("success")

def updateHenry(result, color):
	print("Oops, Henry isn't black, he's grey! (PUT)")
	catToUpdate = {'name': 'Henry', 'color': color, 'id': str(catID)}
	response = requests.put(CAT_API_URL, json=catToUpdate)
	result = json.loads(response.text)

	if response.status_code != 200:
	   	print("Failed to update Henry: " + response.text)
	   	exit(1)

	print("success")
	return result

def deleteHenry(result):
	print("Henry, the grey cat ran out of lives (DELETE)")
	response=requests.delete(henryURL)
	if response.status_code != 200:
	   	print("Failed to delete Henry. Response: " + response.text)
	   	exit(1)

	print("success")

# def checkDeadHenry(result):
# 	print("Verify that Henry is really dead (GET)")
# 	response=requests.get(henryURL)
# 	result = json.loads(response.text)
# 	if ('name' in result):
# 	   	print("Failed to verify Henry is really dead. Response: " + response.text)
# 	   	exit(1)

# 	print("success")

main()
