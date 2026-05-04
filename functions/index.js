const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// 🟢 1. دالة حساب الصحة الأساسية (تدرج من 1 إلى 100 بطيء ثم تسارع للوصول لـ 73 مليون في 500)
function getBaseHealthForLevel(level) {
    if (level <= 100) {
        return 100 * Math.pow(1.06, level - 1);
    } else {
        let hpAt100 = 100 * Math.pow(1.06, 99);
        return hpAt100 * Math.pow(1.0194488, level - 100);
    }
}

// 🟢 2. دالة حساب الصحة النهائية (تدمج الصحة الأساسية مع تدريب النادي والمعدات والبيركس)
function getFinalMaxHealth(pData, currentBaseMaxHealth) {
    let baseHp = currentBaseMaxHealth || pData.maxHealth || 100;
    let hp = baseHp;

    let perks = pData.perks || {};
    if (perks['max_hp_boost']) {
        hp += hp * (perks['max_hp_boost'] * 0.02);
    }
    if (pData.equippedSpecialId === 't_golden_apple') {
        hp += baseHp * 0.10;
    }
    if (pData.equippedSpecialId === 't_phoenix_feather') {
        hp += baseHp * 0.05;
    }
    return Math.floor(hp);
}

// 🟢 3. محطات الإحصائيات في صالة التدريب - يجب أن تطابق kStatMilestones في lib/providers/player_stats_logic.dart
const STAT_MILESTONES = [
    5, 10, 15, 20, 25, 30, 35, 40, 45,
    55, 70, 85, 105,
    130, 160, 195, 235, 280,
    330, 385, 445, 500
];

// 🟢 4. دالة حساب اللفل الفعال في النادي (أعلى محطة وصلها اللاعب فعلياً)
function getEffectiveGymLevel(crimeLevel) {
    let lvl = crimeLevel > 500 ? 500 : crimeLevel;
    let reached = 1;
    for (const m of STAT_MILESTONES) {
        if (lvl >= m) reached = m;
        else break;
    }
    return reached;
}

