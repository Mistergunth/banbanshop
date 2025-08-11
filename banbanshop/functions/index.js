// File: functions/index.js

const functions = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

// [แก้ไข] Initialize Firebase Admin เพียงครั้งเดียวใน Global Scope
admin.initializeApp();

// [แก้ไข] ประกาศตัวแปร client ไว้ใน Global Scope แต่ยังไม่สร้าง object
// เราจะสร้างมันเมื่อถูกเรียกใช้ครั้งแรก (Lazy Initialization)
let db;
let auth;

// --- โค้ดเดิมของคุณ (ไม่เปลี่ยนแปลง) ---
exports.updateStoreRating = onDocumentWritten({
    document: "stores/{storeId}/reviews/{reviewId}",
    region: "us-central1"
}, async (event) => {
    // Lazy load 'db'
    if (!db) db = admin.firestore();

    const storeId = event.params.storeId;
    logger.log(`Detected a review change for store: ${storeId}`);
    const storeRef = db.collection("stores").doc(storeId);
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
    // Lazy load 'auth'
    if (!auth) auth = admin.auth();

    if (!event.data.before.exists && event.data.after.exists) {
        const userId = event.params.userId;
        logger.log(`Detected new buyer document for user: ${userId}. Setting custom claim 'role: buyer'.`);
        try {
            await auth.setCustomUserClaims(userId, { role: 'buyers' });
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
    // Lazy load 'auth'
    if (!auth) auth = admin.auth();

    if (!event.data.before.exists && event.data.after.exists) {
        const userId = event.params.userId;
        logger.log(`Detected new seller document for user: ${userId}. Setting custom claim 'role: seller'.`);
        try {
            await auth.setCustomUserClaims(userId, { role: 'sellers' });
            logger.log(`Custom claim 'role: sellers' set successfully for user ${userId}.`);
        } catch (error) {
            logger.error(`Error setting custom claim for seller ${userId}:`, error);
        }
    }
    return null;
});

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

// ========================================================================
// [ใหม่] ฟังก์ชันสำหรับสแกนบัตรประชาชนด้วย Gemini (แทนที่ Cloud Vision)
// ========================================================================
exports.extractIdInfoWithGemini = onCall({
    secrets: ["GEMINI_API_KEY"],
    region: "asia-southeast1",
    timeoutSeconds: 60,
    memory: "1GiB",
}, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
    }
    
    const { GoogleGenerativeAI } = require("@google/generative-ai");
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

    const imageBase64 = request.data.imageBase64;
    if (!imageBase64) {
        throw new HttpsError("invalid-argument", "Image data (Base64) is required.");
    }

    try {
        logger.log("Received image, calling Gemini 1.5 Flash...");
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash-latest" });

        const prompt = "จากรูปภาพบัตรประชาชนไทยที่ให้มา ให้ดึงข้อมูลเฉพาะชื่อ-นามสกุลภาษาไทย และเลขประจำตัวประชาชน 13 หลักออกมา ตอบกลับเป็น JSON object ที่มี key เป็น 'fullName' และ 'idNumber' เท่านั้น หากหาข้อมูลส่วนไหนไม่เจอ ให้ค่าของ key นั้นเป็นสตริงว่าง ('')";

        const imagePart = {
            inlineData: {
                data: imageBase64,
                mimeType: "image/jpeg",
            },
        };

        const result = await model.generateContent([prompt, imagePart]);
        const response = await result.response;
        const text = response.text();

        logger.log("Gemini response raw text:", text);
        
        const cleanedText = text.replace(/```json/g, "").replace(/```/g, "").trim();
        const data = JSON.parse(cleanedText);

        logger.log("Successfully parsed JSON:", data);
        return {
            fullName: data.fullName || "",
            idNumber: data.idNumber || "",
        };

    } catch (error) {
        logger.error("Error calling Gemini or parsing response:", error);
        throw new HttpsError("internal", "Failed to process image with AI.", error.message);
    }
});
