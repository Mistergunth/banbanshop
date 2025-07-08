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
