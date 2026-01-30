-- AppleScript to take screenshots of CartoMix app
-- Run this manually from Script Editor if permissions block automated capture

tell application "cartomix_flutter"
    activate
end tell

delay 2

tell application "System Events"
    tell process "cartomix_flutter"
        set frontmost to true
    end tell
end tell

delay 1

-- Take screenshot of the app window
do shell script "screencapture -o -w ~/Desktop/cartomix_screenshot.png"

display dialog "Screenshot saved to Desktop" buttons {"OK"} default button "OK"