// =======================================================
// 1. دالة الجرائم
// =======================================================
exports.commitCrime = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const uid = payload.uid;
    if (!uid) throw new functions.https.HttpsError('invalid-argument', 'رقم اللاعب مفقود');

    // 🟢 استقبلنا minXp و maxXp بدلاً من xp الثابت
    const { crimeId, crimeName, reqCourage, finalFailChance, minCash, maxCash, minXp, maxXp, maxCourage, maxEnergy } = payload;
    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const playerDoc = await transaction.get(playerRef);
        if (!playerDoc.exists) throw new functions.https.HttpsError('not-found', 'حساب اللاعب غير موجود');
        const pData = playerDoc.data();

        if (pData.isInPrison) throw new functions.https.HttpsError('failed-precondition', 'لا يمكنك تنفيذ جريمة وأنت في السجن!');

        let isVip = (pData.vipUntil && new Date(pData.vipUntil) > new Date());

        let currentCourage = pData.courage !== undefined ? pData.courage : 30;
        let mCourage = maxCourage || 30;

        if (pData.lastCourageUpdate && currentCourage < mCourage) {
            let lastUpdate = pData.lastCourageUpdate.toDate ? pData.lastCourageUpdate.toDate() : new Date(pData.lastCourageUpdate);
            let now = new Date();
            let secondsPassed = Math.floor((now.getTime() - lastUpdate.getTime()) / 1000);

            let regenerated = Math.floor(secondsPassed / 36);
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
        let earnedTitle = null;
        let earnedXp = 0; // 🟢 متغير لحفظ الخبرة المكتسبة

        if (isSuccess) {
            reward = Math.floor(Math.random() * (maxCash - minCash + 1)) + minCash;
            updates.cash = admin.firestore.FieldValue.increment(reward);

            // 🟢 حساب الخبرة العشوائية بين المين والماكس
            let safeMinXp = minXp || 15;
            let safeMaxXp = maxXp || 30;
            earnedXp = Math.floor(Math.random() * (safeMaxXp - safeMinXp + 1)) + safeMinXp;

            let currentEnergy = pData.energy !== undefined ? pData.energy : 100;
            let mEnergy = maxEnergy || 100;
            let energyChanged = false;

            let energyInterval = isVip ? 9 : 18;

            if (pData.lastEnergyUpdate && currentEnergy < mEnergy) {
                let lastUpdateE = pData.lastEnergyUpdate.toDate ? pData.lastEnergyUpdate.toDate() : new Date(pData.lastEnergyUpdate);
                let nowE = new Date();
                let secondsPassedE = Math.floor((nowE.getTime() - lastUpdateE.getTime()) / 1000);

                let regenerated = Math.floor(secondsPassedE / energyInterval);
                if (regenerated > 0) {
                    currentEnergy += regenerated;
                    if (currentEnergy > mEnergy) currentEnergy = mEnergy;
                    energyChanged = true;
                }
            }

            let goldDropChance = Math.min(reqCourage * 0.002, 0.10);
            let energyDropChance = Math.min(reqCourage * 0.0025, 0.12);

            let catMatch = crimeId.match(/cat_(\d+)/);
            let catIndex = catMatch ? parseInt(catMatch[1]) : 0;
            let maxLevelForLoot = (catIndex + 1) * 35;

            let currentLevelForPenalty = pData.crimeLevel || 1;
            let isOverleveled = currentLevelForPenalty > maxLevelForLoot;

            let finalGoldChance = isOverleveled ? 0 : goldDropChance;
            let finalEnergyChance = isOverleveled ? 0 : energyDropChance;

            if (finalGoldChance > 0 && Math.random() < finalGoldChance) {
                let maxGoldDrop = Math.floor(reqCourage / 15) + 1;
                droppedGold = Math.floor(Math.random() * maxGoldDrop) + 1;
                updates.gold = admin.firestore.FieldValue.increment(droppedGold);
            }

            if (finalEnergyChance > 0 && Math.random() < finalEnergyChance) {
                droppedEnergy = Math.floor(Math.random() * 11) + 5;
                updates.energy = currentEnergy + droppedEnergy;
            } else if (energyChanged) {
                updates.energy = currentEnergy;
            }

            // 🟢 استخدام الخبرة العشوائية التي تم حسابها
            let currentXP = (pData.crimeXP || 0) + earnedXp;
            let currentLevel = pData.crimeLevel || 1;
            let nextLevelXp = Math.floor(250 * Math.pow(1.02, currentLevel - 1));

            let leveledUp = false;
            while (currentXP >= nextLevelXp && currentLevel < 500) {
                currentXP -= nextLevelXp;
                currentLevel++;
                leveledUp = true;
                nextLevelXp = Math.floor(250 * Math.pow(1.02, currentLevel - 1));
            }

            updates.crimeXP = currentXP;
            if (leveledUp) {
                let oldBase = getBaseHealthForLevel(pData.crimeLevel || 1);
                let newBase = getBaseHealthForLevel(currentLevel);
                let healthDifference = Math.floor(newBase - oldBase);

                let currentMaxHealth = pData.maxHealth || 100;
                let newMaxHealth = currentMaxHealth + healthDifference;

                if (newMaxHealth < Math.floor(newBase)) {
                    newMaxHealth = Math.floor(newBase);
                }

                if (newMaxHealth > 100000000) newMaxHealth = 100000000;

                updates.crimeLevel = currentLevel;
                let newMaxCourage = 29 + currentLevel + (isVip ? 50 : 0);

                updates.courage = Math.max(newCourage, newMaxCourage);
                updates.energy = Math.max(currentEnergy + droppedEnergy, maxEnergy || 100);
                updates.lastCourageUpdate = admin.firestore.FieldValue.serverTimestamp();

                updates.maxHealth = newMaxHealth;
                updates.health = getFinalMaxHealth(pData, newMaxHealth);
            }

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
            earnedXp: earnedXp, // 🟢 إرجاع الخبرة العشوائية للواجهة
            prisonMinutes: prisonMinutes,
            bailCost: bailCost,
            droppedGold: droppedGold,
            droppedEnergy: droppedEnergy,
            earnedTitle: earnedTitle
        };
    });
});

