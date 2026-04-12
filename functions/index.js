const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.commitCrime = functions.https.onCall(async (data, context) => {
    // 🟢 التعديل هنا: نأخذ الـ uid من التطبيق مباشرة بدلاً من نظام Auth
    const uid = data.uid;

    if (!uid) {
        throw new functions.https.HttpsError('invalid-argument', 'رقم اللاعب مفقود');
    }

    // استلام البيانات من جهاز اللاعب
    const { crimeId, crimeName, reqCourage, finalFailChance, minCash, maxCash, xp } = data;

    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    // 2. استخدام Transaction لمنع النقر المزدوج (Auto-clickers) وتأمين البيانات
    return db.runTransaction(async (transaction) => {
        const playerDoc = await transaction.get(playerRef);
        if (!playerDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'حساب اللاعب غير موجود');
        }

        const playerData = playerDoc.data();

        // 3. التحقق من السيرفر: هل اللاعب يحاول الغش؟
        if (playerData.isInPrison) {
            throw new functions.https.HttpsError('failed-precondition', 'لا يمكنك تنفيذ جريمة وأنت في السجن!');
        }
        if (playerData.courage < reqCourage) {
            throw new functions.https.HttpsError('failed-precondition', 'شجاعة غير كافية، محاولة غش مرفوضة!');
        }

        // 4. السيرفر هو من يخصم الشجاعة فوراً وبشكل قاطع
        let updates = {
            courage: admin.firestore.FieldValue.increment(-reqCourage)
        };

        // 5. رمي النرد العشوائي (RNG) في السيرفر بعيداً عن برامج الهاكرز
        const isSuccess = Math.random() >= finalFailChance;

        let reward = 0;
        let prisonMinutes = 0;
        let bailCost = 0;

        if (isSuccess) {
            // توليد المكافأة العشوائية
            reward = Math.floor(Math.random() * (maxCash - minCash + 1)) + minCash;

            // إضافة الفلوس والخبرة
            updates.cash = admin.firestore.FieldValue.increment(reward);
            updates.crimeXP = admin.firestore.FieldValue.increment(xp);

            const currentCount = (playerData.crimeSuccessCountsMap && playerData.crimeSuccessCountsMap[crimeId]) ? playerData.crimeSuccessCountsMap[crimeId] : 0;
            updates[`crimeSuccessCountsMap.${crimeId}`] = currentCount + 1;

        } else {
            // إدخال السجن وتحديد الوقت والتكلفة
            updates.isInPrison = true;
            prisonMinutes = 2 + (reqCourage * 2);
            updates.prisonReleaseTime = new Date(Date.now() + prisonMinutes * 60000).toISOString();
            updates.lastCrimeName = crimeName;
            bailCost = 500 + (reqCourage * 600);
            updates.bailCost = bailCost;
        }

        // 6. حفظ التحديثات في قاعدة البيانات
        transaction.update(playerRef, updates);

        // 7. إرجاع النتيجة
        return { 
            success: isSuccess, 
            reward: reward, 
            prisonMinutes: prisonMinutes, 
            bailCost: bailCost 
        };
    });
});