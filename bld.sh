xcodebuild -scheme Carthage\ Bootstrap -workspace SnowChat.xcworkspace -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 8'
xcodebuild -scheme AMBClient -workspace SnowChat.xcworkspace -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 8'
xcodebuild -scheme SnowChat -workspace SnowChat.xcworkspace -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 8'
xcodebuild test -scheme SnowChat -target SnowChatTests -workspace SnowChat.xcworkspace -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 8'
