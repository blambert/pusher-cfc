Pusher CFML Component
=====================

This package contains a thread-safe CFML (ColdFusion) component library for pushing messages using the PusherApp.com REST web service.

The CFC is, for the most part, a straight port of Stephan Scheuermann's MIT-licensed Java Pusher library for Google App Engine (http://github.com/SScheuermann/gae-java-libpusher).'

Get Started
-----------
You may choose to either hard-code your Pusher credentials in the CFC, or pass them into the library using the included "init" method.

  <cfset push=createObject("component", "pusher").init("[appid]", "[appkey]", "[appsecret]")>

There is one "triggerPush" method.  The socket_id parameter is not required.

  <cfset push.triggerPush("[channelname]", "[eventname]", "[jsondata]", "[socket_id]")>

Compatibility
-------------
This CFC requires JDK version 1.5 or higher.  Version 1.4.2 (which ships with CFMX7) lacks the internals to generate HMAC SHA-256 hashes.
 
This CFC has been tested on Railo 3.1.2.001 (JDK 1.6) and ColdFusion MX 7 (JDK 1.5). 

License
-------
Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
