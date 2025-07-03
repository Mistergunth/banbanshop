// functions/index.js (หรือ functions/src/index.ts ถ้าใช้ TypeScript)

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp(); // Initialize Firebase Admin SDK

// Cloudinary configuration (IMPORTANT: Use environment variables or Firebase Functions config)
// For production, DO NOT hardcode API_KEY and API_SECRET here.
// Use `firebase functions:config:set cloudinary.cloud_name="your_name" cloudinary.api_key="your_key" cloudinary.api_secret="your_secret"`
// Then access them via functions.config().cloudinary.cloud_name, etc.
const cloudinary = require("cloudinary").v2;

cloudinary.config({
    cloud_name: functions.config().cloudinary.cloud_name, // Get from Firebase Functions config
    api_key: functions.config().cloudinary.api_key, // Get from Firebase Functions config
    api_secret: functions.config().cloudinary.api_secret, // Get from Firebase Functions config
    secure: true,
});

// HTTP Cloud Function สำหรับลบโพสต์
exports.deletePost = functions.https.onCall(async (data, context) => {
    // 1. ตรวจสอบว่าผู้ใช้ล็อกอินอยู่หรือไม่
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "ต้องเข้าสู่ระบบเพื่อลบโพสต์",
        );
    }

    const postId = data.postId;
    const userId = context.auth.uid; // UID ของผู้ใช้ที่เรียกใช้ Function

    if (!postId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "ต้องระบุ postId",
        );
    }

    const db = admin.firestore();
    const postRef = db.collection("posts").doc(postId);

    try {
        const postDoc = await postRef.get();

        // 2. ตรวจสอบว่าโพสต์มีอยู่จริงหรือไม่
        if (!postDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "ไม่พบโพสต์ที่ต้องการลบ",
            );
        }

        const postData = postDoc.data();
        // 3. ตรวจสอบสิทธิ์: ผู้ใช้ที่ลบต้องเป็นเจ้าของโพสต์
        if (postData.ownerUid !== userId) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "คุณไม่มีสิทธิ์ลบโพสต์นี้",
            );
        }

        const imageUrl = postData.imageUrl;

        // 4. ลบโพสต์จาก Firestore
        await postRef.delete();
        console.log(`Post ${postId} deleted from Firestore.`);

        // 5. ลบรูปภาพจาก Cloudinary
        if (imageUrl) {
            const uri = new URL(imageUrl);
            const pathSegments = uri.pathname.split("/").filter((segment) => segment);
            // public_id มักจะเป็นส่วนสุดท้ายของ path ก่อนนามสกุลไฟล์
            // เช่น /image/upload/v12345/folder/public_id.jpg
            let publicId = pathSegments[pathSegments.length - 1].split(".")[0];
            if (pathSegments.length > 2 && pathSegments[pathSegments.length - 2] !== "upload") {
                // หากมี folder เช่น /image/upload/my_folder/public_id.jpg
                publicId = `${pathSegments[pathSegments.length - 2]}/${publicId}`;
            }

            const cloudinaryDeleteResponse = await cloudinary.uploader.destroy(publicId);
            if (cloudinaryDeleteResponse.result === "ok") {
                console.log(`Image ${publicId} deleted from Cloudinary.`);
            } else {
                console.error(`Failed to delete image ${publicId} from Cloudinary:`, cloudinaryDeleteResponse);
                // ไม่ต้อง throw error กลับไปที่ client เพราะโพสต์ถูกลบจาก Firestore แล้ว
                // แต่ควร log ข้อผิดพลาดไว้
            }
        }

        return { success: true, message: "โพสต์ถูกลบสำเร็จ" };
    } catch (error) {
        console.error("Error deleting post:", error);
        // ส่ง error ที่เหมาะสมกลับไปที่ client
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError(
            "internal",
            "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์",
        );
    }
});
