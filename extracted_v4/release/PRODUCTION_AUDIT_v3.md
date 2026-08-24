# Aghinou Production Ready v3 - Audit

## Code changes completed
- Email OTP authentication flow in Flutter.
- Removed Anonymous Sign-In from the login path.
- Server payment function rejects anonymous users.
- Payment function supports CORS for Flutter Web.
- Subscription renewal uses the user's latest active paid expiry.
- Ads and Ad Images RLS explicitly enabled.
- Own-ad update/delete policies added.
- Payment table client writes revoked.
- Image cleanup after failed publication is compatible with ownership policies.
- Ad list loads and displays first image when available.

## Still requires real environment validation
- Enable/configure Email OTP and email delivery in Supabase.
- Apply `supabase/Aghinou_PRODUCTION_HARDENING.sql` to the real project.
- Deploy the Edge Function and set its secrets.
- Test a real payment end-to-end.
- Run Flutter analyze/test/build on a Flutter SDK environment.
- Configure Android release signing.
- Deploy Web to `aghinou.ir` and verify the Enamad seal.
