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
    region: "asia-southeast1"
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
    region: "asia-southeast1"
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
    region: "asia-southeast1"
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
    region: "asia-southeast1"
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

// --- [เพิ่มใหม่] ฟังก์ชันสำหรับประมวลผลภาพบัตรประชาชน ---
const { onObjectFinalized } = require("firebase-functions/v2/storage");
const vision = require("@google-cloud/vision");

// สร้าง Client สำหรับเรียกใช้ Vision API
const visionClient = new vision.ImageAnnotatorClient();

exports.processIdCardImage = onObjectFinalized({
    bucket: "banbanshop",
    region: "asia-southeast1", // แนะนำให้เปลี่ยน Region ให้ใกล้ไทยมากขึ้น
    timeoutSeconds: 120,    // ขยายเวลาเป็น 2 นาที
    memory: "1GiB",         // เพิ่มหน่วยความจำเป็น 1GiB (v2 syntax)
}, async (event) => {
    logger.log(">>>>>> DIAGNOSTIC TEST: Function triggered successfully! <<<<<<");
    const fileBucket = event.data.bucket;

    const filePath = event.data.name;
    if (!filePath.startsWith("id_card_images/")) {
        return logger.log("Not an ID card image, skipping.");
    }
    const contentType = event.data.contentType;

    // 1. ตรวจสอบว่าเป็นไฟล์รูปภาพที่ถูกอัปโหลดมาในโฟลเดอร์ที่ถูกต้องหรือไม่
    if (!contentType.startsWith("image/") || !filePath.startsWith("id_card_images/")) {
        return logger.log("This is not an image or not in the correct folder.");
    }

    // 2. ดึง User ID ออกมาจากชื่อไฟล์ (เช่น "id_card_images/USER_ID.jpg")
    const fileName = filePath.split("/").pop();
    const userId = fileName.split(".")[0];
    if (!userId) {
        return logger.error("Could not extract user ID from file path.", { filePath });
    }

    logger.log(`Processing ID card for user: ${userId}`);

    // [IMPROVEMENT] Initialize client inside the function to avoid deployment timeouts.
    const visionClient = new vision.ImageAnnotatorClient();

    try {
        // 3. เรียกใช้ Cloud Vision API เพื่ออ่านข้อความจากภาพ
        const [result] = await visionClient.textDetection(`gs://${fileBucket}/${filePath}`);
        const detections = result.textAnnotations;

        if (!detections || detections.length === 0) {
            logger.log(`No text found in image for user: ${userId}`);
            const db = admin.firestore();
            await db.collection("idCardScans").doc(userId).set({
                status: "error",
                errorMessage: "No text found in image.",
            });
            return null;
        }

        // นำข้อความทั้งหมดมารวมกัน
        const fullText = detections[0].description.replace(/\n/g, " ");

        // 4. ใช้ Regular Expression เพื่อค้นหาข้อมูล
        const idCardRegex = /\b(\d[\s-]?){12}\d\b/;
        const nameRegex = /(นาย|นางสาว|นาง)\s*([\u0E00-\u0E7F]+)\s+([\u0E00-\u0E7F]+)/;

        let foundIdNumber = "";
        let foundFullName = "";

        // [FIXED] Use JavaScript's .match() method, not Dart's .firstMatch()
        const idMatch = fullText.match(idCardRegex);
        if (idMatch) {
            foundIdNumber = idMatch[0].replace(/[\s-]/g, "");
        }

        // [FIXED] Use JavaScript's .match() method
        const nameMatch = fullText.match(nameRegex);
        if (nameMatch) {
            foundFullName = nameMatch[0].trim();
        }

        // 5. นำข้อมูลที่ได้ไปบันทึกไว้ใน Firestore
        const db = admin.firestore();
        await db.collection("idCardScans").doc(userId).set({
            idNumber: foundIdNumber,
            fullName: foundFullName,
            status: "completed",
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return logger.log(`Successfully processed ID for user ${userId}. Name: ${foundFullName}, ID: ${foundIdNumber}`);

    } catch (error) {
        logger.error(`Error processing image for user ${userId}:`, error);
        const db = admin.firestore();
        await db.collection("idCardScans").doc(userId).set({
            status: "error",
            errorMessage: "An error occurred during processing.",
            errorDetails: error.message,
        });
        return null;
    }
});
