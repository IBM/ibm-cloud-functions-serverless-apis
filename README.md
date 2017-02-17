# OpenWhisk 101 - OpenWhisk and Serverless APIs
This project provides sample code for creating your serverless REST APIs with Apache OpenWhisk on IBM Bluemix. It should take no more than 10 minutes to get up and running. Once you complete this sample application, you can move on to more complex serverless application use cases, such as those named _OpenWhisk 201_ or tagged as [_openwhisk-use-cases_](https://github.com/search?q=topic%3Aopenwhisk-use-cases+org%3AIBM&type=Repositories).

# Overview of the HTTP REST API
The sample demonstrates how to build a simple CRUD (create, read, update, delete) interface for working with an entity that represents a cat.

HTTP endpoints for each call - corresponding to the `POST`, `GET`, `PUT`, and `DELETE` HTTP methods - are mapped to OpenWhisk actions that modify the state in a Cloudant database.

# Installation
Setting up this sample involves configuration of OpenWhisk and Cloudant on IBM Bluemix. [If you haven't already signed up for Bluemix and configured OpenWhisk, review those steps first](docs/OPENWHISK.md).

### Set up Cloudant
Log into the Bluemix console, provision a Cloudant service instance, and name it `openwhisk-cloudant`. You can reuse an existing instance if you already have one.

Copy `template.local.env` to a new file named `local.env` and update the `CLOUDANT_INSTANCE` value to reflect the name of the Cloudant service instance above.

Then set the `CLOUDANT_USERNAME` and `CLOUDANT_PASSWORD` values based on the service credentials for the service.

Log into the Cloudant web console and create a database, such as `cats`. Set the database name in the `CLOUDANT_DATABASE` variable.

### Bind the Cloudant instance to OpenWhisk
To make Cloudant available to OpenWhisk, we create a "package" along with connection information.

```bash
wsk package bind /whisk.system/cloudant "$CLOUDANT_INSTANCE" \
  --param username "$CLOUDANT_USERNAME" \
  --param password "$CLOUDANT_PASSWORD" \
  --param host "$CLOUDANT_USERNAME.cloudant.com" \
  --param dbname "$CLOUDANT_DATABASE"
```

### Create OpenWhisk actions to modify cat data
Next, create the custom action and reuse Cloudant-specific actions that already exist within the OpenWhisk environment to manage cat data. Actions can also be grouped into a _sequence_ of actions.

This custom `transform-data-for-write` action simply takes supplied parameters and puts them into a format that Cloudant can recognize to insert a new JSON record.
```bash
wsk action create transform-data-for-write actions/transform-data-for-write.js
```

This sequence uses the action above and pairs it in a sequence with the built-in Cloudant `create-document` action for backing our `POST` operation.
```bash
wsk action create --sequence create-document-sequence \
  transform-data-for-write,/_/$CLOUDANT_INSTANCE/create-document
```

This sequence uses the action above and pairs it in a sequence with the Cloudant `update-document` action for backing our `PUT` operation.
```bash
wsk action create --sequence update-document-sequence \
  transform-data-for-write,/_/$CLOUDANT_INSTANCE/update-document
```

We don't have to define actions for our `GET` and `DELETE` operations because they don't require data transformation nor a sequence. We'll specify the Cloudant `read-document` and `delete-document` when we declare the API mapping in the next step.

### Create REST API endpoints
Create four endpoints using the following commands. This will map an resource endpoint (`/cats`) to the `GET`, `DELETE`, `PUT`, and `POST` HTTP methods and associate it with an OpenWhisk action or action sequence.

```bash
wsk api-experimental create -n "Cats API" /v1 /cats get /_/$CLOUDANT_INSTANCE/read-document
wsk api-experimental create /v1 /cats delete /_/$CLOUDANT_INSTANCE/delete-document
wsk api-experimental create /v1 /cats put update-document-sequence
wsk api-experimental create /v1 /cats post create-document-sequence
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
./cat-put.sh [id] [rev] [name of cat] [color of cat]
./cat-delete.sh [id] [rev]
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
