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
However, some use cases require that Actors can be created ***on the fly***. 
In other words, Spawn is used to bring to life Actors previously registered as Unamed, giving them a name and thus creating a concrete instance at runtime for that Actor. Actors created with the Spawn feature are generally used when you want to share a behavior while maintaining the isolation characteristics of the actors.
For these situations we have the Spawning flow described below. 

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
        |                                             |                                | Handle request, execute action                                                   |
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