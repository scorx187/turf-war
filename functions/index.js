const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// =======================================================
// 1. دالة الجرائم (مع حساب الشجاعة التلقائي والترقية Level Up)
// =======================================================
exports.commitCrime = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const uid = payload.uid;
    if (!uid) throw new functions.https.HttpsError('invalid-argument', 'رقم اللاعب مفقود');

    // 🟢 استقبلنا الحد الأقصى للشجاعة والطاقة من التطبيق عشان نعبيها وقت الترقية
    const { crimeId, crimeName, reqCourage, finalFailChance, minCash, maxCash, xp, maxCourage, maxEnergy } = payload;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const playerDoc = await transaction.get(playerRef);
        if (!playerDoc.exists) throw new functions.https.HttpsError('not-found', 'حساب اللاعب غير موجود');
        const pData = playerDoc.data();

        if (pData.isInPrison) throw new functions.https.HttpsError('failed-precondition', 'لا يمكنك تنفيذ جريمة وأنت في السجن!');

        // حساب الشجاعة اللي رجعت مع مرور الوقت
        let currentCourage = pData.courage !== undefined ? pData.courage : 100;
        if (pData.lastCourageUpdate) {
            let lastUpdate = pData.lastCourageUpdate.toDate();
            let now = new Date();
            let secondsPassed = Math.floor((now.getTime() - lastUpdate.getTime()) / 1000);
            currentCourage += Math.floor(secondsPassed / 4); // 1 شجاعة كل 4 ثواني
            let mCourage = maxCourage || 100;
            if (currentCourage > mCourage) currentCourage = mCourage;
        }

        if (currentCourage < reqCourage) {
            throw new functions.https.HttpsError('failed-precondition', 'شجاعة غير كافية!');
        }

        let updates = {
            courage: currentCourage - reqCourage,
            lastCourageUpdate: admin.firestore.FieldValue.serverTimestamp()
        };

        const isSuccess = Math.random() >= finalFailChance;
        let reward = 0, prisonMinutes = 0, bailCost = 0;

        if (isSuccess) {
            reward = Math.floor(Math.random() * (maxCash - minCash + 1)) + minCash;
            updates.cash = admin.firestore.FieldValue.increment(reward);

            // 🟢 ذكاء السيرفر: حساب الترقية (Level Up)
            let currentXP = (pData.crimeXP || 0) + xp;
            let currentLevel = pData.crimeLevel || 1;
            let nextLevelXp = Math.floor(100 * Math.pow(1.05, currentLevel - 1));

            let leveledUp = false;
            while (currentXP >= nextLevelXp) {
                currentXP -= nextLevelXp;
                currentLevel++;
                leveledUp = true;
                nextLevelXp = Math.floor(100 * Math.pow(1.05, currentLevel - 1));
            }

            updates.crimeXP = currentXP;
            if (leveledUp) {
                updates.crimeLevel = currentLevel;
                // عند الترقية نملأ الشجاعة والطاقة للحد الأقصى
                updates.courage = maxCourage || 100;
                updates.energy = maxEnergy || 100;
                updates.lastCourageUpdate = admin.firestore.FieldValue.serverTimestamp();
            }

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

// =======================================================
// 2. دالة الهروب من السجن (نسبة 50%)
// =======================================================
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

        // 🟢 تم التعديل إلى 0.5 (نسبة النجاح 50%)
        const isSuccess = Math.random() < 0.5;
        if (isSuccess) {
            updates.isInPrison = false;
            updates.prisonReleaseTime = null;
        }

        transaction.update(playerRef, updates);
        return { success: isSuccess };
    });
});

// =======================================================
// 3. استعادة الموارد (استخدام القهوة أو المنشط)
// =======================================================
exports.recoverResource = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    // 🟢 السيرفر يستقبل الماكس من اللاعب
    const { uid, type, maxCourage, maxEnergy } = payload;

    if (!uid) throw new functions.https.HttpsError('invalid-argument', 'رقم اللاعب مفقود');

    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        if (!doc.exists) throw new functions.https.HttpsError('not-found', 'اللاعب غير موجود');
        const pData = doc.data();

        const isEnergy = type === 'energy';
        const itemId = isEnergy ? 'steroids' : 'coffee';
        const cost = 50; // سعر الذهب

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
            // 🟢 تعبئة للطاقة القصوى
            updates.energy = maxEnergy || 100;
        } else {
            // 🟢 تعبئة للشجاعة القصوى
            updates.courage = maxCourage || 100;
            updates.lastCourageUpdate = admin.firestore.FieldValue.serverTimestamp();
        }

        transaction.update(playerRef, updates);
        return { success: true };
    });
});

