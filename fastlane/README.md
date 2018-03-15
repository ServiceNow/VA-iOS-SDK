fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios carthage_bootstrap
```
fastlane ios carthage_bootstrap
```
Bootstraps carthage
### ios certificates
```
fastlane ios certificates
```
Downloads development profile and certificate
### ios register_new_device
```
fastlane ios register_new_device
```
Register new device
### ios enterprise
```
fastlane ios enterprise
```
Submit a new enterprise build to Hockey
### ios ensure_certificates
```
fastlane ios ensure_certificates
```
Ensures all profiles and certificates are up to date

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
