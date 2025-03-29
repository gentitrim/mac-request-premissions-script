#!/bin/bash


TCC_DB="/Library/Application Support/com.apple.TCC/TCC.db"

EXECUTABLE_PATH="/Applications/NinjaRMMAgent/programfiles/ninjarmm-macagent"

APP_PATH_2="/Applications/connectwisecontrol-ea1f1eccebd72cab.app"

REAL_PATH=$(realpath "$EXECUTABLE_PATH")

BUNDLE_ID=$(codesign -d --entitlements :- "$REAL_PATH" 2>/dev/null | grep -A1 "<key>application-identifier</key>" | grep "<string>" | sed 's/<[^>]*>//g')

APP_BUNDLE_ID_2=$(defaults read "$APP_PATH_2/Contents/Info" CFBundleIdentifier)


if [ -z "$APP_BUNDLE_ID_2" ]; then
    echo "Could not determine the bundle identifier for $APP_PATH_2."
    exit 1
fi

while true; do
  
    HAS_FDA=$(sqlite3 "$TCC_DB" "SELECT auth_value FROM access WHERE service='kTCCServiceSystemPolicyAllFiles' AND (client='$BUNDLE_ID' OR client='$REAL_PATH');")

    if [ "$HAS_FDA" == "2" ]; then
        echo "NinjaRMM has Full Disc access"
        has_accessibility=$(sqlite3 "$TCC_DB" "SELECT auth_value FROM access WHERE service='kTCCServiceAccessibility' AND client='$APP_BUNDLE_ID_2';")

        if [ "$has_accessibility" == "2" ]; then
            has_screen_recording=$(sqlite3 "$TCC_DB" "SELECT auth_value FROM access WHERE service='kTCCServiceScreenCapture' AND client='$APP_BUNDLE_ID_2';")
            echo "ConectWise has Accessibility permission"
            if [ "$has_screen_recording" == "2" ]; then
                echo "The app with bundle identifier $APP_BUNDLE_ID_2 has Screen Recording permissions. All permissions are set correctly"
                break # Exit the loop if permission is granted
            elif [ "$has_screen_recording" == "0" ];then
                echo "The app with bundle identifier $APP_BUNDLE_ID_2 does not have Screen Recording permissions."

                open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"

                osascript <<EOD
tell application "System Events"
    activate
    display dialog "Please grant Screen Recording permissions to the application $APP_PATH_2 in the Security & Privacy settings." buttons {"OK"} default button "OK"
end tell
EOD
sleep 10
            else
                open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"

                osascript <<EOD
tell application "System Events"
    activate
    display dialog "Please add on the Screen Recording list the application $APP_PATH_2 in the Security & Privacy settings." buttons {"OK"} default button "OK"
end tell
EOD
sleep 10
            fi
            #end of screen recording


            #permission
        elif [ "$has_accessibility" == "0" ]; then

            open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

            osascript <<EOD
    tell application "System Events"
    activate
    display dialog "Please grant the Premission for the Accessibility to the application $APP_PATH_2 in the Security & Privacy settings." buttons {"OK"} default button "OK"
    end tell
EOD
sleep 10
        else
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

            osascript <<EOD
    tell application "System Events"
    activate
    display dialog "Please add to the Accessibility list the $APP_PATH_2 in the Security & Privacy settings." buttons {"OK"} default button "OK"
    end tell
EOD

        
            sleep 10
        fi
    else
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"

        osascript <<EOD
    tell application "System Events"
    activate
    display dialog "Please grant Full Disk Access to NinjaRmm in the Security & Privacy settings." buttons {"OK"} default button "OK"
    end tell
EOD
        sleep 10
    fi
done