// =======================================================
// 4. 🟢 الدالة الشاملة للمشتريات (المتجر الأسود، متجر العصابة، وغيرها)
// =======================================================
exports.buyItem = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const { uid, itemId, cost, currencyType, amount } = payload;

    if (!uid || !itemId || cost === undefined || !currencyType) {
        throw new functions.https.HttpsError('invalid-argument', 'بيانات الشراء ناقصة');
    }

    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const pDoc = await transaction.get(playerRef);
        if (!pDoc.exists) throw new functions.https.HttpsError('not-found', 'حساب اللاعب غير موجود');
        const pData = pDoc.data();

        // 1. السيرفر يتحقق من رصيد اللاعب الفعلي
        const currentBalance = pData[currencyType] || 0;
        if (currentBalance < cost) {
            throw new functions.https.HttpsError('failed-precondition', `لا تملك ${currencyType === 'gold' ? 'ذهب' : 'كاش'} كافي!`);
        }

        let updates = {};

        // 2. خصم المبلغ بشكل آمن
        updates[currencyType] = currentBalance - cost;

        // 3. إضافة العنصر إلى المخزن (Inventory)
        const currentItemCount = (pData.inventory && pData.inventory[itemId]) ? pData.inventory[itemId] : 0;
        updates[`inventory.${itemId}`] = currentItemCount + (amount || 1);

        // 4. حفظ العملية
        transaction.update(playerRef, updates);

        return { success: true, newBalance: updates[currencyType], message: 'تمت عملية الشراء بنجاح' };
    });
});

// =======================================================
// 5. 🟢 دالة عجلة الحظ (تحديد الجائزة من السيرفر وتسجيل الفائز)
// =======================================================
exports.spinLuckyWheel = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const { uid, times } = payload;

    if (!uid || !times) throw new functions.https.HttpsError('invalid-argument', 'بيانات غير مكتملة');

    const cost = times === 1 ? 500 : 4500;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);
    const winnerRef = db.collection('wheel_winners').doc();

    return db.runTransaction(async (transaction) => {
        const pDoc = await transaction.get(playerRef);
        if (!pDoc.exists) throw new functions.https.HttpsError('not-found', 'حساب اللاعب غير موجود');
        const pData = pDoc.data();

        if ((pData.gold || 0) < cost) {
            throw new functions.https.HttpsError('failed-precondition', 'لا تملك ذهب كافي!');
        }

        const prizes = [
            { id: 'gold_600', name: '600 ذهب', colorValue: 4294961152, chance: 0.20 },
            { id: 'cash_50m', name: '50 مليون', colorValue: 4284510463, chance: 0.05 },
            { id: 'cash_10m', name: '10 مليون', colorValue: 4283215696, chance: 0.25 },
            { id: 't_aladdin_lamp', name: 'المصباح السحري', colorValue: 4294956800, chance: 0.06 },
            { id: 't_aladdin_carpet', name: 'البساط الطائر', colorValue: 4292927743, chance: 0.06 },
            { id: 't_magic_ring', name: 'خاتم السلطة', colorValue: 4294940672, chance: 0.06 },
            { id: 'w_aladdin_damage', name: 'سيف الضرر', colorValue: 4294924390, chance: 0.03 },
            { id: 'a_aladdin_evasion', name: 'عباءة مراوغة', colorValue: 4280090623, chance: 0.03 },
            { id: 'a_aladdin_defense', name: 'درع دفاع', colorValue: 4280391423, chance: 0.03 },
            { id: 'w_aladdin_accuracy', name: 'خنجر الدقة', colorValue: 4294928128, chance: 0.03 },
            { id: 'vip_7', name: 'VIP أسبوع', colorValue: 4294951168, chance: 0.10 },
            { id: 'perk_point', name: 'نقطة امتياز', colorValue: 4282684159, chance: 0.10 },
        ];

        let wonPrizes = [];

        // 🟢 تجميع الغنائم أولاً (لمنع تضارب التحديثات عند الفوز بنفس الجائزة مرتين في خيار الـ 10 لفات)
        let totalCashWon = 0;
        let totalGoldWon = 0;
        let totalPerksWon = 0;
        let inventoryUpdates = {};

        for (let i = 0; i < times; i++) {
            let r = Math.random();
            let cumulative = 0;
            let selected = prizes[prizes.length - 1];
            for (let p of prizes) {
                cumulative += p.chance;
                if (r <= cumulative) {
                    selected = p;
                    break;
                }
            }
            wonPrizes.push(selected);

            if (selected.id === 'cash_10m') totalCashWon += 10000000;
            else if (selected.id === 'cash_50m') totalCashWon += 50000000;
            else if (selected.id === 'gold_600') totalGoldWon += 600;
            else if (selected.id === 'perk_point') totalPerksWon += 1;
            else {
                inventoryUpdates[selected.id] = (inventoryUpdates[selected.id] || 0) + 1;
            }
        }

        // 🟢 تجهيز التحديثات وإرسالها دفعة واحدة لحساب اللاعب
        let updates = {};
        updates.luckyWheelSpins = (pData.luckyWheelSpins || 0) + times;

        // حساب الذهب والكاش الدقيق (الرصيد الحالي - تكلفة اللفة + إجمالي الجوائز)
        updates.gold = (pData.gold || 0) - cost + totalGoldWon;
        if (totalCashWon > 0) updates.cash = (pData.cash || 0) + totalCashWon;
        if (totalPerksWon > 0) updates.bonusPerkPoints = (pData.bonusPerkPoints || 0) + totalPerksWon;

        // إضافة الأدوات للمخزن
        for (const [itemId, qty] of Object.entries(inventoryUpdates)) {
            let currentItemCount = (pData.inventory && pData.inventory[itemId]) ? pData.inventory[itemId] : 0;
            updates[`inventory.${itemId}`] = currentItemCount + qty;
        }

        transaction.update(playerRef, updates);

        // 🟢 تسجيل الفائز في السجل العام (بدون مشاكل الحماية)
        const firstPrize = wonPrizes[0];
        const safePlayerName = pData.playerName || "الزعيم";
        transaction.set(winnerRef, {
            uid: uid,
            playerName: safePlayerName,
            profilePicUrl: pData.profilePicUrl || '',
            isVIP: pData.isVIP || false,
            prizeName: firstPrize.name,
            prizeColor: firstPrize.colorValue,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        return { success: true, wonPrizes: wonPrizes };
    });
});

