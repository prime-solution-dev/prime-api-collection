# Production - Manual (Bruno)

assembly type `PRODUCTION_MANUAL` — ไม่มี BOM / backflush; ใช้ของผ่าน New Usage (pick + GI ทันที), รับกลับผ่าน Return, GR ผลผลิตบันทึก output confirm อย่างเดียว

รันตามลำดับ 01 → 09 (หรือ 10 แทน 09 กับใบที่ยัง Draft / NEW) เลือก environment แล้วแก้ข้อมูลทดสอบให้ตรงของจริง ใส่ `token` เองใน Bruno (ไม่ commit)

ต้องเตรียมก่อนรัน
- deploy goods-receive-core → picking-core → production-core และรัน migration แล้ว (ถ้ายังไม่รัน manual endpoint ตอบ `PRODUCTION_MANUAL database migration has not been applied`; PRODUCTION เดิมไม่กระทบ)
- รัน config `production_manual_config.sql` (system_config `IB_PRODUCTION_MANUAL` / `IB_PRODUCTION_MANUAL_RETURN`, hook_config)
- มีสต็อก `inputProduct` ≥ `usageQty` ที่ `srcLocation` (location type NORMAL, ไม่ใช่ production staging) — `srcBatch` / `srcStorageType` / `srcReceiveDate` ต้องตรงกับแถวสต็อก
- `productionStaging` = location ที่ติด flag production staging; `returnLocation` = location NORMAL ปกติ

```bash
cd prime-wms-production-core
npx @usebruno/cli@2 run Production-Manual --env Dev --bail
```

## หมายเหตุ
- `01` ส่ง external_id → Draft (TEMP) แบบ SAP; ไม่ส่ง external_id = สร้างแบบหน้าเว็บ (PENDING + Plan GR ทันที)
- `03` Submit สร้าง Plan GR (`IB_PRODUCTION_MANUAL`, document_ref = เลขใบ) — GR ผลผลิตทำผ่านหน้าเว็บ GR list → "Create Production - Manual" (รับเกินได้, putaway แบบ production, ไม่ตัดวัตถุดิบ)
- `05` / `07` ตอบ 200 พร้อม `result` PICK_PENDING / GI_PENDING / RETURN_PENDING ได้ถ้า service ปลายทางไม่ตอบ → ยิง `06` Retry (ไม่ pick / GI / GR ซ้ำ)
- `09` ปิดใบได้เมื่อมีการใช้ของหรือ GR แล้ว (PENDING GR / PARTIAL GR) และไม่มีแถวค้าง
- `10` ยกเลิกได้เมื่อ Actual = 0 และยังไม่มี GR
- endpoint ที่ production-core เรียกต่อ: picking-core `auto-pick-production-manual`, goods-receive-core `production-manual-return` (ดู collection ของแต่ละ core)
