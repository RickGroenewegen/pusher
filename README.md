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



