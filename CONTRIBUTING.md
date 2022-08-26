# Contributing to eigr/spawn

Thanks for contributing to eigr/spawn!

Before continuing please read our [code of conduct][code-of-conduct] which all
contributors are expected to adhere to.

[code-of-conduct]: https://github.com/eigr/spawn/blob/master/CODE_OF_CONDUCT.md


## Contributing bug reports

If you have found a bug in eigr/spawn please check to see if there is an open
ticket for this problem on [our GitHub issue tracker][issues]. If you cannot
find an existing ticket for the bug please open a new one.

[issues]: https://github.com/eigr/spawn/issues

A bug may be a technical problem such or a user experience issue such as
unclear or absent documentation. If you are unsure if your problem is a bug
please open a ticket and we will work it out together.


## Contributing code changes

Code changes to eigr/spawn are welcomed via the process below.

1. Find or open a GitHub issue relevant to the change you wish to make and
   comment saying that you wish to work on this issue. If the change
   introduces new functionality or behaviour this would be a good time to
   discuss the details of the change to ensure we are in agreement as to how
   the new functionality should work.
2. Open a GitHub pull request with your changes and ensure the tests and build
   pass on CI.
3. A eigr team member will review the changes and may provide feedback to
   work on. Depending on the change there may be multiple rounds of feedback.
4. Once the changes have been approved the code will be rebased into the
   `main` branch.

# Development

This sections below describes the process for running and development this application on your local computer.

## Getting started

First of all you will need to have some tools installed on your computer:

1. Erlang/OTP 24 or newest.
2. Elixir 1.13 or newest.
3. Minikube, kind, K3s, or other Kubernetes flavor for local development.

After installing these tools, open Terminal and run the following:

```shell
git clone https://github.com/eigr/spawn.git
cd spawn
make
```

> **_NOTE:_** Compiling, test and building all applications and containers can take some time so this is the time when you stop and go have a delicious coffee **;-)**

There are many Make tasks to help during development for example to run the proxy locally via the elixir console there is a make task called ***run-proxy-local***, or to run all tests there is another called ***test***. Take a good look at the **Makefile** file to know all the tasks.

## Tour

The Spawn repository is divided into many directories and even though it is an Umbrella-type project it is also composed of many apps. Next, we will talk a little about the main directories and apps.

* **docs:** Where we try to keep important documents for understanding the platform.

* **config:** Where are all the default settings for the different applications that make up Spawn.

* **apps:** directory where the code of all the applications that are part of the Eigr Functions Spawn platform can be found. The applications are divided as follows:

    * ***protos:*** Contains the protobuf files and compiled modules of the Spawn protocol.

    * ***actors:*** This app concentrates all of the Spawn actors logic and is where a lot of the magic happens.

    * ***proxy:*** This is the application that will act as a sidecar of the user functions. It contains the http server responsible for implementing the Spawn HTTP/Protobuf Protocol.

    * ***statestores:*** Includes all data persistence logic and access to different databases and providers.

    * ***operator:*** This is the Kubernetes Controller/Operator that controls the provisioning of the sidecars and user functions.

    * ***metrics_endpoint:*** Helper library for exposing metrics in Prometheus format across applications.

    * ***activator:*** It has the behaviors/contracts and implementation of the event handlers to be used by the different providers of the Activators.

    * ***activator_´name´:*** Each application that starts with activator and follows the name of a given event provider implements in turn the connection logic and event management of that specific provider.

* **examples:** Where you can find some examples of using our CRDs and user applications.

**Don't forget to subscribe to our [Discord](https://discord.gg/2PcshvfS93) server and we wish you a good hack**.