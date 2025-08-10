// File: functions/index.js

const functions = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { onObjectFinalized } = require("firebase-functions/v2/storage");
const vision = require("@google-cloud/vision");

// [แก้ไข] ย้ายการสร้าง VisionClient มาไว้ที่ Global Scope
// การสร้าง client นี้ควรเกิดขึ้นเพียงครั้งเดียวเมื่อฟังก์ชันถูกโหลด
const visionClient = new vision.ImageAnnotatorClient();

// [แก้ไข] เริ่มต้น Firebase Admin SDK เพียงครั้งเดียว
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

// --- [แก้ไขใหม่] ฟังก์ชันสำหรับประมวลผลภาพบัตรประชาชนด้วย Cloud Vision API ---
exports.processIdCardImage = onObjectFinalized({
    // [แก้ไข: สำคัญมาก!] เปลี่ยนกลับเป็นชื่อสั้นของ Bucket เท่านั้น
    // เนื่องจาก Cloud Functions (2nd Gen) สำหรับ Storage Trigger ต้องการชื่อสั้น
    bucket: "banbanshop", 
    region: "asia-southeast1",
    timeoutSeconds: 300, // เพิ่ม timeout เป็น 5 นาที (300 วินาที)
    memory: "2GiB",      // เพิ่ม memory เป็น 2GiB (ถ้ามีให้เลือก)
}, async (event) => {
    logger.log(">>>>>> DIAGNOSTIC TEST: Function triggered successfully! <<<<<<");
    const fileBucket = event.data.bucket;
    const filePath = event.data.name;
    const contentType = event.data.contentType;

    // ตรวจสอบว่าเป็นไฟล์รูปภาพที่ถูกอัปโหลดมาในโฟลเดอร์ที่ถูกต้องหรือไม่
    if (!contentType.startsWith("image/") || !filePath.startsWith("id_card_images/")) {
        // ถ้าไม่ใช่รูปภาพบัตรประชาชน หรือไม่ได้อยู่ในโฟลเดอร์ที่กำหนด ให้ข้ามการประมวลผล
        return logger.log("This is not an ID card image or not in the correct folder, skipping.");
    }

    // ดึง User ID ออกมาจากชื่อไฟล์ (เช่น "id_card_images/USER_ID.jpg")
    const fileName = filePath.split("/").pop();
    const userId = fileName.split(".")[0];
    if (!userId) {
        // ถ้าไม่สามารถดึง User ID ได้ ให้บันทึกข้อผิดพลาด
        return logger.error("Could not extract user ID from file path.", { filePath });
    }

    logger.log(`Processing ID card for user: ${userId}`);
    const db = admin.firestore(); // สร้าง Firestore instance ภายในฟังก์ชัน

    try {
        // เรียกใช้ Cloud Vision API เพื่ออ่านข้อความจากภาพ (ระบุภาษาเป็น THAI และ English)
        const [result] = await visionClient.textDetection(`gs://${fileBucket}/${filePath}`, {
            imageContext: {
                languageHints: ['th', 'en'] // แนะนำให้ใช้ภาษาไทยและอังกฤษ
            }
        });
        const detections = result.textAnnotations;

        if (!detections || detections.length === 0) {
            // ถ้าไม่พบข้อความในภาพ ให้บันทึกสถานะข้อผิดพลาดลง Firestore
            logger.log(`No text found in image for user: ${userId}`);
            await db.collection("idCardScans").doc(userId).set({
                status: "error",
                errorMessage: "No text found in image.",
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
            return null;
        }

        const fullText = detections[0].description;
        logger.log("Full text from Vision API:", fullText);

        const idCardRegex = /(\d[\s-]?){13}/;
        const nameRegex = /(นาย|นางสาว|นาง|เด็กชาย|เด็กหญิง)\s*([ก-๙]+(?:\s[ก-๙]+)?)\s+([ก-๙]+)/;
        const fallbackNameRegex = /(?:ชื่อตัวและชื่อสกุล|ชื่อ)\s*([ก-๙\s]+)/;
        const engNameRegex = /Name\s*([a-zA-Z\s.]+)\s*Last name\s*([a-zA-Z\s.]+)/;

        let foundIdNumber = "";
        let foundFullName = "";
        let foundEngName = "";

        // ค้นหาเลขบัตรประชาชน
        const idMatch = fullText.match(idCardRegex);
        if (idMatch) {
            foundIdNumber = idMatch[0].replace(/[\s-]/g, ""); // ลบช่องว่างและขีดกลาง
            // ตรวจสอบความยาวเลขบัตรประชาชน 13 หลักสุดท้าย (เผื่อมีตัวเลขอื่น ๆ ติดมา)
            if (foundIdNumber.length > 13) {
                foundIdNumber = foundIdNumber.substring(foundIdNumber.length - 13);
            }
        }

        // ค้นหาชื่อ-นามสกุลไทย
        let nameMatch = fullText.match(nameRegex);
        if (nameMatch && nameMatch[2] && nameMatch[3]) {
            foundFullName = `${nameMatch[2].trim()} ${nameMatch[3].trim()}`;
        } else {
            nameMatch = fullText.match(fallbackNameRegex);
            if (nameMatch && nameMatch[1]) {
                foundFullName = nameMatch[1].trim().replace(/[a-zA-Z0-9]/g, '');
                const nameParts = foundFullName.split(/\s+/).filter(part => part.length > 0);
                if (nameParts.length >= 2) {
                    foundFullName = `${nameParts[0]} ${nameParts[1]}`;
                } else {
                    foundFullName = nameParts.length > 0 ? nameParts[0] : "";
                }
            }
        }

        // ค้นหาชื่อภาษาอังกฤษ
        const engNameMatch = fullText.match(engNameRegex);
        if (engNameMatch && engNameMatch[1] && engNameMatch[2]) {
            foundEngName = `${engNameMatch[1].trim()} ${engNameMatch[2].trim()}`;
        }

        // นำข้อมูลที่ได้ไปบันทึกไว้ใน Firestore ใน Collection "idCardScans"
        await db.collection("idCardScans").doc(userId).set({
            idNumber: foundIdNumber,
            fullName: foundFullName,
            englishName: foundEngName,
            status: "completed", // ตั้งสถานะเป็น "completed" หากประมวลผลสำเร็จ
            processedAt: admin.firestore.FieldValue.serverTimestamp(), // บันทึกเวลาที่ประมวลผล
        }, { merge: true }); // ใช้ merge: true เพื่อไม่ให้เขียนทับข้อมูลอื่น ๆ ใน document

        logger.log(`Successfully processed ID for user ${userId}. Name: ${foundFullName}, ID: ${foundIdNumber}, Eng Name: ${foundEngName}`);
        return null;

    } catch (error) {
        // หากเกิดข้อผิดพลาดในการประมวลผล ให้บันทึกสถานะข้อผิดพลาดลง Firestore
        logger.error(`Error processing image for user ${userId}:`, error);
        await db.collection("idCardScans").doc(userId).set({
            status: "error",
            errorMessage: "An error occurred during processing: " + error.message,
            errorDetails: error.stack,
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return null;
    }
});
