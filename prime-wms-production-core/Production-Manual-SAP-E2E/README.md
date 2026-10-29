# Production-Manual-SAP-E2E (Bruno, Crossmax-main)

พิสูจน์ว่าใบ `PRODUCTION_MANUAL` ใบเดียว (สร้างจาก SAP Production Order ผ่าน crossmax) ส่ง SAP ครบทุกรอบโดยไม่ซ้ำ:
submit → new-usage 1 → GR ปกติ FG 4000 → new-usage 2 (SAP ล้ม → release → resend) → gr-import FG 6000 → manual return 1 บรรทัด → complete

ฝั่ง WMS: Bruno assert ผ่าน `POST /production/get-production-detail` (`is_send_interface`, `qty_interface`, `is_send_grpo`) ทุกขั้น
ฝั่ง SAP: Bruno เช็คไม่ได้ → ทำตาม [SAP checklist](#sap-checklist)

## Pre-condition

- deploy Crossmax-main ครบขั้น 1–6 ตาม spec (goods-receive-core → document-core โค้ด → production-core `migrate-up` → crossmax-custom + production-core พร้อมกัน → document-core `make seed-up SET=Crossmax-main`)
- crossmax env `PRODUCTION_ASSEMBLY_TYPE=PRODUCTION_MANUAL` (ไม่ตั้ง = crossmax สร้างใบ `PRODUCTION` → `05` ล้ม)
- `OMHPTS03-0340` เป็น group_value ของ PG06 บน Crossmax-main (ไม่งั้น crossmax ไม่ถือ PO เป็น PO ค่าผลิต → GRPO-Production skip)
- รัน `production_manual_config.sql` แล้ว (system_config `IB_PRODUCTION_MANUAL` / `IB_PRODUCTION_MANUAL_RETURN`, hook_config)
- สต็อก WMS: `u1Product` ≥ `u1Qty` ที่ `u1Location`, `u2Product` ≥ `u2Qty` ที่ `u2Location` (location NORMAL, lot ตรงแถวสต็อก)
- สต็อก SAP: `u1Product` พอ, **`u2Product` ไม่พอ** (ให้ IFP #2 ล้มที่ `2-ifp-fail`) — เตรียมของไว้เติมทีหลัง
- แก้ค่า `CHANGE_ME` ใน `environments/Crossmax-Main.bru` (productionStaging, lot ของ u1 / u2, return location); `u?MfgDate` / `u?ExpDate` / `u?ReceiveDate` ใส่ `null` หรือ `"2026-01-01T00:00:00Z"` (มี `"`)
- ⚠️ ตรวจ host ก่อนรัน: env นี้ใช้ `crossmax.prime-solution.cc` ตาม `prime-wms-document-core/environments/Crossmax-Main.bru` แต่ curl ตัวอย่างของ PO / PdO ยิง `crossmax-wms.prime-lab.cc` (ซึ่งใน collection นี้คือ `Crossmax-Uat`)

## รัน

`token` ไม่ commit — ส่งทาง `--env-var token=...` ทุกครั้ง (หรือใส่ใน Bruno app)
ค่าเดียวที่ข้าม subfolder คือ `assemblyCode` (`02` ใช้ `bru.setEnvVar(..., { persist: true })` — Bruno app เขียนลง env ให้, **CLI 2.15 ไม่เขียนไฟล์** → อ่านเลขจากชื่อ test ของ `02` แล้ว export เอง). ห้าม commit `assemblyCode`
ค่าอื่นหาใหม่ทุก subfolder: รอบ usage แยกด้วยสินค้า (รอบ 1 = `u1Product`, รอบ 2 = `u2Product` **ต้องคนละตัว**), output แยกด้วย qty (`gr1Qty` / `gr2Qty` ต้องไม่เท่ากัน)

```bash
cd prime-wms-production-core
run() { npx @usebruno/cli@2 run "Production-Manual-SAP-E2E/$1" --env Crossmax-Main --env-var token="$TOKEN" --env-var assemblyCode="$ASSEMBLY" --bail; }

run 1-setup/a-create-and-usage-1
export ASSEMBLY=...   # จาก test "assembly created: assemblyCode = ..." ของ 02
# [manual 1] GR ผลผลิตปกติ FG 4000 ผ่านหน้าเว็บ (GR list → Create Production - Manual, ผูก Plan GR ของ assemblyCode)
run 1-setup/b-assert-gr-1
run 2-ifp-fail
# [manual 2] เติมสต็อก u2Product ฝั่ง SAP ให้พอ
run 3-resend-and-finish/a-resend
# [manual 3] gr-import FG 6000 ผ่านหน้าเว็บ /gr-import (ไฟล์ excel product FGHPTS03-010340DRT01 qty 6000) → status สำเร็จ + มี gr_reference
run 3-resend-and-finish/b-finish
# 4-rollback-check: SQL ข้างล่าง (ไม่มี request)
```

| subfolder | request | assert |
|---|---|---|
| `1-setup/a-create-and-usage-1` | crossmax PO → crossmax Production (เก็บ `CMR_WMSRefDoc` เป็น `assemblyCode`) → get-assembly → submit → detail → get-input-usage → new-usage 1 → detail | `external_id`=290, `external_id_3`=1026100017; แถว usage รอบ 1 `is_send_interface`=true, `qty_interface`=`qty_gi` |
| `1-setup/b-assert-gr-1` | detail | output confirm 1 แถว qty 4000, `is_send_interface`=true, `is_send_grpo`=true; รอบ 1 input ไม่เปลี่ยน |
| `2-ifp-fail` | get-input-usage → new-usage 2 → detail | แถวรอบ 2 `is_send_interface`=false, `qty_interface`=0 (release); รอบ 1 + output รอบ 1 ไม่ถูกแตะ |
| `3-resend-and-finish/a-resend` | `resend-sap-hook` INPUT/CONFIRM → detail | แถวรอบ 2 ส่งแล้ว; รอบ 1 `qty_interface` ไม่เพิ่ม |
| `3-resend-and-finish/b-finish` | detail → return → detail → complete → detail | output 2 แถว (4000 + 6000) ส่งครบทั้ง RFP / GRPO; แถว MANUAL_RETURN RETURNED + ส่งแล้ว; complete ไม่เปลี่ยน flag ใดๆ |

## SAP checklist

ค้นใน SAP ด้วย `CMR_WMSRefDoc` = `assemblyCode` (BaseEntry = PdO DocEntry 290)

| เอกสาร | จำนวน | ตรวจ |
|---|---|---|
| IssueforProduction | 2 | #1 = เฉพาะ u1Product × u1Qty; #2 = เฉพาะ u2Product × u2Qty (ไม่มีบรรทัดรอบ 1) — ไม่มีใบที่ล้มค้าง/ซ้ำหลัง resend |
| ReceiptfromProduction | 2 | FG 4000 และ FG 6000 (ไม่สะสม) |
| ReceiptfromProductionReturn | 1 | u1Product × returnQty, BaseLine = LineNum ของ u1Product |
| GoodsReceiptPOProduction | 2 | base PO DocNum 1026100017 (`OMHPTS03-0340`): 4000 × 5 = **20,000** และ 6000 × 5 = **30,000** (ราคาจาก base PO — ยังไม่เคยยืนยันกับ SAP จริง) |
| หลัง complete | 0 | ไม่มีเอกสารใหม่ |

itlog crossmax: IFP #2 ครั้งแรก FAILED (`IsSuccess:false`), ครั้ง resend SUCCESS

## 4-rollback-check (ซ้อม seed-down / seed-up)

ทำหลัง happy path ครบ ไม่เดิน flow ซ้ำ — รันที่ document-core worktree / DB `prime_wms_document` ของ Crossmax-main

```bash
make seed-status SET=Crossmax-main   # ล่าสุดต้องเป็น 20261029120000_production_manual_hooks_v2
make seed-down   SET=Crossmax-main
```

```sql
-- หลัง seed-down: hook PRODUCTION ต้องกลับเป็นก่อน seed v2 (เทียบกับผลที่จดไว้ก่อน seed-up ขั้น 6)
SELECT topic, sub_topic, substring(hook_url FROM '/Api/Transaction/(.*)$') AS endpoint, seq
FROM hook_config WHERE module = 'PRODUCTION' ORDER BY topic, sub_topic, seq;
-- ตารางสำรองต้องหายไป
SELECT to_regclass('seed_bak_production_manual_hooks_v2');   -- คาด NULL
```

```bash
make seed-up SET=Crossmax-main
```

```sql
-- หลัง seed-up: คาด 4 แถวพอดี
--   BACKFLUSH/CREATE  ReceiptfromProduction 1, GoodsReceiptPOProduction 2
--   INPUT/CONFIRM     IssueforProduction 1
--   RETURN/CONFIRM    ReceiptfromProductionReturn 1
--   (ไม่มี COMPLETED/COMPLETED)
SELECT topic, sub_topic, substring(hook_url FROM '/Api/Transaction/(.*)$') AS endpoint, seq
FROM hook_config WHERE module = 'PRODUCTION' ORDER BY topic, sub_topic, seq;
```

## คำเตือน

- **PurchaseOrder ยิงซ้ำ = order ใหม่** (crossmax ไม่กัน) — รันซ้ำให้ข้าม `01` ถ้า PO DocNum 1026100017 มีบน WMS แล้ว (รัน `02`–`08` ทีละไฟล์)
- **Production ยิงซ้ำ = ใบ assembly ใหม่** — ทั้ง flow ต้องอยู่บนใบเดียว (`assemblyCode` ใน env)
- **ห้ามใช้ `Production-Manual/01 Create Draft`** — ไม่เขียน `external_id` / `external_id_3` → IFP / RFP / GRPO skip ทั้งใบ
- ถ้า `2-ifp-fail/02` เจอแถวรอบ 2 ยัง `is_send_interface=true` ทั้งที่ itlog FAILED = release ล้ม → ใช้ `POST /interface-log/:id/resend` ของ crossmax แทน `resend-sap-hook` (runbook ข้อ 2 ใน spec)
- itlog `ERROR` (timeout) → ค้น SAP ด้วย `CMR_WMSRefDoc` ก่อน: ขึ้นแล้ว = ห้ามยิงซ้ำ
- WMS เห็นแค่ flag `is_send_grpo` ต่อแถว — "รอบก่อนไม่ถูก claim ซ้ำ" ของ GRPO / RFP พิสูจน์ด้วยจำนวน + ยอดเอกสารใน SAP checklist (2 ใบ 20,000 / 30,000 ไม่ใช่ 50,000)
