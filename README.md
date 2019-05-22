# Serverless APIs with IBM Cloud Functions (powered by Apache OpenWhisk)

*Read this in other languages: [한국어](README-ko.md), [日本語](README-ja.md), [繁體中文](README-zhTW.md).*

This project shows how serverless, event-driven architectures can execute code that scales automatically in response to demand from HTTP REST API calls. No resources are consumed until the API endpoints are called. When they are called, resources are provisioned to exactly match the current load needed by each HTTP method independently.

It shows four IBM Cloud Functions (powered by Apache OpenWhisk) actions (written in JavaScript) that write and read data in a MySQL database. This demonstrates how actions can work with supporting data services and execute logic in response to HTTP requests.

One action is mapped to HTTP POST requests. It inserts the supplied cat name and color parameters into the database. A second action is mapped to PUT requests to update those fields for an existing cat. A third action is mapped to GET requests that return specific cat data. A fourth action deletes a given cat data.

The Node.js runtime on the IBM Cloud provides a built-in whitelist of npm modules. This demo also highlights how additional Node.js dependencies – such as the MySQL client – can be packaged in a ZIP file with custom actions to provide a high level of extensibility.

![Sample Architecture](docs/arch_buildserverless.png)

## Included components

- IBM Cloud Functions (powered by Apache OpenWhisk)
- ClearDB or Compose (MySQL)

## Prerequisite

