PROJECT="Example/SnowKangaroo.xcodeproj/project.pbxproj"

# Update bundle id
sed -i '' 's/com.servicenow.kangaroo/com.servicenow.kangaroo-internal/g' $PROJECT

# Update team
sed -i '' 's/AS2BZHDV7Q/NV85HZ2543/g' $PROJECT

# Update provisioning profile
sed -i '' 's/match Development com.servicenow./match InHouse com.servicenow./g' $PROJECT