// =======================================================
// 6. 🟢 دالة العلاج في المستشفى
// =======================================================
exports.healPlayer = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const { uid, healType } = payload;

    if (!uid || !healType) throw new functions.https.HttpsError('invalid-argument', 'بيانات ناقصة');

    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const pDoc = await transaction.get(playerRef);
        if (!pDoc.exists) throw new functions.https.HttpsError('not-found', 'اللاعب غير موجود');
        const pData = pDoc.data();

        let maxHealth = pData.maxHealth || 100;
        let currentHealth = pData.health || 0;
        if (currentHealth >= maxHealth) throw new functions.https.HttpsError('failed-precondition', 'أنت بصحة كاملة بالفعل!');

        let missingHealth = maxHealth - currentHealth;
        let healCost = pData.isVIP ? Math.floor(missingHealth * 0.8) : missingHealth;
        let updates = { health: maxHealth };

        if (pData.isHospitalized) {
            updates.isHospitalized = false;
            updates.hospitalReleaseTime = null;
        }

        if (healType === 'cash') {
            if ((pData.cash || 0) < healCost) throw new functions.https.HttpsError('failed-precondition', 'لا تملك كاش كافي للعلاج!');
            updates.cash = admin.firestore.FieldValue.increment(-healCost);
        } else if (healType === 'vip') {
            if (!pData.isVIP) throw new functions.https.HttpsError('failed-precondition', 'هذه الميزة لـ VIP فقط!');
        } else if (healType === 'medkit') {
            const medkitCount = (pData.inventory && pData.inventory['medkit']) ? pData.inventory['medkit'] : 0;
            if (medkitCount > 0) {
                updates['inventory.medkit'] = admin.firestore.FieldValue.increment(-1);
            } else {
                if ((pData.cash || 0) < 2000) throw new functions.https.HttpsError('failed-precondition', 'لا تملك كاش لشراء حقيبة طبية!');
                updates.cash = admin.firestore.FieldValue.increment(-2000);
            }
        } else {
            throw new functions.https.HttpsError('invalid-argument', 'نوع علاج غير معروف');
        }

        transaction.update(playerRef, updates);
        return { success: true, message: 'تم العلاج بنجاح' };
    });
});

