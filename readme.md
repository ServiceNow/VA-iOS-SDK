# SnowChat iOS

SnowChat iOS is the ServiceNow Virtual Agent Chat framework for iOS.

## Getting Started

#### Overview
- Open `SnowChat.xcworkspace`
- Run `🎯 Carthage Bootstrap` to build dependencies
- Run `🎯 Install Certificates` to install development certificates
- Run `SnowKangaroo` demo app 🎉

## Dependencies

#### Carthage
SnowChat uses [Carthage](https://github.com/Carthage/Carthage) for dependency management. 

The `🎯 Carthage Bootstrap` scheme will prompt to install Carthage if needed and then build the project's dependencies. 

Alternatively, you can [manually install Carthage](https://github.com/Carthage/Carthage/#installing-carthage).

#### fastlane
SnowChat uses [fastlane](https://fastlane.tools) for development and build automation.

fastlane [match](https://docs.fastlane.tools/actions/match) is used to manage certificates and provisioning profiles. The `🎯 Install Certificates` scheme will prompt to install fastlane if needed and then download and install the shared development certificates and provisioning profiles.

Alternatively, you can [manually install fastlane](https://docs.fastlane.tools/getting-started/ios/setup/#choose-your-installation-method).

fastlane is also used by Jenkins for automated builds.
