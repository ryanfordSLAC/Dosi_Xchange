

![Logo](/Images/WhiteLogo.png)




# Dosi_Xchange
iOS App for Exchanging Area Dosimeters

Created by Ryan Ford

This app was created as a major revision (complete rebuild) of the Dosimeter Manager app.  Issues overcome in this version are:
* Data is now centrally managed in CloudKit
* Dosimeters can be scanned by either Location Code (QRCode) or Dosimeter Number
* Dosimeters are mapped out on a Map using MapKit
  - Users can navigate to dosimeters and see how many are nearby visually
  - Users can filter pins displayed on the map based on the status of the location
* Dosimeters are listed by distance from user in 'Nearest Dosimeters'
* All locations are listed by status (active/inactive) in 'All Locations'
  - Users can search for a location by QR Code
  - Users can activate locations and edit dosimeter record
* User location detail is available in 'Location Details'
* 'Email Data' allows user to email all data as a .csv file attachment


#### Installation

```
Open LocationApp.xcodeproj in Xcode (Note Swift file does not match folder Title - Novice mistake)
Attach iPod Touch USB cable to Mac
Change device to device just attached
Click Play button, app will load to device
An Apple iCloud account must be registered on the device to edit and save records
```
#### Connectivity

* The app stores data in CloudKit.  CloudKit is accessible from the Apple Developer Console.  A valid Apple Developer Account is needed to access the Developer Console.

#### Maintenance

* Periodic review of the Apple Developer console is necessary to verify the devices are registered correctly.  Prior to loading the app to a staff member's personal device, they should change their device name to something easily identifiable (e.g., RyanFord's iPhone).  This way, devices can be de-registered from the console by the administrator if necessary for security reasons.



