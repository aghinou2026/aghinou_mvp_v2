# Aghinou Production Ready v4

- Live Supabase schema mismatches corrected in Flutter (`edescriptions` and `ad-images`).
- Image upload paths now match the live Storage ownership policy: `<user-id>/<ad-id>/<file>`.
- Added/verified `payments` ledger and secure `publish_ad` RPC on the live Supabase project.
- Direct client ad insertion is blocked; publishing requires an active paid subscription and enforces the 9-ad limit server-side.
- Existing Profiles, Ads and Ad Images tables were preserved.
- This release is still not an APK-tested build because Flutter/Android SDK is not installed in the current environment.
