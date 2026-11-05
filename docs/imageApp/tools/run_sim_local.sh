#!/bin/zsh
# Rebuild the Flutter iOS app for the simulator against the local API and relaunch it.
S="${TMPDIR:-/tmp}/em_sim_build"; mkdir -p "$S"
U=1E839419-2D34-4B38-BA14-3C20E47B2FC2
cd "/Users/krittapatseangsomjai/WebApp/Code Fultter/EasternMangroveCommunities/eastern_mangrove_app/ios" || exit 1
DD=$(printf 'API_BASE_URL=http://127.0.0.1:3002/api' | base64)
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug -derivedDataPath $S/dd build \
  SDKROOT=iphonesimulator SUPPORTED_PLATFORMS=iphonesimulator ARCHS=arm64 ONLY_ACTIVE_ARCH=YES DART_DEFINES="$DD" > $S/xb.log 2>&1 || { tail -20 $S/xb.log; exit 1; }
xcrun simctl terminate $U com.kritdev.easternmangrove 2>/dev/null
xcrun simctl install $U $S/dd/Build/Products/Debug-iphonesimulator/Runner.app && xcrun simctl launch $U com.kritdev.easternmangrove
