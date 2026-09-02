# Aghinou build preparation

Android Gradle configuration has been normalized to the modern Flutter plugin-loader layout.

## Current integrated UI build
The Carousell-style compact square-card home UI and first-run subscription introduction are configured in the APK workflow.

The workflow preserves the release signing keystore so the resulting release APK can update the existing signed installation.

## Build verification
This commit is intentionally used to trigger the release APK workflow. Do not treat an APK as verified until the workflow completes successfully and the generated artifact passes APK signature verification.
