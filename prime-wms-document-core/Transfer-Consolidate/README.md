# Transfer - Consolidate (Bruno)

รันตามลำดับ 01 → 17 (Bruno Runner ได้) เลือก environment Local หรือ Dev แล้วแก้ข้อมูลทดสอบใน environment ให้ตรงกับข้อมูลจริง

ต้องเตรียมก่อนรัน
- migration warehouse-core `add_is_transfer_consol_staging_to_location.sql` ถูก apply แล้ว
- มี location `consolLocation` ที่ติด flag Transfer Consol Staging (สร้างจากหน้าเว็บ Master > Location เลือก type "Transfer Consol staging")
- มีสต็อก `productCode` จำนวน ≥ `qty` ที่ `srcLocation`
- `destLocation` เป็น location ปกติ
- system_config `CTF` / `TFO` / `TFI` (ถ้าไม่มี ระบบสร้าง default ให้โดยใช้ config code เป็น prefix)

หลังรันครบ เปิดเว็บ /transfer แท็บ "Transfer - Consolidate" ค้นด้วย Consolidate No. ที่ได้จาก 02 แล้วเปิด detail ตรวจว่าแก้ไขไม่ได้

## รันทั้ง flow ด้วย CLI (ลำดับสำคัญ — 05a/10a seq ชนกับ 05/10 จึงต้องระบุ path ตามลำดับ)

```bash
cd prime-wms-document-core
npx @usebruno/cli@2 run "Transfer-Consolidate/00 Check Stock.bru" "Transfer-Consolidate/01 Get Consol Locations.bru" "Transfer-Consolidate/02 Create Consolidate Transfer.bru" \
  "Transfer-Consolidate/03 Get Pair by Consolidate No.bru" "Transfer-Consolidate/15 Get Consol Out By Location.bru" "Transfer-Consolidate/16 Get Transfer By Company Site.bru" "Transfer-Consolidate/17 Get Transfer Code Like And Dates.bru" "Transfer-Consolidate/04 Save Consol Out Confirm.bru" "Transfer-Consolidate/05 Complete Consol Out.bru" \
  "Transfer-Consolidate/05a Check Stock After Out.bru" "Transfer-Consolidate/06 Get Consol In.bru" "Transfer-Consolidate/12 Get Consol In By Location.bru" "Transfer-Consolidate/13 Claim Consol In Task.bru" "Transfer-Consolidate/07 Save Consol In Partial.bru" \
  "Transfer-Consolidate/08 Complete Consol In Partial (reject).bru" "Transfer-Consolidate/09 Save Consol In Full.bru" "Transfer-Consolidate/14 Release Consol In Task.bru" "Transfer-Consolidate/10 Complete Consol In.bru" \
  "Transfer-Consolidate/10a Check Stock After In.bru" "Transfer-Consolidate/11 Complete Again (idempotent).bru" --env Pacifica-Uat --bail
```

- `00` เก็บ baseline → `05a` / `10a` เทียบส่วนต่าง (src −qty, Consol +qty/จอง +qty, แล้ว Consol กลับ baseline + dest +qty)
- env ต้องมี `receiveDate` / `storageType` ตรงกับแถวสต็อกที่ src (ดูจาก collection `prime-wms-warehouse-core` → Find Stock In Warehouse) ไม่งั้น complete จะ error `not found inventory`

## หมายเหตุ
- `17` ใช้ `transfer_code_like` (ILIKE) + `create_date_start/end` (มี `update_date_start/end` ด้วย) แบบ filter row หน้าเว็บ (รันหลัง 03)
- `16` ใช้ `company_codes` + `source_site_codes` (มี `dest_site_codes` ด้วย) กรองด้วย company/site ของ Consol Out จาก 03 (รันหลัง 03)
- `15` ใช้ `dest_location_codes` หา Transfer Out ที่มี item ปลายทางเป็น Consol Location (รันหลัง 02; ผลต้องมี Consol Out ของ flow นี้)
- `12` ใช้ `src_location_codes` หา Transfer In ที่มี item ต้นทางเป็น Consol Location ที่ HH สแกน (รันหลัง 05 ก่อน complete Consol In; ผลต้องมี Consol In ของ flow นี้)
- `12` ส่ง `sort_in_progress_first: true` (ใบที่มีคนถืองานขึ้นก่อน) และ response มี `working_user_code`
- `13` claim งาน (`merge-transfer-working`, 1 งาน 1 คน — ผู้ใช้อื่น claim ซ้ำได้ error `transfer <code> is being worked by <user>`) / `14` ปล่อยงาน (`update-clear-transfer-working`); ถ้า complete (10) ระบบลบ lock ให้เอง; env `workingUser` = user_code ของ HH ที่ใช้ทดสอบ
- HH ใช้ `update-transfer` (04/07/09) + `update-transfer-complete` (05/08/10) เท่านั้น ไม่ใช้ `update-process-src/dest`
- เส้นหาสต็อก / location สำหรับตั้งค่า env อยู่ใน collection `prime-wms-warehouse-core`
