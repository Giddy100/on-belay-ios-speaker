## Project Overview

**OnBelay** - Android and iPhone App for Multi Pitch Climbers

## Purpose

Ability to communicate between multi-pitch climbers group members using pre-defined voice commands. The application is configured to pre-defined commands which it can identify after a wakeup-phrase and once identified, play it using push notification to all group members. 

## Architecture
- Client - Kotlin for Android and Swift for iOS. 
- Server - Google Fierbase, Google Functions

## Communication
- Client to Server - Google functions
- Server to Client - Push Notifications

## Principles
- Multi language support, including Right-To-Left languages.
- All Texts which are presented to the User should come from translated resource. We will start with English and Hebrew.
- User interface should use the latest UI standards
- We will only listen to speech in English-US, even if the phone Local is different.
- For speech recognition, we should use On-Device recognition and not 'over the internet' recognition.
- As the application should listen to speech even when the application is in the background, we should follow the device approach to make sure we adhere the device rules
- The App should use standard logging mechanism

## Server API
- The server api is in file index.js at github Giddy100/on-belay-server


