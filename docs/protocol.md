# Spawn Protocol

## Overview

Spawn is divided into two main parts namely:

   1. A sidecar proxy that exposes the server part of the Spawn Protocol in the form of an HTTP API.
   2. A user function, written in any language that supports HTTP, that exposes the client part of the Spawn Protocol.

Both are client and server of their counterparts.

## Registering Actors in an Actor System


In turn, the proxy exposes an HTTP endpoint for registering a user function a.k.a ActorSystem.
 
A user function that wants to register Actors in Proxy Spawn must proceed by making a POST request to the following endpoint:

```
POST /api/v1/system HTTP 1.1
HOST: localhost
User-Agent: user-function-client/0.1.0 (this is just example)
Accept: application/octet-stream
Content-Type: application/octet-stream

registration request type bytes encoded here :-)
```

The general flow of a registration action is as follows:

```
+----------------+                                     +---------------------+                                     +-------+                   
| User Function  |                                     | Local Spawn Sidecar |                                     | Actor |                   
+----------------+                                     +---------------------+                                     +-------+                   
        |                                                       |                                                     |                       
        | HTTP POST Registration Request                        |                                                     |                       
        |------------------------------------------------------>|                                                     |                       
        |                                                       |                                                     |                       
        |                                                       | Upfront start Actors with BEAM Distributed Protocol |                       
        |                                                       |---------------------------------------------------->|
        |                                                       |                                                     |                       
        |                                                       |                                                     |Initialize Statestore 
        |                                                       |                                                     |---------------------- 
        |                                                       |                                                     |                     | 
        |                                                       |                                                     |<--------------------- 
        |                                                       |                                                     |                       
        |          HTTP Registration Response                   |                                                     |                       
        |<------------------------------------------------------|                                                     |                       
        |                                                       |                                                     | 
```

Once the system has been initialized, that is, the registration step has been successfully completed, then the user function will be able to make requests to the System Actors.

This is done through a post request to the Proxy at the `/system/:system_name/actors/:actor_name/invoke` endpoint.

A user function that wants to call Actors in Proxy Spawn must proceed by making a POST request as the follow:

```
POST /system/:system_name/actors/:actor_name/invoke HTTP 1.1
HOST: localhost
User-Agent: user-function-client/0.1.0 (this is just example)
Accept: application/octet-stream
Content-Type: application/octet-stream

invocation request type bytes encoded here :-)
```

## Spawning Actors

Actors are usually created at the beginning of the SDK's communication flow with the Proxy by the registration step described above. 
However, some use cases require that Actors can be created ***on the fly***. For these situations we have the Spawning flow described below. 

A user function that wants to Spawning new Actors in Proxy Spawn must proceed by making a POST request to the following endpoint:

```
POST /system/:system_name/actors/spawn HTTP 1.1
HOST: localhost
User-Agent: user-function-client/0.1.0 (this is just example)
Accept: application/octet-stream
Content-Type: application/octet-stream

SpawnRequest type bytes encoded here :-)
```

The general flow of a Spawning Actors is as follows:

```
+----------------+                                     +---------------------+                                     +-------+                   
| User Function  |                                     | Local Spawn Sidecar |                                     | Actor |                   
+----------------+                                     +---------------------+                                     +-------+                   
        |                                                       |                                                     |                       
        | HTTP POST SpawnRequest                                |                                                     |                       
        |------------------------------------------------------>|                                                     |                       
        |                                                       |                                                     |                       
        |                                                       | Upfront start Actors with BEAM Distributed Protocol |                       
        |                                                       |---------------------------------------------------->|
        |                                                       |                                                     |                       
        |                                                       |                                                     |Initialize Statestore 
        |                                                       |                                                     |---------------------- 
        |                                                       |                                                     |                     | 
        |                                                       |                                                     |<--------------------- 
        |                                                       |                                                     |                       
        |          HTTP SpawnResponse                           |                                                     |                       
        |<------------------------------------------------------|                                                     |                       
        |                                                       |                                                     | 
```

## Calling Actors:

Assuming that two user functions were registered in different separate Proxies, the above request would go the following way.

```
POST /system/:system_name/actors/:actor_name/invoke HTTP 1.1
HOST: localhost
User-Agent: user-function-client/0.1.0 (this is just example)
Accept: application/octet-stream
Content-Type: application/octet-stream

InvocationRequest type bytes encoded here :-)
```

