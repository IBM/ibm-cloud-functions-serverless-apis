[![Build Status](https://travis-ci.org/IBM/openwhisk-serverless-apis.svg?branch=master)](https://travis-ci.org/IBM/openwhisk-serverless-apis)

# OpenWhisk 101 - OpenWhisk and Serverless APIs
Learn how to [create serverless REST APIs](https://github.com/IBM/openwhisk-serverless-apis/wiki) with Apache OpenWhisk on IBM Bluemix. This tutorial will take less than 10 minutes to complete.

You should have a basic understanding of the OpenWhisk programming model. If not, [try the action, trigger, and rule demo first](https://github.com/IBM/openwhisk-action-trigger-rule). [You'll also need a Bluemix account and the latest OpenWhisk command line tool](docs/OPENWHISK.md).

When complete, move on to more complex serverless applications, such as those named _OpenWhisk 201_ or tagged as [_openwhisk-use-cases_](https://github.com/search?q=topic%3Aopenwhisk-use-cases+org%3AIBM&type=Repositories).

# OpenWhisk Serverless REST APIs
This example provides a simple CRUD (create, read, update, delete) interface for an entity that represents a cat with an id, name, and color.

REST endpoints for each call - corresponding to the HTTP `POST`, `GET`, `PUT`, and `DELETE` methods - are mapped to autoscaling OpenWhisk actions that modify cat state in a MySQL database.

![High level diagram](docs/serverless-apis.png)

Steps

1. [Provision MySQL](#1-provision-mysql)
2. [Create OpenWhisk actions and mappings](#2-create-openwhisk-actions-and-mappings)
3. [Test API endpoints](#3-test-api-endpoints)
4. [Delete actions and mappings](#4-delete-actions-and-mappings)
5. [Recreate deployment manually](#5-recreate-deployment-manually)

# 1. Provision MySQL
Log into Bluemix and provision a [ClearDB](https://console.ng.bluemix.net/catalog/services/cleardb-mysql-database/) or a [Compose for MySQL](https://console.ng.bluemix.net/catalog/services/compose-for-mysql/) database instance. ClearDB has a free tier for simple testing, while Compose has tiers for larger workloads.

* For [ClearDB](https://console.ng.bluemix.net/catalog/services/cleardb-mysql-database/), log into the ClearDB dashboard, and select the default database created for you. Get the user, password and host information under "Endpoint Information".

* For [Compose](https://console.ng.bluemix.net/catalog/services/compose-for-mysql/), get the information from the "Service Credentials" tab in the Bluemix console.

Copy `template.local.env` to a new file named `local.env` and update the `MYSQL_HOSTNAME`, `MYSQL_USERNAME`, `MYSQL_PASSWORD` and `MYSQL_DATABASE` for your MySQL instance.

# 2. Create OpenWhisk actions and mappings
`deploy.sh` is a convenience script reads the environment variables from `local.env` and creates the OpenWhisk actions and API mappings on your behalf. Later you will run these commands yourself.

```bash
./deploy.sh --install
```
> **Note**: If you see any error messages, refer to the [Troubleshooting](#troubleshooting) section below.

> **Note**: `deploy.sh` will be replaced with [`wskdeploy`](https://github.com/openwhisk/openwhisk-wskdeploy) in the future. `wskdeploy` uses a manifest to deploy declared triggers, actions, and rules to OpenWhisk.

# 3. Test API endpoints
There are four helper scripts that simulate HTTP API clients to create, get, update and delete entities against the `/v1/cat` endpoint.

```bash
client/cat-post.sh [name of cat] [color of cat]
client/cat-get.sh [id] # Returned by cat-post.sh
client/cat-put.sh [id] [name of cat] [color of cat]
client/cat-delete.sh [id]
```

# 4. Delete actions and mappings
Use `deploy.sh` again to tear down the OpenWhisk actions and mappings. You will recreate them step-by-step in the next section.

```bash
./deploy.sh --uninstall
```

# 5. Recreate deployment manually
This section provides a deeper look into what the `deploy.sh` script executes so that you understand how to work with OpenWhisk triggers, actions, rules, and packages in more detail.

## 5.1 Create OpenWhisk actions to modify cat data
Create four actions to manage cat data, one for each method (POST, PUT, GET, and DELETE) of our API. The code for the actions is located in `/actions`. Let's start with the action action that creates a cat record first.

> **Note**: There are a [number of built-in packages ](https://github.com/openwhisk/openwhisk/blob/master/docs/reference.md?cm_mc_uid=33591682128714865890263&cm_mc_sid_50200000=1487347815#javascript-runtime-environments) available in the OpenWhisk Node.js runtime environment. If you need additional packages, you can upload them in a ZIP file along with your action file. More information on the single file versus zipped archive approaches is available in the [getting started guide](https://console.ng.bluemix.net/docs/openwhisk/openwhisk_actions.html#openwhisk_js_packaged_action).

### 5.1.1 The cat create action
The JavaScript code for the POST action is in `/actions/cat-post-action/index.js`. This function depends on the `mysql` client NPM package which we need to connect to the database. Install the package using `npm install` (which parses `package.json`) and create a ZIP file that includes both your application and its dependencies.
```bash
  cd actions/cat-post-action
  npm install
  zip -rq action.zip *
```
Next use the OpenWhisk CLI to create an action from `action.zip`, passing along environment variables loaded from `local.env`.
```bash
source ../../local.env

# Create
wsk action create cat-post --kind nodejs:6 action.zip \
  --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
  --param "MYSQL_USERNAME" $MYSQL_USERNAME \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE
```

> **Note**: The command above passes in parameters needed to connect to your MySQL database at action creation time. This makes them available each time the action is called, instead of having to pass them in each time as runtime parameters.

Then manually invoke the action using the `wsk` CLI to test.

```bash
# Test
wsk action invoke \
  --blocking \
  --param name Henry \
  --param color Black \
  cat-post
```

Repeat the steps above to create and test the corresponding PUT, GET, and DELETE actions.

### 5.1.2 The cat update action
```bash
# Create
cd ../../actions/cat-put-action
npm install
zip -rq action.zip *
wsk action create cat-put --kind nodejs:6 action.zip \
  --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
  --param "MYSQL_USERNAME" $MYSQL_USERNAME \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE

# Test
wsk action invoke \
  --blocking \
  --param name Henry \
  --param color Gray \
  --param id 1 \
  cat-put
```

### 5.1.3 The cat read action
```bash
# Create
cd ../../actions/cat-get-action
npm install
zip -rq action.zip *
wsk action create cat-get --kind nodejs:6 action.zip \
  --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
  --param "MYSQL_USERNAME" $MYSQL_USERNAME \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE

# Test
wsk action invoke \
  --blocking \
  --param id 1 \
  cat-get
```

### 5.1.4 The cat delete action
```bash
# Create
cd ../../actions/cat-delete-action
npm install
zip -rq action.zip *
wsk action create cat-delete --kind nodejs:6 action.zip \
  --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
  --param "MYSQL_USERNAME" $MYSQL_USERNAME \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE

# Test
wsk action invoke \
  --blocking \
  --param id 1 \
  cat-delete
```

## 5.2 Create REST API endpoints
Now map a resource endpoint (`/cat`) to the `GET`, `DELETE`, `PUT`, and `POST` HTTP methods and associate them with the corresponding OpenWhisk actions.

```bash
# Create
wsk api-experimental create -n "Cats API" /v1 /cat post cat-post
wsk api-experimental create /v1 /cat put cat-put
wsk api-experimental create /v1 /cat get cat-get
wsk api-experimental create /v1 /cat delete cat-delete

# Test

# POST /v1/cat {"name": "Tarball", "color": "Black"}
client/cat-post.sh Tarball Black

# GET /v2/cat?id=1
client/cat-get.sh 1

# PUT /v1/cat {"id": 1, "name": "Tarball", "color": "Gray"}
client/cat-put.sh 1 Tarball Gray

# DELETE /v2/cat?id=1
client/cat-delete.sh 1
```

## 5.3 Clean up
Remove the API mappings and delete the actions.

```bash
wsk api-experimental delete /v1
wsk action delete cat-post
wsk action delete cat-put
wsk action delete cat-get
wsk action delete cat-delete
```

# Troubleshooting
Check for errors first in the OpenWhisk activation log. Tail the log on the command line with `wsk activation poll` or drill into details visually with the [monitoring console on Bluemix](https://console.ng.bluemix.net/openwhisk/dashboard).

If the error is not immediately obvious, make sure you have the [latest version of the `wsk` CLI installed](https://console.ng.bluemix.net/openwhisk/learn/cli). If it's older than a few weeks, download an update.
```bash
wsk property get --cliversion
```

# License
[Apache 2.0](LICENSE.txt)
