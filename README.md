Pusher
======

A library that provides in sending push notifications to iOS and Android using Coldfusion. 
Features
=========

+ Device registration
+ Multiple devices per user (Also cross-platform)
+ Connect a device to a specific user ID in your database (optional)
+ Broadcast notifications to all your users
+ Send push notifications to a specific user
+ Handle the removal of inactive devices.
+ iOS: Supports for both sandbox and production mode
+ Android: New canonical registration ID support
+ Supported DBMS: MS SQL, MySQL

Requirements
=========

+ ColdFusion 8 or higher or Railo 3.x or higher
+ A MySQL or MS SQL database
+ An Apple SSL Push certificate (See [this excellent blog](http://www.raymondcamden.com/index.cfm/2010/9/13/Guest-Post-Apple-Push-Notifications-From-ColdFusion-in-Ten-Minutes-or-Less) by Raymond Camden on how to generate it)
+ Your Google GCM API key (See this post)
+ Install all the jars from the /jar path into your ColdFusion class path
+ Don’t forget to restart ColdFusion :)

Installation / usage
=========

### Configuration

+ Upload pusher.cfc into your webroot.
+ Edit pusher.cfc line 3 to reflect your DBMS type (‘mssql’ or ‘mysql’).
+ Edit pusher.cfc line 4 to set your datasource.
+ Call the init() function to create the neccesary database table and pass the neccesary information about the certificates.

```cfm
<cfset pusher = createObject("component","pusher").init(
          mode = "development",
          appleCertificatePath = "C:\certificates\my.p12",
          appleCertificatePassword = "myPassword",
          googleAPIKey = "xxxxxxxxxxxxxxxxxxxxxxxx"
)/>
```

### Registering devices
You configure your Android and/or iOS app to get the device token and send it to Pusher. Registering devices can be done anonymously, or a device can be connected to a user ID in your database:
```html
<!-- Example 1: Register an anonymous Apple Device --->
http://localhost/pusher.cfc?method=registerDevice&deviceType=apple&token=xxxxx
 
<!-- Example 2: Register an anonymous Android Device --->
http://localhost/pusher.cfc?method=registerDevice&deviceType=android&token=xxxxx
 
<!-- Example 3: Register an userID with an Apple Device (Same goes for Android) --->
http://localhost/pusher.cfc?method=registerDevice&deviceType=apple&token=xxxxx&userID=123
```
These methods will return a simple JSON boolean to indicate the result.

### Sending messages

Messages can be sent to specific devices, or broadcasted to all devices:
```cfm
<!--- Example 1: Broadcast a message to all your users --->
<cfset pusher.broadcastMessage(message = "Hello to all my users!")/>
 
<!--- Example 2: Broadcast a message to a specific user --->
<cfset pusher.sendMessage(userID = 123, message = "Hello there!")/>
 
<!--- Example 3: Broadcast a message to a specific user with a badge counter update --->
<cfset pusher.sendMessage(userID = 123, message = "Hello there!", badgeTotal = 3)/>
```

### Handling inactive devices

Pusher automatically handles inactive Android devices since we get immediate feedback about the device status after sending a message. Apple push notifications do not work this way. To handle inactive Apple devices you need to call the 'handleInactiveAppleDevices' function. This will retrieve a list of all inactive devices from Apple and remove them from your device table:
```cfm
<!--- Example: Clean inactive apple devices --->
<cfset pusher.handleInactiveAppleDevices()/>
```
Best practice would be to implement this in a scheduled task.

Credits
=========
This library makes use of java-apns, a Java client for the Apple Push Notification Servce. 

https://github.com/notnoop/java-apns

Support
=======
If you have any questions, feel free to contact me.

Rick Groenewegen

rick@aanzee.nl








