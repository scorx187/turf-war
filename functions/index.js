const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// =======================================================
// 1. دالة الجرائم (مع حماية التراكم ونظام الألقاب عند الختم)
// =======================================================
exports.commitCrime = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const uid = payload.uid;
    if (!uid) throw new functions.https.HttpsError('invalid-argument', 'رقم اللاعب مفقود');

    const { crimeId, crimeName, reqCourage, finalFailChance, minCash, maxCash, xp, maxCourage, maxEnergy } = payload;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const playerDoc = await transaction.get(playerRef);
        if (!playerDoc.exists) throw new functions.https.HttpsError('not-found', 'حساب اللاعب غير موجود');
        const pData = playerDoc.data();

        if (pData.isInPrison) throw new functions.https.HttpsError('failed-precondition', 'لا يمكنك تنفيذ جريمة وأنت في السجن!');

        let currentCourage = pData.courage !== undefined ? pData.courage : 30;
        let mCourage = maxCourage || 30;

        if (pData.lastCourageUpdate && currentCourage < mCourage) {
            let lastUpdate = pData.lastCourageUpdate.toDate ? pData.lastCourageUpdate.toDate() : new Date(pData.lastCourageUpdate);
            let now = new Date();
            let secondsPassed = Math.floor((now.getTime() - lastUpdate.getTime()) / 1000);
            let regenerated = Math.floor(secondsPassed / 4);
            if (regenerated > 0) {
                currentCourage += regenerated;
                if (currentCourage > mCourage) currentCourage = mCourage;
            }
        }

        if (currentCourage < reqCourage) {
            throw new functions.https.HttpsError('failed-precondition', 'شجاعة غير كافية!');
        }

        let newCourage = currentCourage - reqCourage;
        let updates = {
            courage: newCourage
        };

        if (newCourage < mCourage) {
            updates.lastCourageUpdate = admin.firestore.FieldValue.serverTimestamp();
        }

        const isSuccess = Math.random() >= finalFailChance;
        let reward = 0, prisonMinutes = 0, bailCost = 0;
        let droppedGold = 0;
        let droppedEnergy = 0;
        let earnedTitle = null; // 🟢 متغير اللقب الجديد

        if (isSuccess) {
            reward = Math.floor(Math.random() * (maxCash - minCash + 1)) + minCash;
            updates.cash = admin.firestore.FieldValue.increment(reward);

            let currentEnergy = pData.energy !== undefined ? pData.energy : 100;
            let mEnergy = maxEnergy || 100;
            let energyChanged = false;

            if (pData.lastEnergyUpdate && currentEnergy < mEnergy) {
                let lastUpdateE = pData.lastEnergyUpdate.toDate ? pData.lastEnergyUpdate.toDate() : new Date(pData.lastEnergyUpdate);
                let nowE = new Date();
                let secondsPassedE = Math.floor((nowE.getTime() - lastUpdateE.getTime()) / 1000);
                let regenerated = Math.floor(secondsPassedE / 8);
                if (regenerated > 0) {
                    currentEnergy += regenerated;
                    if (currentEnergy > mEnergy) currentEnergy = mEnergy;
                    energyChanged = true;
                }
            }

            if (Math.random() < 0.10) {
                droppedGold = Math.floor(Math.random() * 5) + 1;
                updates.gold = admin.firestore.FieldValue.increment(droppedGold);
            }

            if (Math.random() < 0.15) {
                droppedEnergy = Math.floor(Math.random() * 11) + 5;
                updates.energy = currentEnergy + droppedEnergy;
            } else if (energyChanged) {
                updates.energy = currentEnergy;
            }

            let currentXP = (pData.crimeXP || 0) + xp;
            let currentLevel = pData.crimeLevel || 1;
            let nextLevelXp = Math.floor(250 * Math.pow(1.06, currentLevel - 1));

            let leveledUp = false;
            while (currentXP >= nextLevelXp) {
                currentXP -= nextLevelXp;
                currentLevel++;
                leveledUp = true;
                nextLevelXp = Math.floor(250 * Math.pow(1.06, currentLevel - 1));
            }

            updates.crimeXP = currentXP;
            if (leveledUp) {
                updates.crimeLevel = currentLevel;
                let newMaxCourage = (pData.isVIP ? 60 : 29) + currentLevel;
                updates.courage = Math.max(newCourage, newMaxCourage);
                updates.energy = Math.max(currentEnergy + droppedEnergy, maxEnergy || 100);
                updates.lastCourageUpdate = admin.firestore.FieldValue.serverTimestamp();
            }

            // 🟢 نظام الختم (الـ 3 نجوم) والألقاب
            const currentCount = (pData.crimeSuccessCountsMap && pData.crimeSuccessCountsMap[crimeId]) ? pData.crimeSuccessCountsMap[crimeId] : 0;
            const newCount = currentCount + 1;
            updates[`crimeSuccessCountsMap.${crimeId}`] = newCount;

            if (newCount === 500) {
                earnedTitle = `أسطورة ${crimeName}`;
                updates.titles = admin.firestore.FieldValue.arrayUnion(earnedTitle);
            }

        } else {
            updates.isInPrison = true;
            prisonMinutes = 2 + (reqCourage * 2);
            updates.prisonReleaseTime = new Date(Date.now() + prisonMinutes * 60000).toISOString();
            updates.lastCrimeName = crimeName;
            bailCost = 500 + (reqCourage * 600);
            updates.bailCost = bailCost;
        }

        transaction.update(playerRef, updates);

        return {
            success: isSuccess,
            reward: reward,
            prisonMinutes: prisonMinutes,
            bailCost: bailCost,
            droppedGold: droppedGold,
            droppedEnergy: droppedEnergy,
            earnedTitle: earnedTitle // 🟢 نرسل اللقب لواجهة الجوال
        };
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

        // 🟢 تم التعديل إلى 30 هنا
        let currentCourage = pData.courage !== undefined ? pData.courage : 30;
        let lastUpdate = pData.lastCourageUpdate ? pData.lastCourageUpdate.toDate() : new Date();
        let now = new Date();
        let secondsPassed = Math.floor((now.getTime() - lastUpdate.getTime()) / 1000);
        let gainedCourage = Math.floor(secondsPassed / 4);
        currentCourage += gainedCourage;

        // 🟢 تم إضافة الحد الأقصى الديناميكي للشجاعة
        let pLevel = pData.crimeLevel || 1;
        let mCourage = (pData.isVIP ? 60 : 29) + pLevel;
        if (currentCourage > mCourage) currentCourage = mCourage;

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
            updates.courage = maxCourage || 30; // الاحتياط في حالة لم يرسل التطبيق الماكس
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
// 5. 🟢 دالة عجلة الحظ (تحديد الجائزة وخصم التكلفة فقط للحفاظ على المتعة)
// =======================================================
exports.spinLuckyWheel = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const { uid, times } = payload;

    if (!uid || !times) throw new functions.https.HttpsError('invalid-argument', 'بيانات غير مكتملة');

    const cost = times === 1 ? 500 : 4500;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

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
        }

        // 🟢 خصم التكلفة فوراً ليرى اللاعب أن رصيده نقص، لكن نخزن الجوائز كـ "معلقة"
        let currentPending = pData.pendingWheelPrizes || [];
        transaction.update(playerRef, {
            gold: pData.gold - cost,
            pendingWheelPrizes: currentPending.concat(wonPrizes)
        });

        return { success: true, wonPrizes: wonPrizes };
    });
});

