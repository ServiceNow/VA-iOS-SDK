if ! hash carthage 2>/dev/null; then
    CARTHAGE_INSTALL_SCRIPT="
       try
            tell application \"Xcode\" to display dialog \"Carthage is needed to build project dependencies.\" with title \"Carthage Not Installed\" with icon note buttons {\"Learn More…\", \"Cancel\" , \"Install Carthage\"} default button \"Install Carthage\" cancel button \"Cancel\"
            set buttonResult to button returned of result
            return buttonResult
       end try
    "

    CARTHAGE_INSTALL_RESULT=`osascript -e "$CARTHAGE_INSTALL_SCRIPT"`

    if [[ $CARTHAGE_INSTALL_RESULT == 'Install Carthage' ]]; then
        brew install carthage
    elif [[ $CARTHAGE_INSTALL_RESULT == 'Learn More…' ]]; then
        open https://github.com/Carthage/Carthage/#installing-carthage
        echo "error: Carthage is not installed."
        exit 1
    else
       echo "error: Carthage is not installed."
       exit 1
    fi
fi