```

+-----------------+                       +------------------------+       +------------------------+                                                       +--------------------------------+
| User Function A |                       | Local Spawn Sidecar A  |       | Remote User Function B |                                                       | Remote Spawn Sidecar / Actor B |
+-----------------+                       +------------------------+       +------------------------+                                                       +--------------------------------+
        |                                             |                                |                                                                                   |
        | HTTP POST InvocationRequest                 |                                |                                                                                   |
        |-------------------------------------------->|                                |                                                                                   |
        |                                             |                                |                                                                                   |
        |                                             | Lookup for Actor               |                                                                                   |
        |                                             |-----------------               |                                                                                   |
        |                                             |                |               |                                                                                   |
        |                                             |<----------------               |                                                                                   |
        |                                             |                                |                                                                                   |
        |                                             | Make a BEAM Distributed Protocol Call on Actor located at proxy b                                                  |
        |                                             |------------------------------------------------------------------------------------------------------------------->|
        |                                             |                                |                                                                                   |
        |                                             |                                |  Proxy Make HTTP POST in /api/v1/actors/actions on SDK sending ActorInvocation    |
        |                                             |                                |<----------------------------------------------------------------------------------|
        |                                             |                                |                                                                                   |
        |                                             |                                | Handle request, execute command                                                   |
        |                                             |                                |--------------------------------                                                   |
        |                                             |                                |                               |                                                   |
        |                                             |                                |<-------------------------------                                                   |
        |                                             |                                |                                                                                   |
        |                                             |                                | SDK HTTP Reply with ActorInvocationResponse and the new state of actor B          |
        |                                             |                                |---------------------------------------------------------------------------------->|
        |                                             |                                |                                                                                   | Store new State 
        |                                             |                                |                                                                                   |-----------------
        |                                             |                                |                                                                                   |                | 
        |                                             |                 Send response to the Spawn Sidecar A                                                               |<----------------
        |                                             |<-------------------------------------------------------------------------------------------------------------------|
        |                                             |                                |                                                                                   |
        | Respond to user with InvocationResponse     |                                |                                                                                   |
        |<--------------------------------------------|                                |                                                                                   |
        |                                             |                                |                                                                                   |
```

## Guide for implementing new SDKs

The Spawn protocol is very simple to implement but it is necessary for the developer of a new support language (we will use the term SDK from now on) to be aware of some important details_

1. **Make sure you understand the request flow:** 

   Before starting to develop an API around the protocol in your desired language, first try to understand how all the parts relate to each other. A good way to acquire this knowledge is to create a simple test that just fills in the protobuf objects and makes a simple request to the proxy. Here we have some example:
   
   https://github.com/eigr/spawn-springboot-sdk/blob/main/spawn-springboot-starter/src/test/java/io/eigr/spawn/springboot/starter/SpawnTest.java

2. **Spawn is both a client and an http server:**
   
   To implement an SDK for Spawn you will have to implement both an http client side and an http server side.
   This file contains the general flow of requests that occur on each side and when they should occur, but a read of the source code of other SDKs can help better understand how things connect.

3. **At first, pay attention to the main:**

   Despite being simple, Spawn has a lot of flexibility and can be configured in many ways. Try to implement default values for most parameters of protobufs.

   It is also important to note that the essential thing is that the user is able to register with the proxy and perform his actors through the invocation resource. Focus on that at first and leave the spawning feature and other protocol options for when you are able to do the first two features mentioned.

4. **API style:**

   Each language has its idiosyncrasies and therefore each language will have an API that best represents the characteristics of its base language but it is important that the languages maintain a common identity, this allows developers who are not native to a certain language to feel familiar with the general concepts.

   It is important to keep in mind and respect the terms used in the documentation so that your SDK is familiar to all developers and not just those in your language.

5. **Raise your hand and seek help:**

   When in doubt, look for issues and PR, or in our repository discussions to see if something related to the problem you are experiencing has already been mentioned.

   Also feel free to ask for help at any time via Issues or Discussions on Github or via our Discord server. If you're starting to develop a new SDK, let us know and we'll create a dedicated channel on our Discord server.