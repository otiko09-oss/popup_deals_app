# Production release checklist

- Set `MAPS_API_KEY` in `android/local.properties`; restrict it to
  `com.popupdeals.app` and the release signing certificate.
- Run `flutterfire configure` after finalizing the Android package and iOS
  bundle ID. Do not ship until `lib/firebase_options.dart` matches both IDs.
- Store Stripe credentials outside git (`functions/.env.example` lists every
  required name), create the Stripe products/prices, and register the deployed
  webhook for checkout and subscription lifecycle events.
- Deploy rules, indexes, Storage rules and functions together:
  `firebase deploy --only firestore:rules,firestore:indexes,storage,functions`.
- Bootstrap the first administrator from a trusted Admin SDK script or Firebase
  Console; mobile clients must never write `isAdmin`.
- Confirm Android/iOS notification credentials and send a real foreground and
  background test notification to a registered device.
- Build and test signed Android App Bundle and iOS archive on real devices.