// =======================================================
// 2. دالة الهروب من السجن
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

        let currentCourage = pData.courage !== undefined ? pData.courage : 30;
        let lastUpdate = pData.lastCourageUpdate ? pData.lastCourageUpdate.toDate() : new Date();
        let now = new Date();
        let secondsPassed = Math.floor((now.getTime() - lastUpdate.getTime()) / 1000);

        // 🟢 تعديل الشجاعة: نقطة كل 36 ثانية
        let gainedCourage = Math.floor(secondsPassed / 36);
        currentCourage += gainedCourage;

        let pLevel = pData.crimeLevel || 1;
        let isVip = (pData.vipUntil && new Date(pData.vipUntil) > new Date());
        let mCourage = 29 + pLevel + (isVip ? 50 : 0);
        if (currentCourage > mCourage) currentCourage = mCourage;

        if (currentCourage < 10) throw new functions.https.HttpsError('failed-precondition', 'تحتاج 10 شجاعة للهروب');

        let updates = {
            courage: currentCourage - 10,
            lastCourageUpdate: admin.firestore.FieldValue.serverTimestamp()
        };

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
// 3. استعادة الموارد
// =======================================================
exports.recoverResource = functions.https.onCall(async (request) => {
    const payload = request.data || request;
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
            updates.energy = maxEnergy || 100;
        } else {
            updates.courage = maxCourage || 30;
            updates.lastCourageUpdate = admin.firestore.FieldValue.serverTimestamp();
        }

        transaction.update(playerRef, updates);
        return { success: true };
    });
});

// =======================================================
// 4. الدالة الشاملة للمشتريات
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

        const currentBalance = pData[currencyType] || 0;
        if (currentBalance < cost) {
            throw new functions.https.HttpsError('failed-precondition', `لا تملك ${currencyType === 'gold' ? 'ذهب' : 'كاش'} كافي!`);
        }

        let updates = {};
        updates[currencyType] = currentBalance - cost;

        const currentItemCount = (pData.inventory && pData.inventory[itemId]) ? pData.inventory[itemId] : 0;
        updates[`inventory.${itemId}`] = currentItemCount + (amount || 1);

        transaction.update(playerRef, updates);

        return { success: true, newBalance: updates[currencyType], message: 'تمت عملية الشراء بنجاح' };
    });
});

// =======================================================
// 5. دالة عجلة الحظ
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

        let currentPending = pData.pendingWheelPrizes || [];
        transaction.update(playerRef, {
            gold: pData.gold - cost,
            pendingWheelPrizes: currentPending.concat(wonPrizes)
        });

        return { success: true, wonPrizes: wonPrizes };
    });
});

// =======================================================
// 6. دالة استلام جوائز العجلة
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

        updates.pendingWheelPrizes = admin.firestore.FieldValue.delete();
        transaction.update(playerRef, updates);

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
// 7. دالة العلاج في المستشفى
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

        let maxHealth = getFinalMaxHealth(pData, pData.maxHealth);
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
// 8. دالة الشحن الآمنة
// =======================================================
exports.topUpBalance = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const { uid, currencyType, amount } = payload;

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
        updates[currencyType] = admin.firestore.FieldValue.increment(amount);

        transaction.update(playerRef, updates);
        return { success: true };
    });
});