// =======================================================
// 6. 🟢 دالة استلام جوائز العجلة (تُستدعى بعد وقوف العجلة)
// =======================================================
exports.claimLuckyWheel = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const { uid } = payload;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const pDoc = await transaction.get(playerRef);
        if (!pDoc.exists) return { success: false };
        const pData = pDoc.data();

        if (!pData.pendingWheelPrizes || pData.pendingWheelPrizes.length === 0) {
            return { success: true };
        }

        const wonPrizes = pData.pendingWheelPrizes;
        let updates = {};
        let spinsCount = (pData.luckyWheelSpins || 0) + wonPrizes.length;
        updates.luckyWheelSpins = spinsCount;

        // 🟢 تطبيق وإضافة الجوائز الآن
        for (let selected of wonPrizes) {
            if (selected.id === 'cash_10m') updates.cash = admin.firestore.FieldValue.increment(10000000);
            else if (selected.id === 'cash_50m') updates.cash = admin.firestore.FieldValue.increment(50000000);
            else if (selected.id === 'gold_600') updates.gold = (updates.gold !== undefined ? updates.gold : pData.gold) + 600;
            else if (selected.id === 'perk_point') updates.bonusPerkPoints = admin.firestore.FieldValue.increment(1);
            else {
                let currentItemCount = (pData.inventory && pData.inventory[selected.id]) ? pData.inventory[selected.id] : 0;
                updates[`inventory.${selected.id}`] = currentItemCount + 1;
            }
        }

        // إزالة الجوائز من قائمة "المعلقة" بعد استلامها
        updates.pendingWheelPrizes = admin.firestore.FieldValue.delete();
        transaction.update(playerRef, updates);

        // 🟢 نشر الأسماء في شريط الفائزين الآن فقط لتظهر في اللحظة المناسبة
        const safePlayerName = pData.playerName || "الزعيم";
        const isVip = pData.isVIP || false;
        const profilePicUrl = pData.profilePicUrl || '';

        for (let prize of wonPrizes) {
            const currentWinnerRef = db.collection('wheel_winners').doc();
            transaction.set(currentWinnerRef, {
                uid: uid,
                playerName: safePlayerName,
                profilePicUrl: profilePicUrl,
                isVIP: isVip,
                prizeName: prize.name,
                prizeColor: prize.colorValue,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });
        }

        return { success: true };
    });
});

