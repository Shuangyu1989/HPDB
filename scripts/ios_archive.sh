#!/bin/sh

set -e

if [ ! -d "../build" ]; then
    mkdir "../build"
fi
rm -rf "../build/ios"
mkdir "../build/ios"

archiveFatFwk()
{
    PROJECT_DIR="../ios/$1"
    if [ -d "${PROJECT_DIR}/build" ]; then
        rm -rf "${PROJECT_DIR}/build"
    fi
    OUTPUT_DIR="../build/ios"

    xcodebuild -project "${PROJECT_DIR}/$1.xcodeproj" -target $2 -configuration Release -arch arm64 -arch armv7 only_active_arch=no defines_module=yes -sdk "iphoneos"
    xcodebuild -project "${PROJECT_DIR}/$1.xcodeproj" -target $2 -configuration Release -arch x86_64 -arch i386 only_active_arch=no defines_module=yes -sdk "iphonesimulator"

    cp -r "${PROJECT_DIR}/build/Release-iphoneos/$2.framework" "${OUTPUT_DIR}/$2.framework"
    lipo -create -output "${OUTPUT_DIR}/$2.framework/$2" "${PROJECT_DIR}/build/Release-iphoneos/$2.framework/$2" "${PROJECT_DIR}/build/Release-iphonesimulator/$2.framework/$2"
    cp -r "${PROJECT_DIR}/build/Release-iphonesimulator/$2.framework/Modules/$2.swiftmodule/" "${OUTPUT_DIR}/$2.framework/Modules/$2.swiftmodule"
}

archiveFatFwk "HPDB" "HPDB"

