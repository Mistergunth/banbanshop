// File: functions/index.js

const functions = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Declare database and auth clients for lazy initialization
let db;
let auth;

// --- ฟังก์ชันเดิม (ไม่มีการเปลี่ยนแปลง) ---
exports.updateStoreRating = onDocumentWritten({
    document: "stores/{storeId}/reviews/{reviewId}",
    region: "us-central1"
}, async (event) => {
    if (!db) db = admin.firestore();
    const storeId = event.params.storeId;
    const storeRef = db.collection("stores").doc(storeId);
    const reviewsSnapshot = await storeRef.collection("reviews").get();

    if (reviewsSnapshot.empty) {
        return storeRef.update({ averageRating: 0, reviewCount: 0 });
    }

    let totalRating = 0;
    reviewsSnapshot.forEach((doc) => {
        totalRating += doc.data().rating;
    });

    const reviewCount = reviewsSnapshot.size;
    const averageRating = totalRating / reviewCount;

    return storeRef.update({
        reviewCount: reviewCount,
        averageRating: averageRating,
    });
});

exports.addRoleOnBuyerCreate = onDocumentWritten({
    document: "buyers/{userId}",
    region: "us-central1"
}, async (event) => {
    if (!auth) auth = admin.auth();
    if (!event.data.before.exists && event.data.after.exists) {
        const userId = event.params.userId;
        try {
            await auth.setCustomUserClaims(userId, { role: 'buyers' });
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
    if (!auth) auth = admin.auth();
    if (!event.data.before.exists && event.data.after.exists) {
        const userId = event.params.userId;
        try {
            await auth.setCustomUserClaims(userId, { role: 'sellers' });
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
// [FINAL STABLE VERSION] AI Store Search Function
// Version นี้ลดการพึ่งพา AI ในการสร้าง JSON ที่ซับซ้อน
// โดยให้ AI ทำหน้าที่แค่คิดประโยคพูด แล้วให้ Code สร้าง JSON เองเพื่อความเสถียร
// ========================================================================
exports.searchStoresWithAI = onCall({
    secrets: ["GEMINI_API_KEY"],
    region: "asia-southeast1",
    timeoutSeconds: 60,
}, async (request) => {
    // --- 1. ตรวจสอบข้อมูลนำเข้า ---
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
    }
    const userQuery = request.data.query || "";
    if (!userQuery) {
        throw new HttpsError("invalid-argument", "Query is required.");
    }
    logger.log(`New search query: "${userQuery}" from user ${request.auth.uid}`);

    try {
        // --- 2. ใช้ AI สกัด Keywords (ยังคงเดิม) ---
        const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
        const keywordExtractorModel = genAI.getGenerativeModel({ model: "gemini-1.5-flash-latest" });

        const keywordPrompt = `
            จากประโยคของผู้ใช้: "${userQuery}"
            ให้สกัดคำสำคัญ (keywords) สำหรับใช้ค้นหาร้านค้าในแอปอีคอมเมิร์ซ
            คำสำคัญควรเป็น ชื่อสินค้า, ประเภทสินค้า, หรือชื่อสถานที่ (จังหวัด, อำเภอ)
            ตอบกลับมาเป็น JSON object ที่มี key ชื่อ "keywords" เท่านั้น ห้ามมีข้อความอื่นนอกเหนือจาก JSON
            ตัวอย่าง:
            - Input: "อยากได้ร้านจักสานที่สกลนคร" -> Output: {"keywords": ["จักสาน", "สกลนคร"]}
            - Input: "แนะนำผ้าครามสวยๆ ให้หน่อย" -> Output: {"keywords": ["ผ้าคราม"]}
            - Input: "มีสินค้าอะไรบ้าง" -> Output: {"keywords": []}
        `;

        const keywordResult = await keywordExtractorModel.generateContent(keywordPrompt);
        const keywordResponseText = keywordResult.response.text();
        logger.log("AI Keyword Extraction Raw Response:", keywordResponseText);

        let keywords = [];
        try {
            const jsonResponse = JSON.parse(keywordResponseText.match(/{[\s\S]*}/)[0]);
            keywords = jsonResponse.keywords || [];
        } catch (e) {
            logger.error("Failed to parse keywords from AI response, using fallback.", e);
            keywords = userQuery.split(/\s+/).filter(k => k.length > 2);
        }

        logger.log("Final Keywords for search:", keywords);

        if (keywords.length === 0) {
            return {
                responseText: "ขออภัยค่ะ ไม่พบสินค้าที่ต้องการ กรุณาลองระบุชื่อสินค้าหรือประเภทสินค้าที่ชัดเจนขึ้นนะคะ",
                stores: [],
            };
        }

        // --- 3. ค้นหาข้อมูลใน Firestore จาก Keywords ---
        if (!db) db = admin.firestore();
        const storesSnapshot = await db.collection("stores").get();
        let matchedStores = [];

        storesSnapshot.forEach(doc => {
            const storeData = doc.data();
            const searchableText = `
                ${storeData.name || ''} 
                ${storeData.description || ''} 
                ${storeData.category || ''} 
                ${storeData.type || ''} 
                ${storeData.province || ''} 
                ${storeData.amphoe || ''}`.toLowerCase();

            const isMatch = keywords.some(keyword => searchableText.includes(keyword.toLowerCase()));

            if (isMatch) {
                matchedStores.push({
                    id: doc.id,
                    name: storeData.name,
                    description: storeData.description,
                    imageUrl: storeData.imageUrl,
                    rating: storeData.averageRating || 0,
                });
            }
        });

        // --- 4. จัดการผลลัพธ์ ---
        logger.log(`Found ${matchedStores.length} matched stores.`);

        if (matchedStores.length === 0) {
            return {
                responseText: "ขออภัยค่ะ ไม่พบร้านค้าที่ตรงกับที่คุณค้นหาเลย ลองใช้คำอื่นดูนะคะ",
                stores: [],
            };
        }
        
        // [การเปลี่ยนแปลงสำคัญ] จัดเรียงร้านค้าตามเรตติ้ง (จากสูงไปต่ำ)
        // เพื่อให้ผลลัพธ์ที่ได้ดูเหมือน "การแนะนำ" มากขึ้น
        matchedStores.sort((a, b) => b.rating - a.rating);

        const limitedStores = matchedStores.slice(0, 5);

        // --- 5. ใช้ AI สร้างแค่ประโยคพูด ---
        const finalResponseModel = genAI.getGenerativeModel({ model: "gemini-1.5-flash-latest" });
        const finalPrompt = `
            คุณคือผู้ช่วย AI ของแอปชื่อ "BanBanShop"
            คำถามเดิมของผู้ใช้คือ: "${userQuery}"
            และนี่คือรายชื่อร้านค้าที่เราค้นเจอ (เรียงตามความนิยม): ${limitedStores.map(s => s.name).join(', ')}.
            
            คำสั่ง:
            จากข้อมูลทั้งหมด ให้สร้าง "ประโยคเกริ่นนำที่เป็นมิตร" เพียง 1 ประโยค เพื่อบอกผู้ใช้ว่าเราเจออะไรบ้าง
            - ถ้าเจอร้านเดียว: "เจอร้าน...ให้แล้วค่ะ"
            - ถ้าเจอหลายร้าน: "นี่คือร้านค้าที่น่าสนใจ...ที่เราเจอค่ะ"
            - ทำให้เป็นธรรมชาติที่สุด
            - ตอบกลับมาเป็นประโยคพูดธรรมดา ไม่ต้องมี JSON หรือสัญลักษณ์ใดๆ
        `;

        let friendlyResponseText = "นี่คือร้านค้าที่เราค้นเจอค่ะ"; // Default text
        try {
            const finalResult = await finalResponseModel.generateContent(finalPrompt);
            friendlyResponseText = finalResult.response.text().trim();
        } catch (e) {
            logger.error("Final response generation from AI failed. Using default text.", e);
        }
        
        logger.log("Final AI-generated sentence:", friendlyResponseText);

        // --- 6. Code ของเราสร้าง JSON สุดท้ายเอง ---
        return {
            responseText: friendlyResponseText,
            stores: limitedStores
        };

    } catch (error) {
        logger.error("Critical error in searchStoresWithAI:", error);
        if (error instanceof HttpsError) {
            throw error;
        }
        throw new HttpsError("internal", "ขออภัยค่ะ เกิดข้อผิดพลาดที่ไม่คาดคิดในการค้นหา กรุณาลองใหม่อีกครั้ง");
    }
});

