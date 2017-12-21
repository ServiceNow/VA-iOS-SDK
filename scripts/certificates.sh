CERT_PASSWORD_SCRIPT="
  try
    tell application \"Xcode\" to set cert_password to display dialog \"Enter the password for shared mobile development certificates.\n\nAsk a team member. 😉\" ¬
      with title \"Mobile Certificates Password\" ¬
      with icon caution ¬
      default answer \"\" ¬
      buttons {\"Cancel\", \"OK\"} default button 2 ¬
      with hidden answer 
    return (text returned of cert_password)
  end try
"

CERT_PASSWORD_RESULT=`osascript -e "$CERT_PASSWORD_SCRIPT"`

if [ -z "$CERT_PASSWORD_RESULT" ]; then
    echo "error: Must provide a password for mobile certificates."
    exit 1
fi

export MATCH_PASSWORD=$CERT_PASSWORD_RESULT

fastlane certificates