# OpenWhisk 101 - OpenWhisk and Serverless APIs
This project provides sample code for creating your serverless REST APIs with Apache OpenWhisk on IBM Bluemix. It should take no more than 10 minutes to get up and running. Once you complete this sample application, you can move on to more complex serverless application use cases, such as those named _OpenWhisk 201_ or tagged as [_openwhisk-use-cases_](https://github.com/search?q=topic%3Aopenwhisk-use-cases+org%3AIBM&type=Repositories).

# Overview of the HTTP REST API
The sample demonstrates how to build a simple CRUD (create, read, update, delete) interface for working with an entity that represents a cat.

HTTP endpoints for each call - corresponding to the `POST`, `GET`, `PUT`, and `DELETE` HTTP methods - are mapped to OpenWhisk actions that modify the state in a MySQL database.

# Installation
Setting up this sample involves configuration of OpenWhisk and MySQL on IBM Bluemix. [If you haven't already signed up for Bluemix and configured OpenWhisk, review those steps first](docs/OPENWHISK.md).

### Set up MySQL
Create a MySQL instance. You can create one on the Bluemix console, or connect to your own instance. You will need to configure this example with host, user, password and database name.

To create a MySQL instance on bluemix, log into the Bluemix console, go to catalog, and provision a ClearDB MySQL database. Log into the ClearDB dashboard, and select the default database created for you. Grab the user, password and host information under "Endpoint Information".

Copy `template.local.env` to a new file named `local.env` and update the `MYSQL_HOST`, `MYSQL_USERNAME`, `MYSQL_PASSWORD` and `MYSQL_DATABASE` values to reflect the name of the MySQL database instance you created.

### Create OpenWhisk actions to modify cat data
Create the custom actions to manage cat data. We will create four actions, one for each method (POST, PUT, GET, and DELETE) of our API.

The code for the actions is located in `/actions`. Let's create the POST action first.

The javascript function for the POST action is located at `/actions/cat-post-action/index.js`. This function depends on a node package: `mysql`. Install the node packages using `npm install`, and create an archive that includes your application and your node dependencies.

```
  cd actions/cat-post-action
  npm install
  zip -rq action.zip *
``` 
Once you have an archive, you can use the OpenWhisk CLI to create an action.
```
  wsk action create cat-post --kind nodejs:6 action.zip \
  --param "MYSQL_HOST" $MYSQL_HOST \
  --param "MYSQL_USER" $MYSQL_USER \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE
```

There are a [number of packages available](https://github.com/openwhisk/openwhisk/blob/master/docs/reference.md?cm_mc_uid=33591682128714865890263&cm_mc_sid_50200000=1487347815#javascript-runtime-environments) by default in the OpenWhisk runtime environment. For packages that are not included by default, we can upload them in a zip file when we create the action. If your application requires no additional packages, you can create an action by linking directly to your `js` file. No need to create and upload an archive. More information in the [getting started docs](https://console.ng.bluemix.net/docs/openwhisk/openwhisk_actions.html#openwhisk_js_packaged_action).

Notice that the command above passes in parameters needed to connect to your MySQL database. Specifying values here will allow these to apply each time you call your action, instead of having to pass them in each time.

Repeat the above steps for PUT, GET, and DELETE.

### Create REST API endpoints
Now that we have our actions, we can create REST endpoints to attach to those actions. Create four endpoints using the following commands. This will map an resource endpoint (`/cats`) to the `GET`, `DELETE`, `PUT`, and `POST` HTTP methods and associate it with the OpenWhisk actions you just created.

```bash

wsk api-experimental create -n "Cats API" /v1 /cats post cat-post
wsk api-experimental create /v1 /cats put cat-put
wsk api-experimental create /v1 /cats get cat-get
wsk api-experimental create /v1 /cats delete cat-delete
```
### Use the `deploy.sh` script to automate the steps above
The commands above exist in a convenience script that reads the environment variables out of `local.env` and injects them where needed.

Change to the root directory, and install the app using `deploy.sh`.

> **Note**: `deploy.sh` will be replaced with the [`wskdeploy`](https://github.com/openwhisk/openwhisk-wskdeploy) tool in the future. `wskdeploy` uses a manifest to create the triggers, actions, and rules that power the sample.

```bash
./deploy.sh --install
```

## Testing
Now that the endpoints have been created, let's invoke them. You can use  `cat-post.sh`, `cat-get.sh`, `cat-put.sh`, `cat-delete.sh` helper scripts to create, get, update and delete cats respectively.

But first, set the `CAT_API_URL` environment variable to the endpoint matching the "Cats API" URL from `wsk api-experimental list` command.
```bash
export CAT_API_URL=[url]
./cat-post.sh [name of cat] [color of cat]
./cat-get.sh [id]
./cat-put.sh [id] [name of cat] [color of cat]
./cat-delete.sh [id]
```

## Troubleshooting
The first place to check for errors is the OpenWhisk activation log. You can view it by tailing the log on the command line with `wsk activation poll` or you can view the [monitoring console on Bluemix](https://console.ng.bluemix.net/openwhisk/dashboard).

## Cleaning up
To remove all the API mappings and delete the actions, you can use `./deploy.sh --uninstall` or perform the deletions manually.

```bash
wsk api-experimental delete /v1

wsk action delete create-document-sequence
wsk action delete update-document-sequence
wsk action delete transform-data-for-write

wsk package delete "$CLOUDANT_INSTANCE"
```

# Credits
Created by @jzaccone and @krook

# License
Licensed under the [Apache 2.0 license](LICENSE.txt).
