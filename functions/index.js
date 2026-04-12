const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.commitCrime = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const uid = payload.uid;

    if (!uid) throw new functions.https.HttpsError('invalid-argument', 'رقم اللاعب مفقود');

    const { crimeId, crimeName, reqCourage, finalFailChance, minCash, maxCash, xp } = payload;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const playerDoc = await transaction.get(playerRef);
        if (!playerDoc.exists) throw new functions.https.HttpsError('not-found', 'حساب اللاعب غير موجود');
        const playerData = playerDoc.data();

        if (playerData.isInPrison) throw new functions.https.HttpsError('failed-precondition', 'لا يمكنك تنفيذ جريمة وأنت في السجن!');
        if (playerData.courage < reqCourage) throw new functions.https.HttpsError('failed-precondition', 'شجاعة غير كافية!');

        let updates = { courage: admin.firestore.FieldValue.increment(-reqCourage) };
        const isSuccess = Math.random() >= finalFailChance;

        let reward = 0, prisonMinutes = 0, bailCost = 0;

        if (isSuccess) {
            reward = Math.floor(Math.random() * (maxCash - minCash + 1)) + minCash;
            updates.cash = admin.firestore.FieldValue.increment(reward);
            updates.crimeXP = admin.firestore.FieldValue.increment(xp);
            const currentCount = (playerData.crimeSuccessCountsMap && playerData.crimeSuccessCountsMap[crimeId]) ? playerData.crimeSuccessCountsMap[crimeId] : 0;
            updates[`crimeSuccessCountsMap.${crimeId}`] = currentCount + 1;
        } else {
            updates.isInPrison = true;
            prisonMinutes = 2 + (reqCourage * 2);
            updates.prisonReleaseTime = new Date(Date.now() + prisonMinutes * 60000).toISOString();
            updates.lastCrimeName = crimeName;
            bailCost = 500 + (reqCourage * 600);
            updates.bailCost = bailCost;
        }

        transaction.update(playerRef, updates);
        return { success: isSuccess, reward: reward, prisonMinutes: prisonMinutes, bailCost: bailCost };
    });
});

// 🟢 الدالة الجديدة: الهروب من السجن عبر السيرفر لتجنب القلتشات
exports.attemptEscape = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const uid = payload.uid;

    if (!uid) throw new functions.https.HttpsError('invalid-argument', 'رقم اللاعب مفقود');

    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        if (!doc.exists) throw new functions.https.HttpsError('not-found', 'اللاعب غير موجود');
        const pData = doc.data();

        if (!pData.isInPrison) throw new functions.https.HttpsError('failed-precondition', 'أنت لست في السجن!');
        if (pData.courage < 10) throw new functions.https.HttpsError('failed-precondition', 'تحتاج 10 شجاعة للهروب');

        let updates = { courage: admin.firestore.FieldValue.increment(-10) };
        const isSuccess = Math.random() < 0.3; // نسبة النجاح 30%

        if (isSuccess) {
            updates.isInPrison = false;
            updates.prisonReleaseTime = null;
        }

        transaction.update(playerRef, updates);
        return { success: isSuccess };
    });
});