// =======================================================
// 7. 🟢 دالة العلاج في المستشفى
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
// 8. 🟢 دالة الشحن الآمنة (شحن الكاش والذهب)
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
// 9. 🟢 دالة الحذف الشامل للحساب (بصلاحيات السيرفر لتخطي الحماية)
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

// =======================================================
// 10. 🟢 دالة شراء العقارات (آمنة عبر السيرفر)
// =======================================================
exports.buyRealEstate = functions.https.onCall(async (request) => {
    const { uid, propertyId, price, happinessGain } = request.data || request;
    if (!uid || !propertyId || price === undefined) throw new functions.https.HttpsError('invalid-argument', 'بيانات ناقصة');

    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const pDoc = await transaction.get(playerRef);
        if (!pDoc.exists) throw new functions.https.HttpsError('not-found', 'اللاعب غير موجود');
        const pData = pDoc.data();

        if ((pData.cash || 0) < price) throw new functions.https.HttpsError('failed-precondition', 'كاش غير كافي!');
        if ((pData.ownedProperties || []).includes(propertyId)) throw new functions.https.HttpsError('failed-precondition', 'أنت تملك هذا العقار مسبقاً!');

        let updates = {
            cash: pData.cash - price,
            ownedProperties: admin.firestore.FieldValue.arrayUnion(propertyId)
        };

        // تفعيل السكن تلقائياً إذا لم يكن لديه سكن
        if (!pData.activePropertyId && !pData.activeRentedProperty) {
            updates.activePropertyId = propertyId;
            updates.happiness = happinessGain || 0;
        }

        // تسجيل العملية في كشف الحساب
        let newTx = { title: "شراء عقار", amount: price, date: new Date().toISOString(), isPositive: false };
        let currentTxs = pData.transactions || [];
        currentTxs.unshift(newTx);
        if (currentTxs.length > 20) currentTxs.pop();
        updates.transactions = currentTxs;

        transaction.update(playerRef, updates);
        return { success: true };
    });
});

