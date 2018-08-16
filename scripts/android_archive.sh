#!/bin/sh

set -e

if [ ! -d "../build" ]; then
    mkdir "../build"
fi

rm -rf "../build/android"
mkdir "../build/android"

archiveAAR()
{
    PROJECT_DIR="../android/$1"
    OUTPUT_DIR="../build/android"

    cd ${PROJECT_DIR} && ./gradlew assembleRelease && cd ../../scripts
    cp -r "${PROJECT_DIR}/$2/build/outputs/aar/$2-release.aar" "${OUTPUT_DIR}/$2.aar"
}

archiveAAR "SyncEngine" "syncEngine"
archiveAAR "HPDB" "hpdb"