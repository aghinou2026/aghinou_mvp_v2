# Aghinou integrated final build

This build combines the requested UI and functional fixes on top of the Build 110/112 baseline:

- Carousell-inspired modern Persian layout.
- 3x3 home category grid with colorful category tiles.
- Dedicated category pages showing only that category's subcategories.
- Square, more compact listing cards with publication age and photo count.
- Persistent Supabase session resume so returning users do not re-enter the phone number when the session is still valid.
- Light / dark / device theme selection persisted locally.
- Searchable city selector for posting ads.
- Current GPS location capture plus map preview/navigation on ad details when coordinates are saved.
- Vehicle posting fields arranged in a two-column layout.
- Posting limit remains 9 ads; browsing/search remains free; posting is gated by the 35,000-toman monthly subscription state.
- Release signing keystore remains preserved for updating the existing installation.

The release APK must not be considered final until CI completes successfully and APK signature verification passes.