// =======================================================
// 9. دالة الحذف الشامل للحساب
// =======================================================
exports.deletePlayerAccount = functions.https.onCall(async (request) => {
    const payload = request.data || request;
    const uid = payload.uid;

    if (!uid) throw new functions.https.HttpsError('invalid-argument', 'رقم اللاعب مفقود');

    const db = admin.firestore();
    const batch = db.batch();

    try {
        const notifications = await db.collection('notifications').where('uid', '==', uid).get();
        notifications.forEach(doc => batch.delete(doc.ref));

        const publicChats = await db.collection('chat').where('uid', '==', uid).get();
        publicChats.forEach(doc => batch.delete(doc.ref));

        const privateChats = await db.collection('private_chats').where('participants', 'array-contains', uid).get();
        privateChats.forEach(doc => batch.delete(doc.ref));

        const rentedProps = await db.collection('property_rentals').where('ownerId', '==', uid).get();
        rentedProps.forEach(doc => batch.delete(doc.ref));

        const friendsArrays = await db.collection('players').where('friends', 'array-contains', uid).get();
        friendsArrays.forEach(doc => batch.update(doc.ref, { friends: admin.firestore.FieldValue.arrayRemove(uid) }));

        const reqArrays = await db.collection('players').where('friendRequests', 'array-contains', uid).get();
        reqArrays.forEach(doc => batch.update(doc.ref, { friendRequests: admin.firestore.FieldValue.arrayRemove(uid) }));

        const sentArrays = await db.collection('players').where('sentRequests', 'array-contains', uid).get();
        sentArrays.forEach(doc => batch.update(doc.ref, { sentRequests: admin.firestore.FieldValue.arrayRemove(uid) }));

        const renters = await db.collection('players').where('activeRentedProperty.ownerId', '==', uid).get();
        renters.forEach(doc => {
            batch.update(doc.ref, {
                'activeRentedProperty.ownerName': 'البنك المركزي 🏛️',
                'activeRentedProperty.ownerId': 'bank_system'
            });
        });

        batch.delete(db.collection('players').doc(uid));

        await batch.commit();

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
// 10. دالة شراء العقارات
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

        if (!pData.activePropertyId && !pData.activeRentedProperty) {
            updates.activePropertyId = propertyId;
            updates.happiness = happinessGain || 0;
        }

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
// 11. دالة إدارة المشاريع التجارية
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
// 12. دوال سوق الإيجارات
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
// 13. دوال البنك (Bank)
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
    const netReceive = amount - Math.floor(amount * 0.05);
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
            creditScore: (data.creditScore || 0) + 10
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
// 14. دوال صالة التدريب (Gym)
// =======================================================
exports.trainMultipleStats = functions.https.onCall(async (request) => {
    const { uid, strE, defE, skillE, spdE, maxEnergy } = request.data || request;
    const totalEnergyUsed = strE + defE + skillE + spdE;
    if (totalEnergyUsed <= 0) throw new functions.https.HttpsError('invalid-argument', 'يجب تحديد طاقة للتدريب');

    const db = admin.firestore();
    const playerRef = db.collection('players').doc(uid);

    return db.runTransaction(async (transaction) => {
        const doc = await transaction.get(playerRef);
        const data = doc.data();

        let currentEnergy = data.energy !== undefined ? data.energy : 100;
        let mEnergy = maxEnergy || 100;

        let isVip = (data.vipUntil && new Date(data.vipUntil) > new Date());
        let energyInterval = isVip ? 9 : 18;

        if (data.lastEnergyUpdate && currentEnergy < mEnergy) {
            let lastUpdate = data.lastEnergyUpdate.toDate ? data.lastEnergyUpdate.toDate() : new Date(data.lastEnergyUpdate);
            let now = new Date();
            let secondsPassed = Math.floor((now.getTime() - lastUpdate.getTime()) / 1000);

            let gainedEnergy = Math.floor(secondsPassed / energyInterval);
            if (gainedEnergy > 0) {
                currentEnergy += gainedEnergy;
                if (currentEnergy > mEnergy) currentEnergy = mEnergy;
            }
        }

        if (currentEnergy < totalEnergyUsed) {
            throw new functions.https.HttpsError('failed-precondition', 'طاقة غير كافية للتدريب المطلوب');
        }

        // 🟢 1. حساب الحد الأقصى بنظام المحطات (يفتح عند 5, 10, 15... ثم فجوات تكبر تدريجياً حتى 500)
        let crimeLevel = data.crimeLevel || 1;
        let effectiveLevel = getEffectiveGymLevel(crimeLevel);

        // حساب السقف بناءً على المحطة الحالية
        let maxGymStats = 100.0 + (effectiveLevel * 50.0) + (Math.pow(effectiveLevel, 2) * 2.0);
        let currentBaseStats = (data.strength || 5) + (data.defense || 5) + (data.skill || 5) + (data.speed || 5);

        // 🟢 2. التحقق من الوصول للحد الأقصى ومنع التدريب
        if (currentBaseStats >= maxGymStats) {
            throw new functions.https.HttpsError('failed-precondition', 'الحد_الأقصى');
        }

        let baseMultiplier = 0.1;
        let happiness = data.happiness || 0;
        let gainFactor = baseMultiplier * (1 + (happiness / 100));

        if (data.activeSteroidEndTime && new Date(data.activeSteroidEndTime) > new Date()) {
            gainFactor *= 2;
        }

        let strGain = strE * gainFactor;
        let defGain = defE * gainFactor;
        let skillGain = skillE * gainFactor;
        let spdGain = spdE * gainFactor;

        if (data.activeCoach === 'russian') strGain *= 1.5;
        if (data.activeCoach === 'tactical') defGain *= 1.5;
        if (data.activeCoach === 'ninja') { skillGain *= 1.5; spdGain *= 1.5; }

        let totalGained = strGain + defGain + skillGain + spdGain;

        let availableRoom = maxGymStats - currentBaseStats;
        let actualEnergyUsed = totalEnergyUsed;
        let refundedEnergy = 0;

        // 🟢 إذا تعدينا الحد، نقلص الفايدة ونسترجع الطاقة
        if (totalGained > availableRoom) {
            let scale = availableRoom / totalGained;
            strGain *= scale;
            defGain *= scale;
            skillGain *= scale;
            spdGain *= scale;
            totalGained = availableRoom;

            // حساب الطاقة اللي احتاجها فعلياً واسترجاع الباقي
            actualEnergyUsed = Math.ceil(totalEnergyUsed * scale);
            if (actualEnergyUsed === 0 && availableRoom > 0) actualEnergyUsed = 1;
            refundedEnergy = totalEnergyUsed - actualEnergyUsed;
        }

        let newEnergy = currentEnergy - actualEnergyUsed;

        let updates = {
            energy: newEnergy,
            strength: (data.strength || 5) + strGain,
            defense: (data.defense || 5) + defGain,
            skill: (data.skill || 5) + skillGain,
            speed: (data.speed || 5) + spdGain,
        };

        if (defGain > 0) {
            let hpBoostChance = (data.activeCoach === 'tactical') ? 15.0 : 8.0;
            let randomMultiplier = hpBoostChance + (Math.random() * 7.0);
            let hpBoost = Math.floor(defGain * randomMultiplier);

            if (hpBoost > 0) {
                let currentMaxHealth = data.maxHealth || 100;
                let newMaxHealth = currentMaxHealth + hpBoost;

                if (newMaxHealth > 100000000) newMaxHealth = 100000000;

                updates.maxHealth = newMaxHealth;
                updates.health = getFinalMaxHealth(data, newMaxHealth);
            }
        }

        if (newEnergy < mEnergy) {
            updates.lastEnergyUpdate = admin.firestore.FieldValue.serverTimestamp();
        }

        transaction.update(playerRef, updates);

        // 🟢 السيرفر يرسل كم طاقة تم استرجاعها للواجهة
        return { success: true, gained: parseFloat(totalGained.toFixed(2)), refunded: refundedEnergy };
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

        let endTime = new Date(Date.now() + 30 * 60000);
        let cooldownTime = new Date(Date.now() + 6 * 3600000);

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

        let endTime = new Date(Date.now() + 20 * 60000);
        let cooldownTime = new Date(Date.now() + 6 * 3600000);

        transaction.update(playerRef, {
            cash: data.cash - price,
            activeSteroidEndTime: endTime.toISOString(),
            'inventory.steroid_cooldown': cooldownTime.getTime()
        });
        return { success: true };
    });
});

// =======================================================
// 15. دوال السجن (Prison) - دفع الكفالة
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

        transaction.update(payerRef, {
            cash: payerData.cash - bailCost
        });

        transaction.update(targetRef, {
            isInPrison: false,
            prisonReleaseTime: null
        });

        return { success: true };
    });
});

