# Production - Manual: auto pick (Bruno)

endpoint ที่ production-core เรียกตอน New Usage — ปกติให้ยิงผ่าน collection `prime-wms-production-core` → `Production-Manual/05 New Usage` (production-core จัดการแถว input confirm + GI + SAP ให้) ยิงตรงที่นี่เฉพาะตอน debug

ข้อควรรู้
- `requestId` / `refId` สร้างอัตโนมัติครั้งแรกแล้วค้างไว้ใน runtime var → ยิงซ้ำ = idempotent replay (ได้ pick เดิม); อยากได้ pick ใหม่ให้ล้าง runtime var ก่อน
- ยิงตรงแล้วของจะย้ายไป production staging จริง แต่ production-core ไม่รู้ (ไม่มีแถว usage / ไม่ GI) — ใช้กับข้อมูลทดสอบเท่านั้น
- ต้องมีสต็อกตรง lot (`srcBatch` / `srcStorageType` / `srcReceiveDate`) ที่ `srcLocation`
