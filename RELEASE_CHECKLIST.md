# Production release checklist

- [x] iOS bundle ID finalized: `com.popupdeals.app` (matches Android's
  `com.popupdeals.app`). `ios/Runner/GoogleService-Info.plist` is in place
  (it existed under a misnamed copy, `GoogleService-Info (1).plist`, and was
  never picked up by Xcode) and the Google Sign-In URL scheme is registered
  in `Info.plist`. `lib/firebase_options.dart` already matches both IDs.
- [ ] Set `MAPS_API_KEY` in `android/local.properties`; restrict it to
  `com.popupdeals.app` and the release signing certificate.
  `android/local.properties` is a per-machine file (now correctly
  git-ignored) — each dev/build machine needs its own with this key set.
- [ ] Store Stripe credentials outside git (`functions/.env.example` lists
  every required name), create the Stripe products/prices, and register the
  deployed webhook for checkout and subscription lifecycle events. Enable the
  Stripe Billing Portal and configure its cancellation, payment-method and
  invoice settings before deployment; the app's “Manage billing” button opens
  that portal for paid businesses.
- [ ] Deploy rules, indexes, Storage rules and functions together:
  `firebase deploy --only firestore:rules,firestore:indexes,storage,functions`.
- [x] Admin bootstrap script added: `scripts/set-admin.js` (see the header
  in that file for setup — needs a Firebase service account key, which is
  never committed). Mobile clients still can never write `isAdmin`
  themselves; only this script / Firebase Console can.
- [ ] Confirm Android/iOS notification credentials and send a real
  foreground and background test notification to a registered device.
- [ ] Build and test signed Android App Bundle and iOS archive on real
  devices. Android needs a real `key.properties` + keystore (not in this
  repo — generate your own, see Flutter's official signing guide).

## Note on Firebase config files

`android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`
were previously committed to git despite being listed in `.gitignore`
(the ignore rule only stops *future* commits, not files already tracked).
Both are now untracked — they still exist on your local checkout, but won't
be pushed going forward. If you ever need a clean copy, redownload from
Firebase Console -> Project settings -> Your apps.
