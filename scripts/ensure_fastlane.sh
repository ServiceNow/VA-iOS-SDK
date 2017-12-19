export PATH="$HOME/.fastlane/bin:$PATH"

if ! hash fastlane 2>/dev/null; then
    FASTLANE_INSTALL_SCRIPT="
       try
            tell application \"Xcode\" to display dialog \"Fastlane is needed for development automation.\" with title \"Fastlane Not Installed\" with icon note buttons {\"Learn More…\", \"Cancel\" , \"Install Fastlane\"} default button \"Install Fastlane\" cancel button \"Cancel\"
            set buttonResult to button returned of result
            return buttonResult
       end try
    "

    FASTLANE_INSTALL_RESULT=`osascript -e "$FASTLANE_INSTALL_SCRIPT"`

    if [[ $FASTLANE_INSTALL_RESULT == 'Install Fastlane' ]]; then
        brew tap caskroom/cask
        brew cask install fastlane
        echo 'export PATH="$HOME/.fastlane/bin:$PATH"' >>~/.bash_profile
    elif [[ $FASTLANE_INSTALL_RESULT == 'Learn More…' ]]; then
        open https://docs.fastlane.tools/#choose-your-installation-method
        echo "error: fastlane is not installed."
        exit 1
    else
       echo "error: fastlane is not installed."
       exit 1
    fi
fi