// =======================================================
// 11. 🟢 دالة إدارة المشاريع التجارية (شراء وترقية)
// =======================================================
exports.manageBusiness = functions.https.onCall(async (request) => {
    const { uid, businessId, cost, actionType } = request.data || request;
    if (!uid || !businessId || cost === undefined) throw new functions.https.HttpsError('invalid-argument', 'بيانات ناقصة');

    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const pDoc = await transaction.get(playerRef);
        const pData = pDoc.data();

        if ((pData.cash || 0) < cost) throw new functions.https.HttpsError('failed-precondition', 'كاش غير كافي!');

        let updates = { cash: pData.cash - cost };
        let ownedBiz = pData.ownedBusinesses || {};

        if (actionType === 'buy') {
            if (ownedBiz[businessId]) throw new functions.https.HttpsError('failed-precondition', 'تملك المشروع مسبقاً!');
            updates[`ownedBusinesses.${businessId}`] = 1;
        } else if (actionType === 'upgrade') {
            if (!ownedBiz[businessId]) throw new functions.https.HttpsError('failed-precondition', 'لا تملك هذا المشروع للترقية!');
            updates[`ownedBusinesses.${businessId}`] = ownedBiz[businessId] + 1;
        }

        let newTx = { title: actionType === 'buy' ? "شراء مشروع تجاري" : "ترقية مشروع تجاري", amount: cost, date: new Date().toISOString(), isPositive: false };
        let currentTxs = pData.transactions || [];
        currentTxs.unshift(newTx);
        if (currentTxs.length > 20) currentTxs.pop();
        updates.transactions = currentTxs;

        transaction.update(playerRef, updates);
        return { success: true };
    });
});

// =======================================================
// 12. 🟢 دوال سوق الإيجارات (عرض، استئجار، إلغاء)
// =======================================================
exports.listPropertyForRent = functions.https.onCall(async (request) => {
    const { uid, propertyId, dailyPrice, days, playerName } = request.data || request;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);
    const listingRef = db.collection('property_rentals').doc(`${uid}_${propertyId}`);

    return db.runTransaction(async (transaction) => {
        const pDoc = await transaction.get(playerRef);
        const pData = pDoc.data();

        let updates = { listedProperties: admin.firestore.FieldValue.arrayUnion(propertyId) };
        if (pData.activePropertyId === propertyId) {
            updates.activePropertyId = null;
            updates.happiness = 0;
        }

        transaction.update(playerRef, updates);
        transaction.set(listingRef, {
            ownerId: uid, ownerName: playerName || 'مجهول', propertyId: propertyId,
            dailyPrice: dailyPrice, days: days, timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
        return { success: true };
    });
});

exports.cancelRentalListing = functions.https.onCall(async (request) => {
    const { uid, propertyId } = request.data || request;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);
    const listingRef = db.collection('property_rentals').doc(`${uid}_${propertyId}`);

    return db.runTransaction(async (transaction) => {
        transaction.update(playerRef, { listedProperties: admin.firestore.FieldValue.arrayRemove(propertyId) });
        transaction.delete(listingRef);
        return { success: true };
    });
});

exports.rentPropertyFromMarket = functions.https.onCall(async (request) => {
    const { uid, listingId, ownerId, propertyId, dailyPrice, days, happinessGain, renterName } = request.data || request;
    const db = admin.firestore();

    const listingRef = db.collection('property_rentals').doc(listingId);
    const ownerRef = db.collection('players').doc(ownerId);
    const meRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const listingSnap = await transaction.get(listingRef);
        if (!listingSnap.exists) throw new functions.https.HttpsError('failed-precondition', 'العقار لم يعد متاحاً!');

        const listingData = listingSnap.data();
        const totalPrice = listingData.dailyPrice * listingData.days;

        const meSnap = await transaction.get(meRef);
        const meData = meSnap.data();

        if ((meData.cash || 0) < totalPrice) throw new functions.https.HttpsError('failed-precondition', 'كاش غير كافي للاستئجار!');
        if (meData.activeRentedProperty) throw new functions.https.HttpsError('failed-precondition', 'أنت مستأجر عقاراً حالياً!');

        let expireDate = new Date();
        expireDate.setDate(expireDate.getDate() + listingData.days);

        // تحديث المستأجر (خصم الفلوس وإضافة السكن)
        let meUpdates = {
            cash: meData.cash - totalPrice,
            activeRentedProperty: { id: listingData.propertyId, expire: expireDate.toISOString(), ownerId: listingData.ownerId, ownerName: listingData.ownerName },
            activePropertyId: listingData.propertyId,
            happiness: happinessGain || 0
        };

        let newTx = { title: "استئجار عقار", amount: totalPrice, date: new Date().toISOString(), isPositive: false };
        let currentTxs = meData.transactions || [];
        currentTxs.unshift(newTx);
        if (currentTxs.length > 20) currentTxs.pop();
        meUpdates.transactions = currentTxs;

        transaction.update(meRef, meUpdates);

        // تحديث المالك (إعطاؤه الفلوس)
        const ownerSnap = await transaction.get(ownerRef);
        if (ownerSnap.exists) {
            const ownerData = ownerSnap.data();
            transaction.update(ownerRef, {
                cash: (ownerData.cash || 0) + totalPrice,
                listedProperties: admin.firestore.FieldValue.arrayRemove(listingData.propertyId),
                [`rentedOutProperties.${listingData.propertyId}`]: { expire: expireDate.toISOString(), renterId: uid, renterName: renterName || 'لاعب' }
            });
        }

        transaction.delete(listingRef);
        return { success: true, days: listingData.days };
    });
});

