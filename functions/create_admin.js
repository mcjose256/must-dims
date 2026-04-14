const admin = require("firebase-admin");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "dims-must";
process.env.GOOGLE_CLOUD_PROJECT =
  process.env.GOOGLE_CLOUD_PROJECT || "dims-must";

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: "dims-must",
  });
}

const db = admin.firestore();

async function main() {
  const [, , email, password, ...displayNameParts] = process.argv;
  const displayName = displayNameParts.join(" ").trim();

  if (!email || !password || !displayName) {
    console.error('Usage: node create_admin.js <email> <password> "<Display Name>"');
    process.exit(1);
  }

  const existing = await admin
    .auth()
    .getUserByEmail(email)
    .catch(() => null);

  if (existing) {
    console.error(`A Firebase Auth user with email ${email} already exists.`);
    process.exit(1);
  }

  const userRecord = await admin.auth().createUser({
    email,
    password,
    displayName,
  });

  await db.collection("users").doc(userRecord.uid).set({
    uid: userRecord.uid,
    email,
    displayName,
    role: "admin",
    isApproved: true,
    phoneNumber: "",
    photoUrl: "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log("Admin created successfully.");
  console.log(`UID: ${userRecord.uid}`);
  console.log(`Email: ${email}`);
}

main().catch((error) => {
  console.error("Failed to create admin:", error);
  process.exit(1);
});
