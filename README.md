# Getting Started with OpenWhisk and Serverless APIs
This project provides sample code for creating a Cat API with Apache OpenWhisk on IBM Bluemix. It should take no more than 10 minutes to get up and running. Once you complete this sample application, you can move on to more complex serverless application use cases.

# Overview diagram
To come.

# Installation
You will need a Bluemix account to work with the IBM hosted instance of Apache OpenWhisk.

## Sign up for a Bluemix account
Begin by going to [bluemix.net](https://console.ng.bluemix.net/) and signing up for a free account. After you activate your account, set an organization (for example, user@example.com) and space (for example "dev"), click on OpenWhisk in the left navigation.
![alt text](docs/openwhisk-nav.png)

## Install, configure, and test the OpenWhisk CLI
Once there, click the "Download OpenWhisk CLI" button.
![alt text](docs/getting-started-with-openwhisk.png)

Then, follow the three steps to install, configure, and test connectivity. Note that the authorization key is not shown here.
![alt text](docs/openwhisk-cli.png)


### Set up Cloudant

Log into the Bluemix console and create a Cloudant instance and name it `cats-db`. You can reuse an existing instance if you already have one. Update `CLOUDANT_INSTANCE` in `local.env` to reflect the name of the Cloudant service instance.

Then set the `CLOUDANT_USERNAME` and `CLOUDANT_PASSWORD` values in `local.env` based on the service credentials for the service.

Log into the Cloudant console and create a database. Set the database name in the `CLOUDANT_DATABASE` variable.


## Execute `deploy` to deploy the sample
Clone this repository to your system, and change to the root directory and install the app using `deploy.sh`

This will be adjusted soon to use ['wskdeploy'](https://github.com/openwhisk/openwhisk-wskdeploy) tool, which uses a manifest to create the triggers, actions, and rules that power the sample.

```bash
./deploy.sh --install
```

## Confirm that everything works

Use the `postCat.sh`, `getCat.sh`, `putCat.sh`, `deleteCat.sh` helper scripts to create, get, update and delete cats respectively. But first, set the `CAT_API_URL` environment variable to the endpoint matching the cat api url from `wsk api-exerimental list` command.
```bash
export CAT_API_URL=[url]
```

# Troubleshooting
The first place to check for errors is the OpenWhisk activation log. You can view it by tailing the log on the command line with `wsk activation poll` or you can view the [monitoring console on Bluemix](https://console.ng.bluemix.net/openwhisk/dashboard).