exports.cancelRentedProperty = functions.https.onCall(async (request) => {
    const { uid } = request.data || request;
    const db = admin.firestore();
    const meRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const meSnap = await transaction.get(meRef);
        const meData = meSnap.data();

        if (!meData.activeRentedProperty) throw new functions.https.HttpsError('failed-precondition', 'لست مستأجراً!');
        const propId = meData.activeRentedProperty.id;
        const ownerId = meData.activeRentedProperty.ownerId;

        let updates = { activeRentedProperty: admin.firestore.FieldValue.delete() };
        if (meData.activePropertyId === propId) { updates.activePropertyId = null; updates.happiness = 0; }

        if (ownerId && ownerId !== 'bank_system') {
            const ownerRef = db.collection('players').doc(ownerId);
            transaction.update(ownerRef, { [`rentedOutProperties.${propId}`]: admin.firestore.FieldValue.delete() });
        }

        transaction.update(meRef, updates);
        return { success: true };
    });
});

// =======================================================
// 13. 🟢 دوال البنك (Bank)
// =======================================================
exports.depositToBank = functions.https.onCall(async (request) => {
    const { uid, amount } = request.data || request;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();
        if ((data.cash || 0) < amount) throw new functions.https.HttpsError('failed-precondition', 'كاش غير كافي');

        transaction.update(playerRef, {
            cash: data.cash - amount,
            bankBalance: (data.bankBalance || 0) + amount
        });
        return { success: true };
    });
});

exports.withdrawFromBank = functions.https.onCall(async (request) => {
    const { uid, amount } = request.data || request;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();
        if ((data.bankBalance || 0) < amount) throw new functions.https.HttpsError('failed-precondition', 'رصيد بنكي غير كافي');

        transaction.update(playerRef, {
            bankBalance: data.bankBalance - amount,
            cash: (data.cash || 0) + amount
        });
        return { success: true };
    });
});

exports.buyGold = functions.https.onCall(async (request) => {
    const { uid, amount, price } = request.data || request;
    const totalCost = amount * price;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();
        if ((data.cash || 0) < totalCost) throw new functions.https.HttpsError('failed-precondition', 'كاش غير كافي');

        transaction.update(playerRef, {
            cash: data.cash - totalCost,
            gold: (data.gold || 0) + amount
        });
        return { success: true };
    });
});

exports.sellGold = functions.https.onCall(async (request) => {
    const { uid, amount, price } = request.data || request;
    const totalGain = amount * price;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();
        if ((data.gold || 0) < amount) throw new functions.https.HttpsError('failed-precondition', 'ذهب غير كافي');

        transaction.update(playerRef, {
            gold: data.gold - amount,
            cash: (data.cash || 0) + totalGain
        });
        return { success: true };
    });
});