// =======================================================
// 16. دوال التشليح والورشة (Chop Shop)
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

        let endTime = new Date(Date.now() + 30 * 60000);

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
            cash: (data.cash || 0) + 15000
        });
        return { success: true };
    });
});

// =======================================================
// 17. المخزن (استخدام الأدوات وقراءة الصحة المحدثة)
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
        updates[`inventory.${itemId}`] = inventory[itemId] - 1;

        let isVip = (data.vipUntil && new Date(data.vipUntil) > new Date());
        let maxEnergy = isVip ? 200 : 100;
        let currentLevel = data.crimeLevel || 1;
        let maxCourage = 29 + currentLevel + (isVip ? 50 : 0);

        let maxHealth = getFinalMaxHealth(data, data.maxHealth);

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

        transaction.update(playerRef, updates);
        return { success: true };
    });
});

// =======================================================
// نظام الفعاليات التلقائي (يشتغل كل يوم الساعة 12:00 ص) - الجيل الثاني V2
// =======================================================
const { onSchedule } = require("firebase-functions/v2/scheduler");

exports.autoCrimeEvent = onSchedule({
    schedule: "every day 00:00",
    timeZone: "Asia/Riyadh" // توقيت السعودية
}, async (event) => {
    const db = admin.firestore();
    // 🟢 المسار الجديد والصحيح اللي اتفقنا عليه
    const eventRef = db.collection('events').doc('active_events');

    const today = new Date();
    const currentDate = today.getDate();
    const lastDayOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate();

    let newMultiplier = 1.0;
    if (currentDate === 15 || currentDate === lastDayOfMonth) {
        newMultiplier = 2.0;
        console.log(`🎉 يوم مميز! تم تشغيل الفعالية لأن اليوم هو ${currentDate}. المضاعف: 2.0`);
    } else {
        newMultiplier = 1.0;
        console.log(`📅 يوم عادي. اليوم هو ${currentDate}. المضاعف: 1.0`);
    }

    // تحديث المضاعف
    await eventRef.set({ crimeMultiplier: newMultiplier }, { merge: true });
    return null;
});