# Location Import

warehouse-core รับแถว JSON ที่ service `reports` parse จาก Excel แล้ว (เส้น Excel `upload-location-master-v2` และ template ถูกลบ; template/import ไฟล์อยู่ที่ reports ผ่าน document-core `/report/Import|Export`)

1. `01 Upsert Location` — แก้ `zoneCode` / `locationSize` ใน vars ของ request ให้ตรง master ของ `warehouseCode` ก่อน แล้วรัน (เขียน location `BRU-01-01` จริง)
2. `02 Upsert Location Unknown Warehouse` — ต้องได้ 400 และ `errors[0].column == "Warehouse*"` (ไม่เขียนข้อมูล)
3. ตรวจผล: `location.pick_sequence` และ `location_seq` (seq_type = PICK) ผ่าน `POST /location-seq/get-location-seq`