exports.takeLoan = functions.https.onCall(async (request) => {
    const { uid, amount } = request.data || request;
    const netReceive = amount - Math.floor(amount * 0.05); // خصم 5% رسوم إدارية
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();
        let maxLoan = data.maxLoanLimit || 50000;
        let currentLoan = data.loanAmount || 0;

        if (currentLoan + amount > maxLoan) throw new functions.https.HttpsError('failed-precondition', 'تجاوزت الحد المسموح للقروض');

        transaction.update(playerRef, {
            loanAmount: currentLoan + amount,
            cash: (data.cash || 0) + netReceive,
            loanTime: admin.firestore.FieldValue.serverTimestamp()
        });
        return { success: true };
    });
});

exports.repayLoan = functions.https.onCall(async (request) => {
    const { uid, amount } = request.data || request;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();

        if ((data.cash || 0) < amount) throw new functions.https.HttpsError('failed-precondition', 'كاش غير كافي للسداد');

        let newLoan = (data.loanAmount || 0) - amount;
        if (newLoan < 0) newLoan = 0;

        transaction.update(playerRef, {
            cash: data.cash - amount,
            loanAmount: newLoan,
            creditScore: (data.creditScore || 0) + 10 // مكافأة السداد
        });
        return { success: true };
    });
});

exports.startLockedInvestment = functions.https.onCall(async (request) => {
    const { uid, amount, minutes, rate } = request.data || request;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();

        if ((data.cash || 0) < amount) throw new functions.https.HttpsError('failed-precondition', 'كاش غير كافي للاستثمار');
        if (data.isInvestmentLocked) throw new functions.https.HttpsError('failed-precondition', 'لديك استثمار نشط بالفعل');

        let expireDate = new Date(Date.now() + minutes * 60000);

        transaction.update(playerRef, {
            cash: data.cash - amount,
            isInvestmentLocked: true,
            lockedBalance: amount,
            lockedProfits: Math.floor(amount * rate),
            lockedUntil: expireDate.toISOString()
        });
        return { success: true };
    });
});

// =======================================================
// 14. 🟢 دوال صالة التدريب (Gym)
// =======================================================
exports.trainMultipleStats = functions.https.onCall(async (request) => {
    // 🟢 السيرفر يستقبل الماكس إنرجي من التطبيق ليعرف هل هو VIP (200) أو عادي (100)
    const { uid, strE, defE, skillE, spdE, maxEnergy } = request.data || request;
    const totalEnergyUsed = strE + defE + skillE + spdE;
    if (totalEnergyUsed <= 0) throw new functions.https.HttpsError('invalid-argument', 'يجب تحديد طاقة للتدريب');

    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();

        // 🟢 1. حساب الطاقة الحقيقية بدقة (مع دعم وحماية التراكم Overcharge)
        let currentEnergy = data.energy !== undefined ? data.energy : 100;
        let mEnergy = maxEnergy || 100;

        // لا نحسب الاسترجاع الزمني أبداً إذا كانت الطاقة أعلى من أو تساوي الماكس
        if (data.lastEnergyUpdate && currentEnergy < mEnergy) {
            // حماية الكراش (toDate)
            let lastUpdate = data.lastEnergyUpdate.toDate ? data.lastEnergyUpdate.toDate() : new Date(data.lastEnergyUpdate);
            let now = new Date();
            let secondsPassed = Math.floor((now.getTime() - lastUpdate.getTime()) / 1000);

            let gainedEnergy = Math.floor(secondsPassed / 8);
            if (gainedEnergy > 0) {
                currentEnergy += gainedEnergy;
                if (currentEnergy > mEnergy) currentEnergy = mEnergy;
            }
        }

        // 🟢 2. هل الطاقة تكفي للتدريب؟
        if (currentEnergy < totalEnergyUsed) {
            throw new functions.https.HttpsError('failed-precondition', 'طاقة غير كافية للتدريب المطلوب');
        }

        let baseMultiplier = 0.1;
        let happiness = data.happiness || 0;
        let gainFactor = baseMultiplier * (1 + (happiness / 100)); // مكافأة السعادة

        // هل المنشط شغال؟
        if (data.activeSteroidEndTime && new Date(data.activeSteroidEndTime) > new Date()) {
            gainFactor *= 2; // يضاعف النتائج
        }

        let strGain = strE * gainFactor;
        let defGain = defE * gainFactor;
        let skillGain = skillE * gainFactor;
        let spdGain = spdE * gainFactor;

        // هل المدرب شغال؟
        if (data.activeCoach === 'russian') strGain *= 1.5;
        if (data.activeCoach === 'tactical') defGain *= 1.5;
        if (data.activeCoach === 'ninja') { skillGain *= 1.5; spdGain *= 1.5; }

        let totalGained = strGain + defGain + skillGain + spdGain;
        let newEnergy = currentEnergy - totalEnergyUsed;

        let updates = {
            energy: newEnergy,
            strength: (data.strength || 5) + strGain,
            defense: (data.defense || 5) + defGain,
            skill: (data.skill || 5) + skillGain,
            speed: (data.speed || 5) + spdGain,
        };

        // 🟢 3. تصفير العداد فقط إذا نزلت الطاقة عن الحد الأقصى
        // (لكي لا نخرب التراكم لو كانت طاقته 150 واستخدم 10 فصارت 140)
        if (newEnergy < mEnergy) {
            updates.lastEnergyUpdate = admin.firestore.FieldValue.serverTimestamp();
        }

        transaction.update(playerRef, updates);

        return { success: true, gained: parseFloat(totalGained.toFixed(2)) };
    });
});

