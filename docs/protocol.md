# Spawn Protocol

## Overview

Spawn is divided into two main parts namely:

   1. A sidecar proxy that exposes the server part of the Spawn Protocol in the form of an HTTP API.
   2. A user function, written in any language that supports HTTP, that exposes the client part of the Spawn Protocol.

Both are client and server of their counterparts.

## Registering Actors in an Actor System


In turn, the proxy exposes an HTTP endpoint for registering a user function a.k.a ActorSystem.
 
A user function that wants to register actors in Proxy Spawn must proceed by making a POST request to the following endpoint:

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

This is done through a post request to the Proxy at the `/system/:name/actors/:actor_name/invoke` endpoint.

A user function that wants to call actors in Proxy Spawn must proceed by making a POST request as the follow:

```
POST /system/:name/actors/:actor_name/invoke HTTP 1.1
HOST: localhost
User-Agent: user-function-client/0.1.0 (this is just example)
Accept: application/octet-stream
Content-Type: application/octet-stream

invocation request type bytes encoded here :-)
```

## Calling Actors:

Assuming that two user functions were registered in different separate Proxies, the above request would go the following way:

```

+-----------------+                       +------------------------+       +------------------------+                                         +--------------------------------+
| User Function A |                       | Local Spawn Sidecar A  |       | Remote User Function B |                                         | Remote Spawn Sidecar / Actor B |
+-----------------+                       +------------------------+       +------------------------+                                         +--------------------------------+
        |                                             |                                |                                                                     |
        | HTTP POST Invocation Request.               |                                |                                                                     |
        |-------------------------------------------->|                                |                                                                     |
        |                                             |                                |                                                                     |
        |                                             | Lookup for Actor               |                                                                     |
        |                                             |-----------------               |                                                                     |
        |                                             |                |               |                                                                     |
        |                                             |<----------------               |                                                                     |
        |                                             |                                |                                                                     |
        |                                             | Make a BEAM Distributed Protocol Call on Actor located at proxy b                                    |
        |                                             |----------------------------------------------------------------------------------------------------->|
        |                                             |                                |                                                                     |
        |                                             |                                |                        Make HTTP POST in /api/v1/actors/actions     |
        |                                             |                                |<--------------------------------------------------------------------|
        |                                             |                                |                                                                     |
        |                                             |                                | Handle request, execute command                                     |
        |                                             |                                |--------------------------------                                     |
        |                                             |                                |                               |                                     |
        |                                             |                                |<-------------------------------                                     |
        |                                             |                                |                                                                     |
        |                                             |                                | HTTP Reply with the result and the new state of actor B             |
        |                                             |                                |-------------------------------------------------------------------->|
        |                                             |                                |                                                                     | Store new State 
        |                                             |                                |                                                                     |-----------------
        |                                             |                                |                                                                     |                | 
        |                                             |                 Send response to the Spawn Sidecar A                                                 |<----------------
        |                                             |<-----------------------------------------------------------------------------------------------------|
        |                                             |                                |                                                                     |
        | Respond to user with result value           |                                |                                                                     |
        |<--------------------------------------------|                                |                                                                     |
        |                                             |                                |                                                                     |
```