#!/bin/bash
set -e

if ! command -v javac &> /dev/null || ! javac -version 2>&1 | grep -q "21"; then
    echo "Ensuring OpenJDK 21 is installed..."
    apt-get update && apt-get install -y openjdk-21-jdk-headless
fi

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export ANDROID_HOME=/opt/android-sdk

if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
    echo "Installing Android Commandline tools..."
    mkdir -p /opt/android-sdk/cmdline-tools
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip
    unzip -q /tmp/cmdline-tools.zip -d /opt/android-sdk/cmdline-tools
    mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest 2>/dev/null || true
    rm -f /tmp/cmdline-tools.zip
fi

if [ ! -d "/opt/gradle-8.11.1" ]; then
    echo "Installing Gradle 8.11.1..."
    wget -q https://services.gradle.org/distributions/gradle-8.11.1-bin.zip -O /tmp/gradle.zip
    unzip -q /tmp/gradle.zip -d /opt/
    rm -f /tmp/gradle.zip
fi

export PATH=$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:/opt/gradle-8.11.1/bin:$PATH

echo "Accepting licenses and installing SDK platforms..."
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager "platform-tools" "platforms;android-34" "platforms;android-35" "build-tools;34.0.0" >/dev/null 2>&1 || true

echo "sdk.dir=/opt/android-sdk" > /app/applet/android/local.properties

echo "Syncing assets to android..."
mkdir -p /app/applet/android/app/src/main/assets/public
cp -rf /app/applet/public/* /app/applet/android/app/src/main/assets/public/
mkdir -p /app/applet/dist
cp -rf /app/applet/public/* /app/applet/dist/

echo "Building APK with Gradle..."
cd /app/applet/android
/opt/gradle-8.11.1/bin/gradle assembleDebug --no-daemon -Dorg.gradle.jvmargs="-Xmx1024m -XX:+UseSerialGC" --max-workers=2

echo "Copying generated APK to output folders..."
mkdir -p /app/applet/android-apk
mkdir -p /app/applet/public/downloads
mkdir -p /app/applet/dist/downloads
cp -f /app/applet/android/app/build/outputs/apk/debug/app-debug.apk /app/applet/android-apk/altakhfeed-alsh.apk
cp -f /app/applet/android/app/build/outputs/apk/debug/app-debug.apk /app/applet/public/downloads/altakhfeed-alsh.apk
cp -f /app/applet/android/app/build/outputs/apk/debug/app-debug.apk /app/applet/dist/downloads/altakhfeed-alsh.apk

echo "SUCCESS: APK created at android-apk/altakhfeed-alsh.apk and public/downloads/altakhfeed-alsh.apk"
ls -lh /app/applet/android-apk/altakhfeed-alsh.apk