exports.hireCoach = functions.https.onCall(async (request) => {
    const { uid, coachId, price } = request.data || request;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();

        if ((data.cash || 0) < price) throw new functions.https.HttpsError('failed-precondition', 'كاش غير كافي');
        if (data.activeCoach) throw new functions.https.HttpsError('failed-precondition', 'لديك مدرب حالي');

        let endTime = new Date(Date.now() + 30 * 60000); // 30 دقيقة
        let cooldownTime = new Date(Date.now() + 6 * 3600000); // 6 ساعات راحة

        transaction.update(playerRef, {
            cash: data.cash - price,
            activeCoach: coachId,
            coachEndTime: endTime.toISOString(),
            'inventory.coach_cooldown': cooldownTime.getTime()
        });
        return { success: true };
    });
});

exports.buyAndUseSteroids = functions.https.onCall(async (request) => {
    const { uid, price } = request.data || request;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();

        if ((data.cash || 0) < price) throw new functions.https.HttpsError('failed-precondition', 'كاش غير كافي');
        if (data.activeSteroidEndTime && new Date(data.activeSteroidEndTime) > new Date()) {
            throw new functions.https.HttpsError('failed-precondition', 'مفعول المنشط لا زال سارياً!');
        }

        let endTime = new Date(Date.now() + 20 * 60000); // 20 دقيقة
        let cooldownTime = new Date(Date.now() + 6 * 3600000); // 6 ساعات راحة

        transaction.update(playerRef, {
            cash: data.cash - price,
            activeSteroidEndTime: endTime.toISOString(),
            'inventory.steroid_cooldown': cooldownTime.getTime()
        });
        return { success: true };
    });
});

// =======================================================
// 15. 🟢 دوال السجن (Prison) - دفع الكفالة
// =======================================================
exports.bailOutPlayer = functions.https.onCall(async (request) => {
    const { uid, targetUid, bailCost } = request.data || request;
    const db = admin.firestore();

    const payerRef = db.collection('players').doc(uid);
    const targetRef = db.collection('players').doc(targetUid);

    return db.runTransaction(async (transaction) => {
        const payerDoc = await transaction.get(payerRef);
        const targetDoc = await transaction.get(targetRef);

        if (!payerDoc.exists || !targetDoc.exists) throw new functions.https.HttpsError('not-found', 'حساب اللاعب غير موجود');
        const payerData = payerDoc.data();

        if ((payerData.cash || 0) < bailCost) throw new functions.https.HttpsError('failed-precondition', 'لا تملك كاش كافي لدفع الكفالة!');

        // خصم الفلوس من الدافع
        transaction.update(payerRef, {
            cash: payerData.cash - bailCost
        });

        // إخراج المستهدف من السجن
        transaction.update(targetRef, {
            isInPrison: false,
            prisonReleaseTime: null
        });

        return { success: true };
    });
});

