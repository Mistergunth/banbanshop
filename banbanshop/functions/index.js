// The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * ฟังก์ชันที่จะทำงานทุกครั้งที่มีการเขียน (สร้าง, แก้ไข, ลบ)
 * ใน sub-collection 'reviews' ของร้านค้าใดๆ
 * โดยใช้ синтаксисของ Cloud Functions v2
 */
exports.updateStoreRating = onDocumentWritten("stores/{storeId}/reviews/{reviewId}", async (event) => {
  // ดึง storeId จากพารามิเตอร์ของ path
  const storeId = event.params.storeId;
  logger.log(`Detected a review change for store: ${storeId}`);

  // อ้างอิงไปยังเอกสารของร้านค้านั้นๆ
  const storeRef = admin.firestore().collection("stores").doc(storeId);

  // ดึงข้อมูลรีวิวทั้งหมดของร้านค้านี้
  const reviewsSnapshot = await storeRef.collection("reviews").get();

  // ถ้าไม่มีรีวิวเหลืออยู่เลย (เช่น รีวิวสุดท้ายถูกลบ)
  // ให้อัปเดตข้อมูลร้านค้าเป็น 0 แล้วจบการทำงาน
  if (reviewsSnapshot.empty) {
    logger.log(`No reviews for store ${storeId}. Setting rating to 0.`);
    return storeRef.update({
      averageRating: 0,
      reviewCount: 0,
    });
  }

  // คำนวณคะแนนรวม
  let totalRating = 0;
  reviewsSnapshot.forEach((doc) => {
    totalRating += doc.data().rating;
  });

  // จำนวนรีวิวทั้งหมด
  const reviewCount = reviewsSnapshot.size;

  // คะแนนเฉลี่ย
  const averageRating = totalRating / reviewCount;

  // อัปเดตข้อมูลในเอกสารของร้านค้า
  logger.log(
      `Updating store ${storeId}: reviewCount=${reviewCount}, ` +
      `averageRating=${averageRating.toFixed(2)}`,
  );
  return storeRef.update({
    reviewCount: reviewCount,
    averageRating: averageRating,
  });
});

// --- [NEW] Cloud Functions for Custom Claims ---

/**
 * ฟังก์ชันที่จะทำงานเมื่อมีการสร้างเอกสารใหม่ใน collection 'buyers'
 * เพื่อกำหนด Custom Claim 'role: buyer' ให้กับผู้ใช้งาน Firebase Auth
 */
exports.addRoleOnBuyerCreate = onDocumentWritten("buyers/{userId}", async (event) => {
  // ตรวจสอบว่าเป็นการสร้างเอกสารใหม่เท่านั้น (ไม่ใช่การอัปเดตหรือลบ)
  if (!event.data.before.exists && event.data.after.exists) {
    const userId = event.params.userId;
    logger.log(`Detected new buyer document for user: ${userId}. Setting custom claim 'role: buyer'.`);
    try {
      await admin.auth().setCustomUserClaims(userId, { role: 'buyers' }); // ตั้งค่า role เป็น 'buyers'
      logger.log(`Custom claim 'role: buyers' set successfully for user ${userId}.`);
    } catch (error) {
      logger.error(`Error setting custom claim for buyer ${userId}:`, error);
    }
  }
  return null;
});

/**
 * ฟังก์ชันที่จะทำงานเมื่อมีการสร้างเอกสารใหม่ใน collection 'sellers'
 * เพื่อกำหนด Custom Claim 'role: seller' ให้กับผู้ใช้งาน Firebase Auth
 */
exports.addRoleOnSellerCreate = onDocumentWritten("sellers/{userId}", async (event) => {
  // ตรวจสอบว่าเป็นการสร้างเอกสารใหม่เท่านั้น (ไม่ใช่การอัปเดตหรือลบ)
  if (!event.data.before.exists && event.data.after.exists) {
    const userId = event.params.userId;
    logger.log(`Detected new seller document for user: ${userId}. Setting custom claim 'role: seller'.`);
    try {
      await admin.auth().setCustomUserClaims(userId, { role: 'sellers' }); // ตั้งค่า role เป็น 'sellers'
      logger.log(`Custom claim 'role: sellers' set successfully for user ${userId}.`);
    } catch (error) {
      logger.error(`Error setting custom claim for seller ${userId}:`, error);
    }
  }
  return null;
});
