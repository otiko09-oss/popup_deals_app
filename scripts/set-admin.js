#!/usr/bin/env node
/**
 * One-off bootstrap script: grants isAdmin:true on a user's
 * users/{uid} Firestore document.
 *
 * This is the ONLY supported way to create the first admin account.
 * firestore.rules deliberately blocks any client (including the app
 * itself) from ever setting isAdmin on its own document — see
 * firestore.rules, match /users/{userId}. Only the Admin SDK (which
 * bypasses security rules) can do it, which is exactly what this
 * script uses.
 *
 * SETUP (one-time)
 * 1. Firebase Console -> Project settings -> Service accounts
 *    -> "Generate new private key". Save the downloaded JSON as
 *    scripts/serviceAccountKey.json (already gitignored — never commit it).
 * 2. cd scripts && npm install firebase-admin
 *
 * USAGE
 *   node scripts/set-admin.js someone@example.com
 *   node scripts/set-admin.js <firebase-auth-uid>
 *
 * You can run this again later with a different email/uid to add more
 * admins, or with --revoke to remove admin rights from an account.
 */

const admin = require("firebase-admin");
const path = require("path");

const keyPath = path.join(__dirname, "serviceAccountKey.json");

let serviceAccount;
try {
  serviceAccount = require(keyPath);
} catch (e) {
  console.error(
    "\nCouldn't find scripts/serviceAccountKey.json.\n" +
    "Download it from Firebase Console -> Project settings -> Service accounts\n" +
    "-> Generate new private key, and save it at that exact path.\n"
  );
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

async function resolveUid(identifier) {
  // Looks like an email -> resolve to a UID via Firebase Auth.
  if (identifier.includes("@")) {
    const userRecord = await admin.auth().getUserByEmail(identifier);
    return userRecord.uid;
  }
  return identifier;
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length === 0 || args[0] === "--help" || args[0] === "-h") {
    console.log(
      "\nUsage:\n" +
      "  node scripts/set-admin.js <email-or-uid>            grant admin\n" +
      "  node scripts/set-admin.js <email-or-uid> --revoke    revoke admin\n"
    );
    process.exit(args.length === 0 ? 1 : 0);
  }

  const identifier = args[0];
  const revoke = args.includes("--revoke");

  const uid = await resolveUid(identifier);
  const userRef = admin.firestore().collection("users").doc(uid);
  const snap = await userRef.get();

  if (!snap.exists) {
    console.error(
      `\nNo users/${uid} Firestore document found.\n` +
      "The person needs to have signed up in the app at least once " +
      "(so their Firestore profile exists) before you can grant admin.\n"
    );
    process.exit(1);
  }

  await userRef.update({
    isAdmin: !revoke,
    updatedAt: new Date().toISOString(),
  });

  console.log(
    `\n${revoke ? "Revoked" : "Granted"} admin ${revoke ? "from" : "to"} ` +
    `${identifier} (uid: ${uid}).\n`
  );
  process.exit(0);
}

main().catch((err) => {
  console.error("\nFailed:", err.message || err);
  process.exit(1);
});
