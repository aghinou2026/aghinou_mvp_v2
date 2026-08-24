# Aghinou build preparation

Android Gradle configuration has been normalized to the modern Flutter plugin-loader layout.

## Remaining requirement
The Flutter SDK path must be supplied in `android/local.properties` on the machine that builds the app.
The Gradle wrapper JAR is not bundled here because it is not present in the available source package.

This package is **build-prepared, not build-verified**. Do not treat it as a tested APK until `flutter pub get` and `flutter build apk` succeed on a machine with Flutter/Android tooling installed.