You should have a basic understanding of the OpenWhisk programming model. If not, [try the action, trigger, and rule demo first](https://github.com/IBM/openwhisk-action-trigger-rule).

Also, you'll need an IBM Cloud account and the latest [OpenWhisk command line tool (`ibmcloud fn`) installed and on your PATH](https://github.com/IBM/openwhisk-action-trigger-rule/blob/master/docs/OPENWHISK.md).

As an alternative to this end-to-end example, you might also consider the more [basic "building block" version](https://github.com/IBM/openwhisk-rest-api-trigger) of this sample.

## Steps

1. [Provision MySQL](#1-provision-mysql)
2. [Create OpenWhisk actions and mappings](#2-create-openwhisk-actions-and-mappings)
3. [Test API endpoints](#3-test-api-endpoints)
4. [Delete actions and mappings](#4-delete-actions-and-mappings)
5. [Recreate deployment manually](#5-recreate-deployment-manually)

## 1. Provision MySQL

Log into the IBM Cloud and provision a [ClearDB](https://console.ng.bluemix.net/catalog/services/cleardb-mysql-database/) or a [Compose for MySQL](https://console.ng.bluemix.net/catalog/services/compose-for-mysql/) database instance. ClearDB has a free tier for simple testing, while Compose has tiers for larger workloads.

- For [ClearDB](https://console.ng.bluemix.net/catalog/services/cleardb-mysql-database/), log into the ClearDB dashboard, and select the default database created for you. Get the user, password and host information under "Endpoint Information".

- For [Compose](https://console.ng.bluemix.net/catalog/services/compose-for-mysql/), get the information from the `Service Credentials` tab in the IBM Cloud console.

Copy `template.local.env` to a new file named `local.env` and update the `MYSQL_HOSTNAME`, `MYSQL_USERNAME`, `MYSQL_PASSWORD` and `MYSQL_DATABASE` for your MySQL instance.

## 2. Create OpenWhisk actions and mappings

`deploy.sh` is a convenience script reads the environment variables from `local.env` and creates the OpenWhisk actions and API mappings on your behalf. Later you will run these commands yourself.

```bash
./deploy.sh --install
```

> **Note**: If you see any error messages, refer to the [Troubleshooting](#troubleshooting) section below. You can also explore [Alternative deployment methods](#alternative-deployment-methods).

## 3. Test API endpoints

There are four helper scripts that simulate HTTP API clients to create, get, update and delete entities against the `/v1/cat` endpoint.

```bash
# POST /v1/cat {"name": "Tarball", "color": "Black"}
client/cat-post.sh Tarball Black

# GET /v1/cat?id=1
client/cat-get.sh 1 # Or whatever integer ID was returned by the command above

# PUT /v1/cat {"id": 1, "name": "Tarball", "color": "Gray"}
client/cat-put.sh 1 Tarball Gray

# DELETE /v1/cat?id=1
client/cat-delete.sh 1
```

## 4. Delete actions and mappings

Use `deploy.sh` again to tear down the OpenWhisk actions and mappings. You will recreate them step-by-step in the next section.

```bash
./deploy.sh --uninstall
```

## 5. Recreate deployment manually

This section provides a deeper look into what the `deploy.sh` script executes so that you understand how to work with OpenWhisk triggers, actions, rules, and packages in more detail.

### 5.1 Create OpenWhisk actions to modify cat data

Create four actions to manage cat data, one for each method (POST, PUT, GET, and DELETE) of our API. The code for the actions is located in `/actions`. Let's start with the action action that creates a cat record first.

> **Note**: There are a [number of built-in packages ](https://github.com/openwhisk/openwhisk/blob/master/docs/reference.md?cm_mc_uid=33591682128714865890263&cm_mc_sid_50200000=1487347815#javascript-runtime-environments) available in the OpenWhisk Node.js runtime environment. If you need additional packages, you can upload them in a ZIP file along with your action file. More information on the single file versus zipped archive approaches is available in the [getting started guide](https://console.ng.bluemix.net/docs/openwhisk/openwhisk_actions.html#openwhisk_js_packaged_action).

#### 5.1.1 The cat package

Because all of the actions rely on the MySQL database service, it's convenient to set the credentials once at the package level. This makes them available to all the actions in the package so we don't need to define them for each action at creation and run time.

```bash
source local.env
ibmcloud fn package create cat \
  --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
  --param "MYSQL_PORT" $MYSQL_PORT \
  --param "MYSQL_USERNAME" $MYSQL_USERNAME \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE
```

#### 5.1.2 The cat create action

The JavaScript code for the POST action is in `/actions/cat-post-action/index.js`. This function depends on the `mysql` client npm package which we need to connect to the database. Install the package using `npm install` (which parses `package.json`) and create a ZIP file that includes both your application and its dependencies.

```bash
cd actions/cat-post-action
npm install
zip -rq action.zip *
```

Next use the OpenWhisk CLI to create an action from `action.zip`.

```bash
# Create
ibmcloud fn action create cat/cat-post \
  --kind nodejs:6 action.zip \
  --web true
```

Then manually invoke the action using the `ibmcloud fn` CLI to test.

```bash
# Test
ibmcloud fn action invoke \
  --blocking \
  --param name Tarball \
  --param color Black \
  cat/cat-post
```

Repeat the steps above to create and test the corresponding GET, PUT, and DELETE actions.

> **Note**: Replace the number 1 in your tests below to reflect the actual id returned from the POST action result above.

#### 5.1.3 The cat read action

```bash
# Create
cd ../../actions/cat-get-action
npm install
zip -rq action.zip *
ibmcloud fn action create cat/cat-get \
  --kind nodejs:6 action.zip \
  --web true

# Test
ibmcloud fn action invoke \
  --blocking \
  --param id 1 \
  cat/cat-get
```

##### 5.1.4 The cat update action

```bash
# Create
cd ../../actions/cat-put-action
npm install
zip -rq action.zip *
ibmcloud fn action create cat/cat-put \
  --kind nodejs:6 action.zip \
  --web true

# Test
ibmcloud fn action invoke \
  --blocking \
  --param name Tarball \
  --param color Gray \
  --param id 1 \
  cat/cat-put

ibmcloud fn action invoke \
  --blocking \
  --param id 1 \
  cat/cat-get
```

#### 5.1.5 The cat delete action

```bash
# Create
cd ../../actions/cat-delete-action
npm install
zip -rq action.zip *
ibmcloud fn action create cat/cat-delete \
  --kind nodejs:6 action.zip \
  --web true

# Test
ibmcloud fn action invoke \
  --blocking \
  --param id 1 \
  cat/cat-delete

ibmcloud fn action invoke \
  --blocking \
  --param id 1 \
  cat/cat-get
```

### 5.2 Create REST API endpoints

Now map a resource endpoint (`/cat`) to the `GET`, `DELETE`, `PUT`, and `POST` HTTP methods, associate them with the corresponding OpenWhisk actions, and use the client scripts to test.

```bash
# Create
ibmcloud fn api create -n "Cats API" /v1 /cat post cat/cat-post
ibmcloud fn api create /v1 /cat put cat/cat-put
ibmcloud fn api create /v1 /cat get cat/cat-get
ibmcloud fn api create /v1 /cat delete cat/cat-delete

# Test

# POST /v1/cat {"name": "Tarball", "color": "Black"}
client/cat-post.sh Tarball Black

# GET /v1/cat?id=1
client/cat-get.sh 1 # Replace 1 with the id returned from the POST action above

# PUT /v1/cat {"id": 1, "name": "Tarball", "color": "Gray"}
client/cat-put.sh 1 Tarball Gray

# DELETE /v1/cat?id=1
client/cat-delete.sh 1
```

### 5.3 Clean up

Remove the API mappings and delete the actions.

```bash
ibmcloud fn api delete /v1
ibmcloud fn action delete cat/cat-post
ibmcloud fn action delete cat/cat-put
ibmcloud fn action delete cat/cat-get
ibmcloud fn action delete cat/cat-delete
ibmcloud fn package delete cat
```

## Troubleshooting

Check for errors first in the OpenWhisk activation log. Tail the log on the command line with `ibmcloud fn activation poll` or drill into details visually with the [monitoring console on the IBM Cloud](https://console.ng.bluemix.net/openwhisk/dashboard).

If the error is not immediately obvious, make sure you have the [latest version of the `ibmcloud fn` CLI installed](https://console.ng.bluemix.net/openwhisk/learn/cli). If it's older than a few weeks, download an update.

```bash
ibmcloud fn property get --cliversion
```

## Alternative deployment methods

`deploy.sh` will be replaced with [`wskdeploy`](https://github.com/openwhisk/openwhisk-wskdeploy) in the future. `wskdeploy` uses a manifest to deploy declared triggers, actions, and rules to OpenWhisk.

You can also use the following button to clone a copy of this repository and deploy to the IBM Cloud as part of a DevOps toolchain. Supply your OpenWhisk and MySQL credentials under the Delivery Pipeline icon, click `Create`, then run the Deploy stage for the Delivery Pipeline.

[![Deploy to the IBM Cloud](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy?repository=https://github.com/IBM/openwhisk-serverless-apis.git)

## License

This code pattern is licensed under the Apache Software License, Version 2.  Separate third party code objects invoked within this code pattern are licensed by their respective providers pursuant to their own separate licenses. Contributions are subject to the [Developer Certificate of Origin, Version 1.1 (DCO)](https://developercertificate.org/) and the [Apache Software License, Version 2](http://www.apache.org/licenses/LICENSE-2.0.txt).

[Apache Software License (ASL) FAQ](http://www.apache.org/foundation/license-faq.html#WhatDoesItMEAN)
