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

+ ColdFusion 8 or higher or Railo 3.x or higher.
+ A MySQL or MS SQL database.
+ An Apple SSL Push certificate (See [Nesta CMS](http://effectif.com/nesta "this") excellent blog by Raymond Camden on how to generate it). This should be a file with a .p12 file extention. Be sure to remember the .p12 password you choose. You will need it later on.
Your Google GCM API key (See this post).
Download the java-apns jar’s with dependencies and move them into your ColdFusion class path.
Download gcm-server.jar and move it into your ColdFusion class path.
Download json_simple-1.1.jar and move it into your ColdFusion class path.
Don’t forget to restart ColdFusion :)



