

![Logo](/Images/Logo.png)




# Dosi_Xchange
iOS App for Exchanging Area Dosimeters

Created by Ryan Ford

This app was created as a major revision (complete rebuild) of the Dosimeter Manager app.  Issues overcome in this version are:
* Data is now centrally managed in CloudKit
* Dosimeters are mapped out on a Map using MapKit.  Users can navigate to dosimeters and see how many are nearby visually
* Dosimeters are listed by distance from user
* Dosimeters can be scanned by either Location Code (QRCode) or Dosimeter Number


### Current Revision Branch:  problemText

Problem Text is an Alert which is called from the Nearest Dosimeters VC by tapping a list item.

The purpose of the alert is to store a problem identified in the field such as missing dosimeter.

- [X] Develop Alert
- [ ] Create Query to populate any existing problem text to the Text Field in the Alert
- [ ] Create function to save record
- [ ] Build and test

#### Installation

```
Open LocationApp.xcodeproj in Xcode (Note Swift file does not match folder Title - Novice mistake)
Attach iPod Touch USB cable to Mac
Change device to device just attached
Click Play button, app will load to device
```
#### Connectivity

* The app stores data in CloudKit.  CloudKit is accessible from the Apple Developer Console.  A valid Apple Developer Account is needed to access the Developer Console.

#### Maintenance

* Periodic review of the Apple Developer console is necessary to verify the devices are registered correctly.  Prior to loading the app to a staff member's personal device, they should change their device name to something easily identifiable (e.g., RyanFord's iPhone).  This way, devices can be de-registered from the console by the administrator if necessary for security reasons.



