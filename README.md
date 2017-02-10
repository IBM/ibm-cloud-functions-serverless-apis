# OpenWhisk Getting Started - Serverless APIs - IBM Developer Technology
This project provides sample code for creating your first serverless API with Apache OpenWhisk on IBM Bluemix. It should take no more than 10 minutes to get up and running.

Once you complete this sample application, you can move on to more complex serverless application use cases.

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

## Execute `wskdeploy` to deploy the sample
Clone this repository to your system, and change to the root directory and install the app using the [`wskdeploy`](https://github.com/openwhisk/openwhisk-wskdeploy) tool, which uses a manifest to create the triggers, actions, and rules that power the sample.

```bash
./wskdeploy.sh
```

## Confirm that everything works
The code should show you how a serverless API works.

# Troubleshooting
The first place to check for errors is the OpenWhisk activation log. You can view it by tailing the log on the command line with `wsk activation poll` or you can view the [monitoring console on Bluemix](https://console.ng.bluemix.net/openwhisk/dashboard).
