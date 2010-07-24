<!---
 * CFML component to publish updates to Pusher's REST API.
 * 
 * Insert your Pusher authentication information, or use the init method to get going.
 * <cfset pusher=createObject("component", "pusher")>
 *
 * Ported to CFC by Bradley Lambert, 6/12/2010
 * Adapted from Java class by Stephan Scheuermann
 * Copyright 2010. Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 --->
 
<cfcomponent hint="Pusher">
	<cfset variables.pusherHost = "api.pusherapp.com">
	
	<!--- Either declare your Pusher info here, or use the init method --->
	<cfset variables.pusherApplicationId = "">
	<cfset variables.pusherApplicationKey = "">
	<cfset variables.pusherApplicationSecret = "">
	
	<!---
	 * Initializes the component, if you want, or just paste your details above.
	 * @param appID
	 * @param appKey
	 * @param appSecret
	 * @return
	--->
	<cffunction name="init" access="public" output="no">
		<cfargument name="appID" required="yes">
		<cfargument name="appKey" required="yes">
		<cfargument name="appSecret" required="yes">
		
		<cfset variables.pusherApplicationId = appID>
		<cfset variables.pusherApplicationKey = appKey>
		<cfset variables.pusherApplicationSecret = appSecret>
	
		<cfreturn this>	
	</cffunction>
	
	<!---
	 * Converts a byte array to a string representation
	 * @param data
	 * @return
	--->
	<cffunction name="byteArrayToString" access="private" output="no">
		<cfargument name="data" required="yes">
		<cfset var hash="">
		
		<cfset var bigInteger = createObject("java", "java.math.BigInteger")>
		<cfset bigInteger.init(1, data)>
		<cfset hash = bigInteger.toString(16)>
		
		<!--- zero pad it --->
		<cfloop condition="hash.length() lt 64">
			<cfset hash = "0" + hash>
		</cfloop>
		
		<cfreturn hash>	
	</cffunction>
	

	<!---
	 * Returns a md5 representation of the given string
	 * @param data
	 * @return
	 --->
	<cffunction name="md5Representation" access="private" output="no">
		<cfargument name="data" required="yes">
		<cfreturn LCase(Hash(data))>
	</cffunction>

	
	<!---
	 * Returns a HMAC/SHA256 representation of the given string
	 * @param data
	 * @return
	--->
	 <cffunction name="hmacsha256Representation" access="private" output="no">
	 	<cfargument name="data" required="yes">
	 	<cfset var secret="">
	 	<cfset var mac="">
	 	<cfset var digest="">
		
		<cfscript>
			secret = createObject('java', 'javax.crypto.spec.SecretKeySpec' );
			secret.init(variables.pusherApplicationSecret.GetBytes(), 'HmacSHA256');
			mac = createObject('java', "javax.crypto.Mac");
			mac = mac.getInstance("HmacSHA256");
			mac.init(secret);
			digest = mac.doFinal(data.GetBytes());
		</cfscript>
		
		<!--- Process and return data --->
		<cfset digest = mac.doFinal(data.getBytes("UTF-8"))>
		
		<cfreturn byteArrayToString(digest)>
	</cffunction>
	
	
    <!---
     * Build query string that will be appended to the URI and HMAC/SHA256 encoded
     * @param eventName
     * @param jsonData
     * @return
     --->
		<cffunction name="buildQuery" access="private" output="no">
			<cfargument name="eventName" required="yes">
			<cfargument name="jsonData" required="yes">
			<cfargument name="socketID" required="no">
			<cfset var buffer="">
			
			<!--- Auth_Key --->
			<cfset buffer=buffer & "auth_key=">			
			<cfset buffer=buffer & variables.pusherApplicationKey>
			<!--- Timestamp --->
			<cfset buffer=buffer & "&auth_timestamp=">
			<cfset buffer=buffer & (CreateObject("java", "java.lang.System").currentTimeMillis() / 1000)>
			<!--- Auth_version --->
			<cfset buffer=buffer & "&auth_version=1.0">
			<!--- MD5 body --->
			<cfset buffer=buffer & "&body_md5=">
			<cfset buffer=buffer & md5Representation(jsonData)>
			<!--- Event Name --->
			<cfset buffer=buffer & "&name=">
			<cfset buffer=buffer & eventName>
			
			<!--- Append socket id if set --->
			<cfif isDefined("socketID")>
				<cfset buffer=buffer & "&socket_id=">
				<cfset buffer=buffer & socketID>
			</cfif>
		
			<cfreturn buffer>
		</cffunction>
		
    
    <!---
     * Build path of the URI that is also required for Authentication
     * @return
     --->
		<cffunction name="buildURIPath" access="private" output="no">
			<cfargument name="channelName" required="yes">
			<cfset var buffer="">
			
			<!--- Application ID --->
			<cfset buffer=buffer & "/apps/">
			<cfset buffer=buffer & variables.pusherApplicationId>
			<!--- Channel name --->
			<cfset buffer=buffer & "/channels/">
			<cfset buffer=buffer & channelName>
			<!--- Event --->
			<cfset buffer=buffer & "/events">

			<cfreturn buffer>			
		</cffunction>

    
    <!---
     * Build authentication signature to assure that our event is recognized by Pusher
     * @param uriPath
     * @param query
     * @return
     --->
		<cffunction name="buildAuthenticationSignature" access="private" output="no">
			<cfargument name="uriPath" required="yes">
			<cfargument name="query" required="yes">
			<cfset var buffer="">
			
			<!--- request method --->
			<cfset buffer=buffer & "POST" & Chr(10)>
			<!--- URI Path --->
			<cfset buffer=buffer & uriPath & Chr(10)>
			<!--- Query string --->
			<cfset buffer=buffer & query>

			<!--- return encoded data --->
			<cfreturn hmacsha256Representation(buffer)>
		</cffunction>

    
    <!---
     * Build URI where request is send to
     * @param uriPath
     * @param query
     * @param signature
     * @return
     --->
		<cffunction name="buildURI" access="private" output="no">
			<cfargument name="uriPath" required="yes">
			<cfargument name="query" required="yes">
			<cfargument name="signature" required="yes">
			<cfset var buffer="">
			
			<!--- Protocol --->
    	<cfset buffer=buffer & "http://">
    	<!--- Host --->
    	<cfset buffer=buffer & pusherHost>
    	<!--- URI Path --->
    	<cfset buffer=buffer & uriPath>
    	<!--- Query string --->
    	<cfset buffer=buffer & "?">
    	<cfset buffer=buffer & query>
    	<!--- Authentication signature --->
    	<cfset buffer=buffer & "&auth_signature=">
    	<cfset buffer=buffer & signature>
    	
			<cfreturn buffer>
		</cffunction>

		
    <!---
     * Delivers a message to the Pusher API
     * @param channel
     * @param event
     * @param jsonData
     * @param socketId
     * @return
     --->
		<cffunction name="triggerPush" access="public" output="no">
			<cfargument name="channel" required="yes">
			<cfargument name="event" required="yes">
			<cfargument name="jsonData" required="yes">
			<cfargument name="socketID" required="no" default="">
			<cfset var httpRequest="">

			<!--- Build URI path --->
			<cfset var uriPath = buildURIPath(channel)>
			<!--- Build query --->
			<cfset var query = buildQuery(event, jsonData, socketId)>
			<!--- Generate signature --->
			<cfset var signature = buildAuthenticationSignature(uriPath, query)>
			<!--- Build URI --->
			<cfset var pusherURL = buildURI(uriPath, query, signature)>

			<!--- send HTTP request --->
			<cfhttp url="#pusherURL#" method="POST" timeout="5" useragent="Pusher ColdFusion Library" result="httpRequest">
				<cfhttpparam type="HEADER" name="Content-Type" value="application/json">
				<cfhttpparam type="BODY" name="body" value="#jsonData.getBytes()#">
			</cfhttp>

			<cfreturn httpRequest>			
		</cffunction>
		
</cfcomponent>