// =======================================================
// 7. 🟢 دالة الشحن الآمنة (شحن الكاش والذهب)
// =======================================================
exports.topUpBalance = functions.https.onCall(async (request) => {
    // الطريقة الآمنة لاستخراج البيانات مهما كان إصدار Firebase
    const payload = request.data || request;
    const { uid, currencyType, amount } = payload;

    // أضفنا المتغيرات في رسالة الخطأ لكي تظهر لك في التطبيق ونعرف من هو المفقود!
    if (!uid || !currencyType || !amount) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            `بيانات الشحن ناقصة! -> رقم اللاعب: ${uid}, العملة: ${currencyType}, الكمية: ${amount}`
        );
    }

    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const pDoc = await transaction.get(playerRef);
        if (!pDoc.exists) throw new functions.https.HttpsError('not-found', 'اللاعب غير موجود');

        let updates = {};
        // 🟢 إضافة المبلغ بشكل آمن ومحمي
        updates[currencyType] = admin.firestore.FieldValue.increment(amount);

        transaction.update(playerRef, updates);
        return { success: true };
    });
});

// =======================================================
// 8. 🟢 دالة الحذف الشامل للحساب (بصلاحيات السيرفر لتخطي الحماية)
// =======================================================
exports.deletePlayerAccount = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const uid = payload.uid;

    if (!uid) throw new functions.https.HttpsError('invalid-argument', 'رقم اللاعب مفقود');

    const db = admin.firestore();
    const batch = db.batch();

    try {
        // 1. مسح الإشعارات
        const notifications = await db.collection('notifications').where('uid', '==', uid).get();
        notifications.forEach(doc => batch.delete(doc.ref));

        // 2. مسح الشات العام
        const publicChats = await db.collection('chat').where('uid', '==', uid).get();
        publicChats.forEach(doc => batch.delete(doc.ref));

        // 3. مسح الشات الخاص
        const privateChats = await db.collection('private_chats').where('participants', 'array-contains', uid).get();
        privateChats.forEach(doc => batch.delete(doc.ref));

        // 4. مسح العقارات المعروضة للإيجار ولم تؤجر
        const rentedProps = await db.collection('property_rentals').where('ownerId', '==', uid).get();
        rentedProps.forEach(doc => batch.delete(doc.ref));

        // 5. مسح اللاعب من قوائم أصدقاء اللاعبين الآخرين
        const friendsArrays = await db.collection('players').where('friends', 'array-contains', uid).get();
        friendsArrays.forEach(doc => batch.update(doc.ref, { friends: admin.firestore.FieldValue.arrayRemove(uid) }));

        const reqArrays = await db.collection('players').where('friendRequests', 'array-contains', uid).get();
        reqArrays.forEach(doc => batch.update(doc.ref, { friendRequests: admin.firestore.FieldValue.arrayRemove(uid) }));

        const sentArrays = await db.collection('players').where('sentRequests', 'array-contains', uid).get();
        sentArrays.forEach(doc => batch.update(doc.ref, { sentRequests: admin.firestore.FieldValue.arrayRemove(uid) }));

        // 6. مصادرة العقارات المؤجرة للبنك المركزي حمايةً للمستأجرين
        const renters = await db.collection('players').where('activeRentedProperty.ownerId', '==', uid).get();
        renters.forEach(doc => {
            batch.update(doc.ref, {
                'activeRentedProperty.ownerName': 'البنك المركزي 🏛️',
                'activeRentedProperty.ownerId': 'bank_system'
            });
        });

        // 7. حذف بيانات اللاعب الأساسية
        batch.delete(db.collection('players').doc(uid));

        // تنفيذ الحذف الشامل في قاعدة البيانات
        await batch.commit();

        // 8. حذف حساب المصادقة (Auth) نهائياً
        try {
            await admin.auth().deleteUser(uid);
        } catch (authError) {
            console.log("حساب المصادقة غير موجود أو محذوف مسبقاً");
        }

        return { success: true, message: 'تم مسح الحساب بالكامل' };
    } catch (error) {
        console.error("خطأ أثناء حذف الحساب:", error);
        throw new functions.https.HttpsError('internal', 'فشل السيرفر في حذف الحساب');
    }
});