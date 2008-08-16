#!/bin/sh

# Determine the project name and version
PROJ=$(ls -d *.xcodeproj | sed s/.xcodeproj//)
VERS=$(agvtool mvers -terse1)

# Derived names
DIST=${PROJ}_${VERS}
DMG=$DIST.dmg

# Remove old targets
rm -f $DMG
test -d $DIST && chmod -R +w $DIST && rm -rf $DIST
mkdir $DIST


# Create the Embedded framework
xcodebuild -target JSON -configuration Release install DSTROOT=/tmp/dummy || exit 1
cp -p -R /tmp/Frameworks/$PROJ.framework $DIST/

# Create the iPhone SDK
xcodebuild -target libjson -configuration Release -sdk iphoneos2.0 install \
    ARCHS=armv6 \
    DSTROOT=$DIST/SDKs/JSON/iphoneos.sdk || exit 1
cp Resources/iphoneos.sdk/SDKSettings.plist $DIST/SDKs/JSON/iphoneos.sdk || exit 1

# Create iPhone simulator SDK
xcodebuild -target libjson -configuration Release -sdk iphonesimulator2.0 install \
    ARCHS=i386 \
    DSTROOT=$DIST/SDKs/JSON/iphonesimulator.sdk || exit 1
cp Resources/iphonesimulator.sdk/SDKSettings.plist $DIST/SDKs/JSON/iphonesimulator.sdk || exit 1


# Create the documentation
xcodebuild -target Documentation -configuration Release install DSTROOT=$DIST || exit 1
rm -rf $DIST/Documentation/html/org.brautaset.${PROJ}.docset


cat <<HTML > $DIST/API.html
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html><head><meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
<script type="text/javascript">
<!--
window.location = "Documentation/html/index.html"
//-->
</script>
</head>
<body>
<p>Aw, shucks! I tried to redirect you to the <a
href="Documentaton/html/index.html">api documentation</a> but obviously
failed. Please find it yourself. </p>
</body>
</html>
HTML

cp -p CREDITS $DIST
cp -p README $DIST
cat <<INSTALL > $DIST/INSTALL

iPhone SDK
==========

Copy the content of the 'SDKs' folder to ~/Library/SDKs. (You may have
to create that directory.)


Embedded Framework
==================

Copy the '$PROJECT.framework' bundle to ~/Library/Frameworks. (You may
have to create that directory.)

Documentation
=============

You can install the API documentation in this dmg by copying the
'Documentation/html' directory to a writable location on your
hard-drive, cd into the directory and type 'make install'.

INSTALL

hdiutil create -fs HFS+ -volname $DIST -srcfolder $DIST $DMG
