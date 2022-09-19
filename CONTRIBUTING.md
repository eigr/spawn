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
4. MySQL, Postgres or other supported database running in local environment.

> **_NOTE:_** All scripts will use a MySQL DB with a database called eigr-functions-db by default. Make sure you have a working instance on your localhost or you will have to change make tasks or run commands manually during testing.

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

    * ***spawn:*** Contains the protobuf files, compiled modules of the Spawn protocol and all stuff to make cluster works. So with the basis of our tests.

    * ***actors:*** This app concentrates all of the Spawn actors logic and is where a lot of the magic happens.

    * ***proxy:*** This is the application that will act as a sidecar of the user functions. It contains the http server responsible for implementing the Spawn HTTP/Protobuf Protocol.

    * ***statestores:*** Includes all data persistence logic and access to different databases and providers.

    * ***operator:*** This is the Kubernetes Controller/Operator that controls the provisioning of the sidecars and user functions.

    * ***metrics_endpoint:*** Helper library for exposing metrics in Prometheus format across applications.

    * ***activator:*** It has the behaviors/contracts and implementation of the event handlers to be used by the different providers of the Activators.

    * ***activator_´name´:*** Each application that starts with activator and follows the name of a given event provider implements in turn the connection logic and event management of that specific provider.

* **examples:** Where you can find some examples of using our CRDs and user applications.

## Guide for implementing new SDKs

The Spawn protocol is very simple to implement but it is necessary for the developer of a new support language (we will use the term SDK from now on) to be aware of some important details_

1. **Make sure you understand the request flow:** 

   Before starting to develop an API around the protocol in your desired language, first try to understand how all the parts relate to each other. A good way to acquire this knowledge is to create a simple test that just fills in the protobuf objects and makes a simple request to the proxy. Here we have some example:
   
   https://github.com/eigr/spawn-springboot-sdk/blob/main/spawn-springboot-starter/src/test/java/io/eigr/spawn/springboot/starter/SpawnTest.java

2. **Spawn is both a Client and an HTTP Server:**
   
   To implement an SDK for Spawn you will have to implement both an http client side and an http server side. [This file](docs/protocol.md) contains the general flow of requests that occur on each side and when they should occur, but a read of the source code of other SDKs can help better understand how things connect.

3. **At first, pay attention to the main:**

   Despite being simple, Spawn has a lot of flexibility and can be configured in many ways. Try to implement default values for most parameters of protobufs.

   It is also important to note that the essential thing is that the user is able to register with the proxy and perform his actors through the invocation resource. Focus on that at first and leave the spawning feature and other protocol options for when you are able to do the first two features mentioned.

4. **API style:**

   Each language has its idiosyncrasies and therefore each language will have an API that best represents the characteristics of its base language but it is important that the languages maintain a common identity, this allows developers who are not native to a certain language to feel familiar with the general concepts.

   It is important to keep in mind and respect the terms used in the documentation so that your SDK is familiar to all developers and not just those in your language.

5. **Note on Spawning:**

   The Spawning Actors on the Fly feature is very similar to the SDK registration feature on the Proxy but it has an important feature that must be considered and that refers to the previous item in this guide.
   
   Basically, an actor to be created on the fly must, even in these cases, be created in the SDK in advance, that is, the dynamic Actor must have a template of itself previously registered in the registration step. This is necessary because this way the proxy will know how to optimize the initialization and the way these actors will actually be created in the future. It is important for the proxy to know which are all the functions that a Host Function will define.
   
   For a more complete understanding, see the example in Java of how the Actors are registered and how the Spawning of these actors is performed on the fly:

      * First an actor is defined and its identity is defined as Abstract.
        https://github.com/eigr/spawn-springboot-sdk/blob/main/spawn-springboot-examples/src/main/java/io/eigr/spawn/example/AbstractActor.java

      * Then, when you really want to create a concrete instance of this actor, a real name is given and this name is associated with the abstract type of the Actor.  
        https://github.com/eigr/spawn-springboot-sdk/blob/e88b59f1505647a867adb9607a4d39baa249ebb2/spawn-springboot-examples/src/main/java/io/eigr/spawn/example/App.java#L36

6. **Raise your hand and seek help:**

   When in doubt, look for issues and PR, or in our repository discussions to see if something related to the problem you are experiencing has already been mentioned.

   Also feel free to ask for help at any time via Issues or Discussions on Github or via our Discord server. If you're starting to develop a new SDK, let us know and we'll create a dedicated channel on our Discord server.

**Don't forget to subscribe to our [Discord](https://discord.gg/2PcshvfS93) server and we wish you a good hack**.