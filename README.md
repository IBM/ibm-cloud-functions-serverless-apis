# OpenWhisk 101 - OpenWhisk and Serverless APIs
This project provides sample code for creating serverless REST APIs with Apache OpenWhisk on IBM Bluemix. It should take no more than 10 minutes to get up and running.

This sample assumes you have a basic understanding of the OpenWhisk programming model, which is based on Triggers, Actions, and Rules. If not, you may want to [explore this demo first](https://github.com/IBM/openwhisk-action-trigger-rule).

Serverless platforms like Apache OpenWhisk provide a runtime that scales automatically in response to demand, resulting in a better match between the cost of cloud resources consumed and business value gained.

One of the key use cases for OpenWhisk is to map HTTP REST API calls to business logic functions that create, read, update, and delete data. Instead of pre-provisioning resources in anticipation of demand, these actions are started and destroyed only as needed in response to demand.

Once you complete this sample application, you can move on to more complex serverless application use cases, such as those named _OpenWhisk 201_ or tagged as [_openwhisk-use-cases_](https://github.com/search?q=topic%3Aopenwhisk-use-cases+org%3AIBM&type=Repositories).

# Overview of an HTTP REST API backed by OpenWhisk
The sample demonstrates how to build a simple CRUD (create, read, update, delete) interface for working with an entity that represents a cat that has an id, name, and color.

HTTP endpoints for each call - corresponding to the `POST`, `GET`, `PUT`, and `DELETE` HTTP methods - are mapped to OpenWhisk actions that modify cat state in a MySQL database.

![High level diagram](docs/serverless-apis.png)

The Node.js runtime on Bluemix provides a [built-in whitelist of NPM modules](https://github.com/openwhisk/openwhisk/blob/master/docs/reference.md#javascript-runtime-environments). This demo also highlights how additional Node.js dependencies - such as the MySQL client - can be packaged in a ZIP file with custom actions to provide a high level of extensibility.

# Installation
Setting up this sample involves configuration of OpenWhisk and MySQL on IBM Bluemix. [If you haven't already signed up for Bluemix and configured OpenWhisk, review those steps first](docs/OPENWHISK.md).

### Provision a MySQL database
Create a MySQL instance. You can create one through the Bluemix console, or connect to your own instance. You will need to configure this example with host, user, password and database name.

To create a MySQL instance on bluemix, log into the Bluemix console, go to catalog, and provision a ClearDB MySQL database. Log into the ClearDB dashboard, and select the default database created for you. Grab the user, password and host information under "Endpoint Information".

Copy `template.local.env` to a new file named `local.env` and update the `MYSQL_HOSTNAME`, `MYSQL_USERNAME`, `MYSQL_PASSWORD` and `MYSQL_DATABASE` values to reflect the values for the MySQL database instance you created.

### Create OpenWhisk actions to modify cat data
Next, we create custom actions to manage cat data. We will create four actions, one for each method (POST, PUT, GET, and DELETE) of our API.

> There are a [number of packages available](https://github.com/openwhisk/openwhisk/blob/master/docs/reference.md?cm_mc_uid=33591682128714865890263&cm_mc_sid_50200000=1487347815#javascript-runtime-environments) by default in the OpenWhisk runtime environment. For packages that are not included by default, we can upload them in a ZIP file when we create the action. If your application requires no additional packages, you can create an action by uploading your JavaScript action file directly. No need to create and upload an archive. More information on the two approaches is available in the [getting started documentation](https://console.ng.bluemix.net/docs/openwhisk/openwhisk_actions.html#openwhisk_js_packaged_action).

The code for the actions is located in `/actions`. Let's create the POST action first.

The JavaScript function for the POST action is located at `/actions/cat-post-action/index.js`. This function depends on a Node.js package: `mysql`. Install the Node packages using `npm install` and create an archive that includes your application and your Node dependencies.

```
  cd actions/cat-post-action
  npm install
  zip -rq action.zip *
```
Once you have an archive built, you can use the OpenWhisk CLI to create an action with it, passing along environment variables set by running `source local.env`.
```
  wsk action create cat-post --kind nodejs:6 action.zip \
  --param "MYSQL_HOSTNAME" $MYSQL_HOSTNAME \
  --param "MYSQL_USERNAME" $MYSQL_USERNAME \
  --param "MYSQL_PASSWORD" $MYSQL_PASSWORD \
  --param "MYSQL_DATABASE" $MYSQL_DATABASE
```

Notice that the command above passes in parameters needed to connect to your MySQL database. Specifying values here will allow these to apply each time you call your action, instead of having to pass them in each time.

Repeat the above steps for the corresponding PUT, GET, and DELETE actions.

### Create REST API endpoints
Now that we have our actions, we can create REST endpoints to attach to those actions. Create four endpoints using the following commands. This will map an resource endpoint (`/cats`) to the `GET`, `DELETE`, `PUT`, and `POST` HTTP methods and associate it with the corresponding OpenWhisk action you just created.

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
wsk action delete cat-post
wsk action delete cat-put
wsk action delete cat-get
wsk action delete cat-delete
```

# License
Licensed under the [Apache 2.0 license](LICENSE.txt).
