# OpenWhisk 101 - OpenWhisk and Serverless APIs
This project provides sample code for creating your serverless REST APIs with Apache OpenWhisk on IBM Bluemix. It should take no more than 10 minutes to get up and running. Once you complete this sample application, you can move on to more complex serverless application use cases, such as those named _OpenWhisk 201_ or tagged as [_openwhisk-use-cases_](https://github.com/search?q=topic%3Aopenwhisk-use-cases+org%3AIBM&type=Repositories).

# Overview of HTTP REST API definition
To come.

## Flow of create, read, update, delete calls
1. The developer invokes the PUT API endpoint to create a cat entity with a name, and color.
2. The developer invokes the GET API endpoint to retrieve the new cat data.
3. The developer invokes the PUT API endpoint to update the cat data.
4. The developer invokes the DELETE API endpoint to delete the cat data.

# Installation
Setting up this sample involves configuration of OpenWhisk and Cloudant on IBM Bluemix. [If you haven't already signed up for Bluemix and configured OpenWhisk, review those steps first](docs/OPENWHISK.md).

### Set up Cloudant

Log into the Bluemix console and create a Cloudant instance and name it `openwhisk-cloudant`. You can reuse an existing instance if you already have one.

Copy `template.local.env` to a new file named `local.env` and update the `CLOUDANT_INSTANCE` value to reflect the name of the Cloudant service instance above.

Then set the `CLOUDANT_USERNAME` and `CLOUDANT_PASSWORD` values based on the service credentials for the service.

Log into the Cloudant web console and create a database, such as `cats`. Set the database name in the `CLOUDANT_DATABASE` variable.


## Execute `deploy` to deploy the sample REST API endpoints
Clone this repository to your system,  change to the root directory, and install the app using `deploy.sh`.

> **Note**: `deploy.sh` will be replaced with the [`wskdeploy`](https://github.com/openwhisk/openwhisk-wskdeploy) tool in the future. `wskdeploy` uses a manifest to create the triggers, actions, and rules that power the sample.

```bash
./deploy.sh --install
```

## Test the newly defined API endpoints

Now that the endpoints have been created, let's invoke them. You can use  `postCat.sh`, `getCat.sh`, `putCat.sh`, `deleteCat.sh` helper scripts to create, get, update and delete cats respectively.

But first, set the `CAT_API_URL` environment variable to the endpoint matching the cat api url from `wsk api-exerimental list` command.
```bash
export CAT_API_URL=[url]
./postCat.sh [name of cat] [color of cat]
./getCat.sh [id]
./putCat.sh [id] [rev] [name of cat] [color of cat]
./deleteCat.sh [id] [rev]
```

## Troubleshooting

The first place to check for errors is the OpenWhisk activation log. You can view it by tailing the log on the command line with `wsk activation poll` or you can view the [monitoring console on Bluemix](https://console.ng.bluemix.net/openwhisk/dashboard).

# Credits

Created by @jzaccone

# License

Licensed under the [Apache 2.0 license](LICENSE.txt).