// =======================================================
// 16. 🟢 دوال التشليح والورشة (Chop Shop)
// =======================================================
exports.startChoppingCar = functions.https.onCall(async (request) => {
    const { uid } = request.data || request;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();

        let stolenCars = (data.inventory && data.inventory['stolen_car']) ? data.inventory['stolen_car'] : 0;
        if (stolenCars <= 0) throw new functions.https.HttpsError('failed-precondition', 'لا يوجد سيارات في المخزن');
        if (data.isChopping) throw new functions.https.HttpsError('failed-precondition', 'هناك سيارة قيد التفكيك بالفعل');

        let endTime = new Date(Date.now() + 30 * 60000); // 30 دقيقة

        transaction.update(playerRef, {
            'inventory.stolen_car': stolenCars - 1,
            isChopping: true,
            chopShopEndTime: endTime.toISOString()
        });
        return { success: true };
    });
});

exports.collectChoppedCar = functions.https.onCall(async (request) => {
    const { uid } = request.data || request;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();

        if (!data.isChopping) throw new functions.https.HttpsError('failed-precondition', 'لا يوجد سيارة تم تفكيكها');
        if (new Date(data.chopShopEndTime) > new Date()) throw new functions.https.HttpsError('failed-precondition', 'التفكيك لم ينتهِ بعد');

        transaction.update(playerRef, {
            isChopping: false,
            chopShopEndTime: null,
            cash: (data.cash || 0) + 15000 // 15 ألف كاش كأرباح ثابتة
        });
        return { success: true };
    });
});

// =======================================================
// 17. 🟢 دوال المخزن (استخدام الأدوات)
// =======================================================
exports.consumeItem = functions.https.onCall(async (request) => {
    const { uid, itemId } = request.data || request;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();

        let inventory = data.inventory || {};
        if ((inventory[itemId] || 0) <= 0) {
            throw new functions.https.HttpsError('failed-precondition', 'لا تملك هذا العنصر في المخزن!');
        }

        let updates = {};
        // 1. خصم العنصر من المخزن
        updates[`inventory.${itemId}`] = inventory[itemId] - 1;

        // 2. 🟢 حساب القيم القصوى بشكل دقيق للـ VIP والمستوى
        let isVip = (data.vipUntil && new Date(data.vipUntil) > new Date());
        let maxEnergy = isVip ? 200 : 100;
        let currentLevel = data.crimeLevel || 1;
        let maxCourage = (isVip ? 60 : 29) + currentLevel; // تم حل مشكلة الـ 200 هنا
        let maxHealth = data.maxHealth || 100;

        // 3. تطبيق تأثير العنصر
        if (itemId === 'steroids') updates.energy = maxEnergy;
        else if (itemId === 'coffee') updates.courage = maxCourage;
        else if (itemId === 'medkit') updates.health = maxHealth;
        else if (itemId === 'bandage') updates.health = Math.min(maxHealth, (data.health || 0) + Math.floor(maxHealth * 0.25));
        else if (itemId === 'bribe_small') updates.heat = Math.max(0, (data.heat || 0) - 20);
        else if (itemId === 'fake_plates') updates.heat = Math.max(0, (data.heat || 0) - 40);
        else if (itemId === 'bribe_big') updates.heat = 0;
        else if (itemId === 'smoke_bomb') {
            if (!data.isInPrison) throw new functions.https.HttpsError('failed-precondition', 'لا يمكنك استخدامها إلا داخل السجن!');
            updates.isInPrison = false;
            updates.prisonReleaseTime = null;
        } else if (itemId === 'vip_7') {
            let currentVip = (data.vipUntil && new Date(data.vipUntil) > new Date()) ? new Date(data.vipUntil) : new Date();
            currentVip.setDate(currentVip.getDate() + 7);
            updates.vipUntil = currentVip.toISOString();
            updates.totalVipDays = (data.totalVipDays || 0) + 7;
        } else {
            throw new functions.https.HttpsError('invalid-argument', 'هذا العنصر غير قابل للاستهلاك المباشر.');
        }

        // 4. حفظ التحديثات في السيرفر
        transaction.update(playerRef, updates);
        return { success: true };
    });
});