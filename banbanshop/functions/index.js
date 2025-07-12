// File: functions/index.js
// --- [ฉบับแก้ไขสมบูรณ์] ---

const functions = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// --- โค้ดเดิมของคุณ (ไม่เปลี่ยนแปลง) ---
exports.updateStoreRating = onDocumentWritten({
    document: "stores/{storeId}/reviews/{reviewId}",
    region: "us-central1"
}, async (event) => {
  const storeId = event.params.storeId;
  logger.log(`Detected a review change for store: ${storeId}`);
  const storeRef = admin.firestore().collection("stores").doc(storeId);
  const reviewsSnapshot = await storeRef.collection("reviews").get();
  if (reviewsSnapshot.empty) {
    logger.log(`No reviews for store ${storeId}. Setting rating to 0.`);
    return storeRef.update({ averageRating: 0, reviewCount: 0 });
  }
  let totalRating = 0;
  reviewsSnapshot.forEach((doc) => {
    totalRating += doc.data().rating;
  });
  const reviewCount = reviewsSnapshot.size;
  const averageRating = totalRating / reviewCount;
  logger.log(
      `Updating store ${storeId}: reviewCount=${reviewCount}, ` +
      `averageRating=${averageRating.toFixed(2)}`,
  );
  return storeRef.update({
    reviewCount: reviewCount,
    averageRating: averageRating,
  });
});

exports.addRoleOnBuyerCreate = onDocumentWritten({
    document: "buyers/{userId}",
    region: "us-central1"
}, async (event) => {
  if (!event.data.before.exists && event.data.after.exists) {
    const userId = event.params.userId;
    logger.log(`Detected new buyer document for user: ${userId}. Setting custom claim 'role: buyer'.`);
    try {
      await admin.auth().setCustomUserClaims(userId, { role: 'buyers' });
      logger.log(`Custom claim 'role: buyers' set successfully for user ${userId}.`);
    } catch (error) {
      logger.error(`Error setting custom claim for buyer ${userId}:`, error);
    }
  }
  return null;
});

exports.addRoleOnSellerCreate = onDocumentWritten({
    document: "sellers/{userId}",
    region: "us-central1"
}, async (event) => {
  if (!event.data.before.exists && event.data.after.exists) {
    const userId = event.params.userId;
    logger.log(`Detected new seller document for user: ${userId}. Setting custom claim 'role: seller'.`);
    try {
      await admin.auth().setCustomUserClaims(userId, { role: 'sellers' });
      logger.log(`Custom claim 'role: sellers' set successfully for user ${userId}.`);
    } catch (error) {
      logger.error(`Error setting custom claim for seller ${userId}:`, error);
    }
  }
  return null;
});

// --- [แก้ไขแล้ว] ฟังก์ชันสำหรับ Gemini Chatbot ---
exports.chatWithGemini = onCall({
    secrets: ["GEMINI_API_KEY"],
    region: "us-central1"
}, async (request) => {
  const { GoogleGenerativeAI } = require("@google/generative-ai");
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

  const userMessage = request.data.message || "";
  if (!userMessage) {
    throw new HttpsError("invalid-argument", "Message is required.");
  }

  try {
    // --- [การแก้ไขที่สำคัญ] ---
    // เปลี่ยนชื่อโมเดลเป็น "gemini-1.5-flash-latest" ซึ่งเป็นเวอร์ชันที่ถูกต้องและพร้อมใช้งาน
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash-latest" });
    
    const chat = model.startChat({
      history: [
        { role: "user", parts: [{ text: "สวัสดี" }] },
        { role: "model", parts: [{ text: "สวัสดีครับ! ผมคือผู้ช่วย AI ของ BanBanShop ยินดีให้บริการครับ" }] },
      ],
      generationConfig: { maxOutputTokens: 1000 },
    });

    const result = await chat.sendMessage(userMessage);
    const response = await result.response;
    return { reply: response.text() };
  } catch (error) {
    logger.error("Error calling Gemini API:", error);
    throw new HttpsError("internal", "Error communicating with AI.", error);
  }
});
