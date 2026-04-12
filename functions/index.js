const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// 1. دالة الجرائم (مع حساب الشجاعة التلقائي)
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
        const pData = playerDoc.data();

        if (pData.isInPrison) throw new functions.https.HttpsError('failed-precondition', 'لا يمكنك تنفيذ جريمة وأنت في السجن!');

        // 🟢 ذكاء السيرفر: حساب الشجاعة اللي رجعت مع مرور الوقت
        let currentCourage = pData.courage !== undefined ? pData.courage : 100;
        let lastUpdate = pData.lastCourageUpdate ? pData.lastCourageUpdate.toDate() : new Date();
        let now = new Date();
        let secondsPassed = Math.floor((now.getTime() - lastUpdate.getTime()) / 1000);

        let gainedCourage = Math.floor(secondsPassed / 4); // 1 شجاعة كل 4 ثواني
        currentCourage += gainedCourage;
        if (currentCourage > 100) currentCourage = 100;

        if (currentCourage < reqCourage) {
            throw new functions.https.HttpsError('failed-precondition', 'شجاعة غير كافية!');
        }

        // خصم الشجاعة وتحديث وقت آخر عملية
        let updates = {
            courage: currentCourage - reqCourage,
            lastCourageUpdate: admin.firestore.FieldValue.serverTimestamp()
        };

        const isSuccess = Math.random() >= finalFailChance;
        let reward = 0, prisonMinutes = 0, bailCost = 0;

        if (isSuccess) {
            reward = Math.floor(Math.random() * (maxCash - minCash + 1)) + minCash;
            updates.cash = admin.firestore.FieldValue.increment(reward);
            updates.crimeXP = admin.firestore.FieldValue.increment(xp);
            const currentCount = (pData.crimeSuccessCountsMap && pData.crimeSuccessCountsMap[crimeId]) ? pData.crimeSuccessCountsMap[crimeId] : 0;
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

// 2. دالة الهروب من السجن
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

        let currentCourage = pData.courage !== undefined ? pData.courage : 100;
        let lastUpdate = pData.lastCourageUpdate ? pData.lastCourageUpdate.toDate() : new Date();
        let now = new Date();
        let secondsPassed = Math.floor((now.getTime() - lastUpdate.getTime()) / 1000);
        let gainedCourage = Math.floor(secondsPassed / 4);
        currentCourage += gainedCourage;
        if (currentCourage > 100) currentCourage = 100;

        if (currentCourage < 10) throw new functions.https.HttpsError('failed-precondition', 'تحتاج 10 شجاعة للهروب');

        let updates = {
            courage: currentCourage - 10,
            lastCourageUpdate: admin.firestore.FieldValue.serverTimestamp()
        };

        const isSuccess = Math.random() < 0.3;
        if (isSuccess) {
            updates.isInPrison = false;
            updates.prisonReleaseTime = null;
        }

        transaction.update(playerRef, updates);
        return { success: isSuccess };
    });
});

// 3. 🟢 الدالة الجديدة: استعادة الموارد (استخدام القهوة أو الدفع بالذهب)
exports.recoverResource = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const uid = payload.uid;
    const type = payload.type;

    if (!uid) throw new functions.https.HttpsError('invalid-argument', 'رقم اللاعب مفقود');

    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        if (!doc.exists) throw new functions.https.HttpsError('not-found', 'اللاعب غير موجود');
        const pData = doc.data();

        const isEnergy = type === 'energy';
        const itemId = isEnergy ? 'steroids' : 'coffee';
        const cost = 50;

        let updates = {};
        const ownedCount = (pData.inventory && pData.inventory[itemId]) ? pData.inventory[itemId] : 0;

        if (ownedCount > 0) {
            updates[`inventory.${itemId}`] = admin.firestore.FieldValue.increment(-1);
        } else {
            if ((pData.gold || 0) < cost) {
                throw new functions.https.HttpsError('failed-precondition', 'لا تملك ذهب كافي!');
            }
            updates.gold = admin.firestore.FieldValue.increment(-cost);
        }

        if (isEnergy) {
            updates.energy = 100;
        } else {
            updates.courage = 100;
            updates.lastCourageUpdate = admin.firestore.FieldValue.serverTimestamp();
        }

        transaction.update(playerRef, updates);
        return { success: true };
    });
});