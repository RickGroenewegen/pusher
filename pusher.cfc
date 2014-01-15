<cfcomponent>

	<cfset variables.dbtype = "mssql"/> <!--- DBMS type ('mysql' or 'mssql') --->
	<cfset variables.datasource = "my_datasource"/> <!--- Data source as registered in the ColdFusion administrator --->
	<cfset variables.tablename = "pushdevices"/> <!--- Table name that is used in de database --->
	<cfset variables.applePushService = ""/>
	<cfset variables.androidPushService = ""/>
	
	<cffunction name="init" returntype="any">	
		
		<cfargument name="mode" type="string" required="true" default="development"/>		
		<cfargument name="appleCertificatePath" type="string" required="false" default=""/>
		<cfargument name="appleCertificatePassword" type="string" required="false" default=""/>
		<cfargument name="googleAPIKey" type="string" required="false" default=""/>
		
		<cfset var pushService = ""/>
		<cfset var qCreate = ""/>

		<!--- Check if the P12 certificate and password was provided --->
		<cfif len(arguments.appleCertificatePath) AND len(appleCertificatePassword)>			
			<cfset pushService = createObject("java","com.notnoop.apns.APNS").newService().withCert(arguments.appleCertificatePath,arguments.appleCertificatePassword)/>
			<cfif arguments.mode EQ "development">
				<cfset variables.applePushService = pushService.withSandboxDestination().build() />
			<cfelse>
				<cfset variables.applePushService = pushService.withProductionDestination().build() />
			</cfif>
		</cfif>

		<!--- Check if the Google API key was provided --->		
		<cfif len(arguments.googleAPIKey)>
			<cfset variables.androidPushService = createObject( "java","com.google.android.gcm.server.Sender").init(arguments.googleAPIKey)/>
		</cfif>

		<!--- Try to create the device table. Currently a try/catch to support as many DBMS's as possible --->	
		<cfif variables.dbtype EQ "mysql">		
			<!--- Create the MySQL table if it doesn't exist --->
			<cfquery result="qCreate" datasource="#variables.datasource#">
				IF NOT EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'[dbo].[#variables.tablename#]') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)	
				CREATE TABLE [dbo].[#variables.tablename#] 
				(
					id INT IDENTITY(1,1) NOT NULL,
					userID INTEGER,
					deviceType VARCHAR(25),
					token VARCHAR(500)
				)
			</cfquery>
		<cfelseif variables.dbtype EQ "mssql">
			<!--- Create the MSSQL table if it doesn't exist --->
			<cfquery result="qCreate" datasource="#variables.datasource#">
				CREATE TABLE IF NOT EXISTS #variables.tablename#
				(
					id INTEGER AUTO_INCREMENT PRIMARY KEY,
					userID INTEGER,
					deviceType VARCHAR(25),
					token VARCHAR(500)
				);
			</cfquery>
		</cfif>

		<cfreturn this/>

	</cffunction>

	<cffunction name="registerDevice" access="remote" returntype="boolean" returnformat="JSON">

		<cfargument name="deviceType" type="string" required="true"/>		
		<cfargument name="token" type="string" required="true"/>		
		<cfargument name="userID" type="numeric" required="false" default="0"/>		
	
		<cfset var qDevice = ""/>
		<cfset var qInsertDevice = ""/>
		<cfset var qUpdateDevice = ""/>

		<!--- Check for valid device type --->
		<cfif NOT listFindNoCase("android,apple",arguments.deviceType)>
			<cfthrow message="Invalid device type: #arguments.deviceType#"/>
		</cfif>
		
		<!--- See if the device is already present --->
		<cfquery name="qDevice" datasource="#variables.datasource#">
			SELECT	id
			FROM	#variables.tablename#
			WHERE	#variables.tablename#.deviceType = <cfqueryparam value="#arguments.deviceType#" cfsqltype="cf_sql_varchar"/>
			<cfif arguments.userID EQ 0>
				AND #variables.tablename#.token = <cfqueryparam value="#arguments.token#" cfsqltype="cf_sql_varchar"/>
			<cfelse>
				AND	#variables.tablename#.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_numeric"/>
			</cfif>
		</cfquery>

		<cfif NOT qDevice.recordcount>
			<!--- Device is not present: Create it --->
			<cfquery result="qInsertDevice" datasource="#variables.datasource#">
				INSERT INTO #variables.tablename# 	(	
														userID,
														deviceType,
														token
													) 
				VALUES 								(
														<cfqueryparam value="#userID#" cfsqltype="cf_sql_numeric"/>,
														<cfqueryparam value="#arguments.deviceType#" cfsqltype="cf_sql_varchar"/>,
														<cfqueryparam value="#arguments.token#" cfsqltype="cf_sql_varchar"/>
													)
			</cfquery>			
		<cfelse>
			<!--- Device is present: Update it --->
			<cfquery result="qUpdateDevice" datasource="#variables.datasource#">
				UPDATE	#variables.tablename# 	
				SET		token = <cfqueryparam value="#arguments.token#" cfsqltype="cf_sql_varchar"/>
				WHERE	id = <cfqueryparam value="#qDevice.id#" cfsqltype="cf_sql_numeric"/>
			</cfquery>		
		</cfif>
		
		<cfreturn true/>

	</cffunction>

	<cffunction name="broadcastMessage" returntype="boolean">
		
		<cfargument name="message" type="string" required="true"/>
	
		<cfset var qTokens = ""/>

		<!--- Get all the device tokens from the database --->
		<cfquery name="qTokens" datasource="#variables.datasource#">
			SELECT		id,deviceType,token
			FROM		#variables.tablename#
		</cfquery>
		
		<!--- Send a message to all the tokens --->
		<cfloop query="qTokens">				
			<cfif qTokens.deviceType EQ "apple">		
				<cfset this.sendMessageToApple(qTokens.token,arguments.message)/>
			<cfelseif qTokens.deviceType EQ "android">		
				<cfset this.sendMessageToAndroid(qTokens.id,qTokens.token,arguments.message)/>
			</cfif>
		</cfloop>
		
		<cfreturn true/>

	</cffunction>

	<cffunction name="sendMessage" returntype="boolean">
		
		<cfargument name="userID" type="numeric" required="true"/>
		<cfargument name="message" type="string" required="true"/>
		<cfargument name="badgeTotal" type="numeric" required="false" default="0"/> <!--- iOS only: Sets the badge counter on the app icon --->
			
		<cfset var qTokens = ""/>
		<cfset var payload = ""/>

		<!--- Get all the tokens that are registered --->
		<cfquery name="qTokens" datasource="#variables.datasource#">
			SELECT		id,deviceType,token
			FROM		#variables.tablename#
			WHERE		userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_numeric"/>
		</cfquery>
				
		<!--- Send a message to all the registered devices of this user --->
		<cfloop query="qTokens">				
			<cfif qTokens.deviceType EQ "apple">		
				<cfset this.sendMessageToApple(qTokens.token,arguments.message)/>
			<cfelseif qTokens.deviceType EQ "android">		
				<cfset this.sendMessageToAndroid(qTokens.id,qTokens.token,arguments.message)/>
			</cfif>
		</cfloop>

		<cfreturn true/>

	</cffunction>

	<cffunction name="sendMessageToApple" returntype="void">
		
		<cfargument name="token" type="string" required="true"/>
		<cfargument name="message" type="string" required="true"/>
		<cfargument name="badgeTotal" type="numeric" required="false" default="0"/> 
	
		<cfset var payload = ""/>

		<!--- Check if the push service was created during init() --->
		<cfif NOT isObject(variables.applePushService)>
			<cfthrow message="Unable to send messsge: applePushService is not an object!"/>
		</cfif>

		<!--- Create the message --->
		<cfset payload = createObject( "java", "com.notnoop.apns.APNS" ).newPayload()
            .badge(arguments.badgeTotal)
            .alertBody(arguments.message)
            .sound("PushNotification.caf")
			.build()/>

		<!--- Send the payload --->
		<cfset variables.applePushService.push(arguments.token, payload)/>	

	</cffunction>

	<cffunction name="sendMessageToAndroid" returntype="void">
		
		<cfargument name="tokenID" type="string" required="true"/>
		<cfargument name="token" type="string" required="true"/>
		<cfargument name="message" type="string" required="true"/>
		
		<cfset var payload = ""/>
		<cfset var result = ""/>
		<cfset var qUpdateDevice = ""/>
		<cfset var qDeleteDevice = ""/>

		<!--- Check if the push service was created during init() --->
		<cfif NOT isObject(variables.androidPushService)>
			<cfthrow message="Unable to send messsge: androidPushService is not an object!"/>
		</cfif>

		<!--- Build a message --->
		<cfset payload = createObject( "java","com.google.android.gcm.server.Message$Builder").addData("message",arguments.message).build()/>			
		
		<!--- Send the payload --->
		<cfset result = variables.androidPushService.send(payload, arguments.token, 5)/>
					
		<!--- Check if the user has a new canonical registration ID, if so: replace it --->			
		<cfif NOT isNull(result.getCanonicalRegistrationId())>
			<cfquery result="qUpdateDevice" datasource="#variables.datasource#">
				UPDATE		#variables.tablename#
				SET			token = <cfqueryparam value="#result.getCanonicalRegistrationId()#" cfsqltype="cf_sql_varchar" />
				WHERE		id = <cfqueryparam value="#arguments.tokenID#" cfsqltype="cf_sql_numeric"/>								
			</cfquery>
		</cfif>

		<!--- Check if this is an inactive device. If so: Remove it --->
		<cfif result.getErrorCodeName() EQ "NotRegistered">
			<cfquery result="qDeleteDevice" datasource="#variables.datasource#">
				DELETE FROM	#variables.tablename#
				WHERE		id = <cfqueryparam value="#arguments.tokenID#" cfsqltype="cf_sql_numeric"/>						
			</cfquery>
		</cfif>

	</cffunction>

	<cffunction name="handleInactiveAppleDevices" returntype="void">	
		
		<!--- Get all the inactive devices --->
		<cfset var inactiveDevices = variables.applePushService.getInactiveDevices()/>
		<cfset var deviceToken = "" />
		<cfset var qDeleteDeviceToken = ""/>

		<!--- Loop over the device collection and remove the from the table --->
		<cfloop collection="#inactiveDevices#" item="deviceToken">
			<cfquery name="qDeleteDeviceToken" datasource="#variables.datasource#">
				DELETE FROM 	devicetokens 
				WHERE 			token = <cfqueryparam value="#deviceToken#" cfsqltype="cf_sql_varchar"/> 
				AND 			deviceType = 'apple'
			</cfquery>
		</cfloop>
		
	</cffunction>

</cfcomponent>