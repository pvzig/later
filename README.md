# Later: a read later extension for the Mac

Testing Mac App Store Builds (https://developer.apple.com/library/archive/qa/qa1884/_index.html)
1. Archive and export a build through Xcode (Distribute > Copy)
2. productbuild --component Later.app /Applications --sign "Developer ID Installer: Launch Software LLC (U63DWZL52M)" Later.pkg
3. sudo installer -store -pkg Later.pkg -target /
