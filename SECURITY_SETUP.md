# Firebase Security Setup

The app uses Firebase Authentication and Firestore Security Rules. The Flutter UI is not an authorization boundary.

## 1. Enable sign-in providers

In Firebase Console for project `ccm-melodies`:

1. Open **Authentication > Sign-in method**.
2. Enable **Anonymous** for member access.
3. Enable **Email/Password** for administrators.
4. Create one Firebase Auth user per administrator. Do not put those credentials in the app or source control.

## 2. Give administrators a custom claim

The `admin` claim must be assigned from a trusted environment using the Firebase Admin SDK. Never assign it from Flutter.

Example Node.js script, run only from a secure administrator machine or server:

```js
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const uid = 'FIREBASE_AUTH_USER_UID';
admin.auth().setCustomUserClaims(uid, { admin: true })
  .then(() => console.log('Admin claim assigned'))
  .catch(console.error);
```

After the claim is assigned, the administrator must sign out and sign in again so Firebase refreshes the ID token.

## 3. Deploy Firestore rules

Install and authenticate the Firebase CLI, select project `ccm-melodies`, then run:

```text
firebase use ccm-melodies
firebase deploy --only firestore:rules
```

The rules in `firestore.rules` enforce:

- Signed-in members can read songs, services, and daily bread.
- Members can read only setlists where `published` is `true`.
- Only users with the `admin: true` custom claim can create, update, publish, hide, or delete content.
- All unspecified collections and operations are denied.

## 4. Verify before release

Test with two separate Firebase Auth accounts:

- Member account: can read published setlists, cannot write any collection, and cannot read hidden setlists.
- Admin account: can create, update, publish, hide, and delete content.
- Signed-out client: cannot read protected Firestore data.

Use the Firebase Emulator Suite or the Rules Playground before deploying rules to production.
