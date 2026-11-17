# Interface Log API — curl ทุกเส้นทุกเคส

คู่กับไฟล์ `*.bru` ในโฟลเดอร์นี้ (seq 1–11 + โฟลเดอร์ย่อย `Resend (ยิงปลายทางจริง)` seq 1–3 ที่ยิงปลายทางจริง — `bru run` ปกติจะไม่รันโดยไม่ใส่ `-r`)
ดีไซน์: `docs/design/interface-transaction-log-db.md` (workspace root)

## ตั้งค่าก่อนใช้

```bash
export URL=http://localhost:9119                  # Local
# export URL=https://wms-dev.prime-lab.cc/api/crossmax-custom   # Dev
export KEY='<ITLOG_API_KEY>'   # ค่าเดียวกับ ITLOG_API_KEY ใน .env ของ repo crossmax-custom (อย่า commit)
```

auth ใช้ `Authorization: Bearer <ITLOG_API_KEY>` **ไม่ใช่** header ชื่อเฉพาะ
เพราะ `apilog` ถูก `Use()` ที่ระดับ engine จึง log ทุก request ของทุก route
และ mask ให้เฉพาะ `authorization` / `api_key` / `cookie` / `service_token`
header ชื่ออื่นจะถูกเขียนลง MongoDB แบบ plaintext

---

## POST /interface-log/list — list

### 1. หน้าแรก (attempt ล่าสุดของแต่ละเอกสาร)

```bash
curl -sS -X POST "$URL/interface-log/list" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"limit":50}' | jq
```

ทุก endpoint เป็น POST + JSON body; list คืน 1 แถวต่อ transaction (attempt ล่าสุด)

<details><summary>ตัวอย่าง response</summary>

```json
{
  "total": 2,   // จำนวนรายการในหน้านี้ (= len(items)) ไม่ใช่จำนวนทั้งหมด
  "items": [
    {
      "id": "9f1c0e2a-6b74-4a1e-9d3f-2c5b8a7e4d10",
      "transaction_id": "c4d5e6f7-2222-4222-8222-aaaabbbbcccc",
      "attempt_no": 1,
      "service": "crossmax_custom",
      "counterparty": "SAPB1",
      "topic_group": "TRANSACTION",
      "topic": "GoodsReceiptPO",
      "direction": "OUTBOUND",
      "status": "FAILED",
      "http_status": 200,
      "duration_ms": 842,
      "business_key": "PGR2607-4408",
      "method": "POST",
      "target": "https://sap.example.com/api/transection/goodsreceiptpo",
      "request_body": { "CMR_WMSRefDoc": "PGR2607-4408", "CardCode": "WRONG" },
      "response_body": {
        "IsSuccess": false,
        "Code": "E01",
        "Message": "CardCode not found",
        "Data": null,
        "Errors": ["bad card"],
        "TraceId": "0HN7..."
      },
      "req_headers": { "Content-Type": "application/json", "api_key": "****" },
      "error_message": "CardCode not found | [\"bad card\"]",
      "correlation_id": "432a6b64-de98-4109-9d70-f1ee570aa6e8",
      "is_edited": false,
      "create_dtm": "2026-07-30T10:34:12.481Z"
    },
    {
      "id": "1a2b3c4d-0000-4000-8000-abcdefabcdef",
      "transaction_id": "d0e1f2a3-3333-4333-8333-ddddeeeeffff",
      "attempt_no": 1,
      "topic_group": "MASTER",
      "topic": "ItemMaster",
      "direction": "INBOUND",
      "status": "SUCCESS",
      "http_status": 200,
      "duration_ms": 1503,
      "entity_keys": ["ITM-001", "ITM-002", "ITM-003"],
      "method": "POST",
      "target": "/Api/Master/ItemMaster",
      "request_body": { "TotalRecord": 3, "ItemsList": [{ "ItemCode": "ITM-001" }] },
      "response_body": { "Result": "SUCCESS", "IsError": false, "Message": "" },
      "is_edited": false,
      "create_dtm": "2026-07-30T09:12:00.104Z"
    }
  ],
  "next_cursor": "MTc4NTM5NjAwMDAwMDAwMDAwMHwxYTJiM2M0ZC0wMDAwLTQwMDAtODAwMC1hYmNkZWZhYmNkZWY"
}
```
</details>

### 2. รายการที่ไม่สำเร็จ (หน้าจอหลัก)

```bash
curl -sS -X POST "$URL/interface-log/list" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"status":["FAILED","ERROR","UNKNOWN"],"limit":50}' | jq '.items[] | {topic, business_key, status, error_message}'
```

| status | ความหมาย | resend |
|---|---|---|
| `FAILED` | ถึงปลายทางแล้วถูกปฏิเสธ | ได้เลย |
| `ERROR` | ไม่รู้ว่าถึงหรือยัง (timeout/เน็ตขาด) | เช็ค SAP ก่อน |
| `UNKNOWN` | ตอบมาแต่ตีความ envelope ไม่ได้ | อ่าน `response_body` เอง |

### 3. กรองตามเรื่อง

```bash
# เฉพาะ GoodsReceiptPO
curl -sS -X POST "$URL/interface-log/list" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"topic_group":"TRANSACTION","topic":"GoodsReceiptPO"}' | jq

# master ทั้งหมด
curl -sS -X POST "$URL/interface-log/list" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"topic_group":"MASTER"}' | jq
```

ค่า `topic` ที่มีทั้งหมด:

```
TRANSACTION  ARReserveInvoice ARReserveInvoiceNoBatch GoodsReceiptPO GoodsReceiptPOProduction
             GoodsReceipt GoodsIssue GoodsReturn InventoryTransfer InventoryTransferSTO
             IncomingPayment Return IssueForProduction ReceiptFromProduction
             ReceiptfromProductionReturn ClosedProductionOrder
MASTER       BPMasterData BusinessPatner ItemMaster ItemMasterComponent
             WarehouseMaster VendorMaster
```

### 4. ค้นด้วยเลขเอกสาร (`CMR_WMSRefDoc`)

```bash
curl -sS -X POST "$URL/interface-log/list" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"business_key":"PGR2607-4408"}' | jq '.items[] | {id, transaction_id, attempt_no, status}'
```

`business_key` **ไม่ unique** — ถ้าต้นทางยิงเลขเดิมเข้ามาสองครั้งจะได้สอง chain
ให้ดู `transaction_id` ประกอบ

### 5. ค้นด้วยรหัสรายการใน batch

```bash
curl -sS -X POST "$URL/interface-log/list" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"entity_key":"ITM-001"}' | jq
```

ตอบคำถาม "ItemCode นี้เข้าระบบเมื่อไหร่ สำเร็จไหม" — รหัสที่ใช้ได้ต่อเรื่อง:

```
ItemMaster           ItemCode
ItemMasterComponent  ProductNo
WarehouseMaster      WhseCode
VendorMaster         CardCode
BusinessPatner       customer_code
```

### 6. ช่วงวันที่

```bash
# YYYY-MM-DD ตีเป็นเที่ยงคืนเวลาไทย (ไม่ใช่ UTC)
curl -sS -X POST "$URL/interface-log/list" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"date_from":"2026-07-01","date_to":"2026-08-01","limit":20}' | jq

# RFC3339 ถ้าอยากระบุ offset เอง (อยู่ใน JSON body ไม่ต้อง encode)
curl -sS -X POST "$URL/interface-log/list" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"date_from":"2026-07-30T08:30:00+07:00"}' | jq
```

`date_from` รวมวันนั้น (`>=`); `date_to` แบบ `YYYY-MM-DD` = รวมทั้งวันนั้น (ระบบบวก 1 วันแล้วเทียบ `<`), แบบ RFC3339 = ก่อนเวลานั้น (`<`)

### 7. หน้าถัดไป (keyset cursor)

```bash
CUR=$(curl -sS -X POST "$URL/interface-log/list" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -d '{"limit":20}' | jq -r .next_cursor)

curl -sS -X POST "$URL/interface-log/list" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"limit":20,"cursor":"'"$CUR"'"}' | jq
```

ไม่ใช่ OFFSET จึงไม่ช้าลงเวลาเลื่อนลึก และไม่มีแถวซ้ำ/หลุดเวลามีแถวใหม่เข้ามา
ต้องส่ง filter ชุดเดิมไปด้วย `next_cursor` ว่าง = หมดแล้ว

### 9. เฉพาะฝั่ง INBOUND

```bash
curl -sS -X POST "$URL/interface-log/list" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"direction":"INBOUND","topic_group":"MASTER"}' | jq
```

`direction` มองจากมุมเราเสมอ: `OUTBOUND` = เรายิงไป SAP, `INBOUND` = SAP ยิงเข้ามา

### 10. รวม filter หลายตัว

```bash
curl -sS -X POST "$URL/interface-log/list" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"topic":"GoodsReceiptPO","status":["FAILED"],"direction":"OUTBOUND","date_from":"2026-07-30","limit":10}' | jq
```

---

## POST /interface-log/detail — ทุก attempt ของ transaction

```bash
ID=c4d5e6f7-2222-4222-8222-aaaabbbbcccc   # transaction_id จาก list (ไม่ใช่ items[].id ซึ่งเป็น id ของ attempt)
curl -sS -X POST "$URL/interface-log/detail" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"id":"'"$ID"'"}' | jq
```

ส่ง `id` ของ transaction ใน body — ใช้ `transaction_id` จาก list (detail/resend ไม่รับ `items[].id` ซึ่งเป็น id ของ attempt)

<details><summary>ตัวอย่าง response</summary>

```json
{
  "transaction_id": "c4d5e6f7-2222-4222-8222-aaaabbbbcccc",
  "attempts": [
    {
      "id": "9f1c0e2a-6b74-4a1e-9d3f-2c5b8a7e4d10",
      "attempt_no": 1,
      "status": "FAILED",
      "remote_doc_key": "4242",
      "error_message": "CardCode not found",
      "create_dtm": "2026-07-30T10:34:12.481Z"
    },
    {
      "id": "5e6f7a8b-1111-4111-8111-222233334444",
      "attempt_no": 2,
      "status": "SUCCESS",
      "remote_doc_key": "4242",
      "is_edited": true,
      "create_by": "somchai",
      "create_dtm": "2026-07-30T11:02:44.900Z"
    }
  ]
}
```
</details>

`remote_doc_key` เป็นค่าระดับ transaction (อ่านจากแถวแม่) จึงเท่ากันทุก attempt ที่มี field นี้ — เป็น `omitempty`: ปรากฏเฉพาะเมื่อ transaction มีค่า (ยังไม่เคยได้เลขเอกสาร = ไม่มี field นี้เลย)

---

## POST /interface-log/resend

รับ `id` (+ `resent_by`, `force`, `request_body`) แล้วอ่าน `target` (URL หรือ path) จาก DB **โดยเจตนา** —
ห้ามให้ client ส่ง URL เข้ามา ไม่งั้นเปิดช่องยิงอะไรก็ได้ผ่าน crossmax (SSRF)

### 11. resend payload เดิม

```bash
curl -sS -X POST "$URL/interface-log/resend" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"id":"'"$ID"'","resent_by":"somchai"}' | jq
```

`resent_by` ต้องส่งมาเอง เพราะ shared secret บอกไม่ได้ว่าใครกด

### 12. แก้ข้อมูลแล้ว resend

```bash
curl -sS -X POST "$URL/interface-log/resend" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "'"$ID"'",
    "resent_by": "somchai",
    "request_body": {
      "CMR_WMSRefDoc": "PGR2607-4408",
      "PostingDate": "2026-07-24",
      "DueDate": "2026-07-24",
      "DocumentDate": "2026-07-24",
      "CardCode": "VTE0031",
      "CardName": "DKSH PERFORMANCE MATERIALS (THAILAND) CO., LTD",
      "NumAtCard": "726100063",
      "DocumentTotal": 11500,
      "Comments": "resend after fixing CardCode",
      "LineItems": [
        { "BaseType": "22", "ItemCode": "ITM-001", "Quantity": 100, "WarehouseCode": "WH-PKRP" }
      ]
    }
  }' | jq
```

ให้ copy `request_body` จากผล detail มาแก้ ไม่ต้องประกอบใหม่จากศูนย์
แถวใหม่จะถูกตั้ง `is_edited=true`

**ระวัง**: แก้แล้ว SAP ถูก แต่ข้อมูลใน WMS ยังเป็นของเดิม สองระบบจะไม่ตรงกัน
ต้องไปตามแก้ที่ WMS ด้วย

### 13. resend แถว INBOUND (master)

```bash
IN_ID=d0e1f2a3-3333-4333-8333-ddddeeeeffff
curl -sS -X POST "$URL/interface-log/resend" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"id":"'"$IN_ID"'","resent_by":"somchai"}' | jq
```

เรียก handler ของ `/Api/Master/*` ตรง ๆ ไม่ hop เน็ต — คือ upsert master ใหม่รอบหนึ่ง

แก้ batch ก่อน resend ได้เหมือนกัน เช่นตัด item ที่พังออก:

```bash
curl -sS -X POST "$URL/interface-log/resend" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "'"$IN_ID"'",
    "resent_by": "somchai",
    "request_body": { "TotalRecord": 1, "ItemsList": [ { "ItemCode": "ITM-002" } ] }
  }' | jq
```

### 14. เคส 409 — ปลายทางรับไปแล้ว

```bash
curl -sS -X POST "$URL/interface-log/resend" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"id":"'"$ID"'","resent_by":"somchai"}' -w '\nHTTP %{http_code}\n'
```

```json
{
  "error": "itlog: เอกสารนี้ถูกส่งสำเร็จไปแล้ว (remote_doc_key=777) — ใช้ force=true ถ้าตั้งใจส่งซ้ำ",
  "remote_doc_key": "777"
}
HTTP 409
```

ไม่มีการยิงออกไปเลย และการตรวจ **ดูข้าม chain ด้วย** เพราะ `business_key` ไม่ unique:
chain A สำเร็จได้ `DocEntry 777`, chain B ล้ม — ถ้าดูแค่ chain B จะไม่เห็นว่า SAP รับไปแล้ว
แล้วจะได้เอกสารซ้ำ

409 อีกแบบ: resend ไม่ได้ในสถานะปัจจุบัน (`{"error":"itlog: transaction นี้ resend ไม่ได้ในสถานะปัจจุบัน"}`)
เกิดเมื่อสถานะเป็น SUCCESS/UNKNOWN หรือ PENDING ที่ยังไม่ถึง 5 นาที — resend ได้เฉพาะ FAILED/ERROR หรือ PENDING ที่ค้างเกิน 5 นาที

### 15. force — ข้าม guard

```bash
curl -sS -X POST "$URL/interface-log/resend" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"id":"'"$ID"'","resent_by":"somchai","force":true}' | jq
```

`force` ข้ามทั้ง guard `remote_doc_key` และ guard PENDING (ไม่ข้ามการตรวจสถานะ SUCCESS/UNKNOWN)
ใช้เมื่อไปเช็คใน SAP ด้วยตาแล้วว่าเอกสารไม่ได้เข้าจริง
เคส `ERROR` (timeout) ไม่มี `remote_doc_key` ให้ตรวจ จึงกันอัตโนมัติไม่ได้ — ต้องเช็คมือ

---

## เคส error ทั้งหมด

```bash
# 401 ไม่ส่ง Authorization
curl -sS -X POST "$URL/interface-log/list" -H "Content-Type: application/json" -d '{"limit":1}' -w '\nHTTP %{http_code}\n'
# {"error":"unauthorized"}

# 401 key ไม่ตรง
curl -sS -X POST "$URL/interface-log/list" -H "Authorization: Bearer wrong" -H "Content-Type: application/json" -d '{"limit":1}' -w '\nHTTP %{http_code}\n'

# 401 ลืมคำว่า Bearer
curl -sS -X POST "$URL/interface-log/list" -H "Authorization: $KEY" -H "Content-Type: application/json" -d '{"limit":1}' -w '\nHTTP %{http_code}\n'

# 400 id ไม่ใช่ uuid
curl -sS -X POST "$URL/interface-log/detail" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"id":"not-a-uuid"}' -w '\nHTTP %{http_code}\n'
# {"error":"id: ไม่ใช่ uuid","field":"id"}

# 400 cursor พัง
curl -sS -X POST "$URL/interface-log/list" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"cursor":"!!!"}' -w '\nHTTP %{http_code}\n'

# 400 limit ชนิดผิด
curl -sS -X POST "$URL/interface-log/list" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"limit":"abc"}' -w '\nHTTP %{http_code}\n'

# 400 date ผิดรูปแบบ
curl -sS -X POST "$URL/interface-log/list" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"date_from":"30/07/2026"}' -w '\nHTTP %{http_code}\n'

# 400 body ไม่ใช่ JSON
curl -sS -X POST "$URL/interface-log/resend" -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" -d 'not json' -w '\nHTTP %{http_code}\n'

# 404 ไม่พบ id
curl -sS -X POST "$URL/interface-log/detail" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"id":"00000000-0000-0000-0000-000000000000"}' -w '\nHTTP %{http_code}\n'

# 503 ยังไม่ตั้ง ITLOG_API_KEY / ตารางไม่มี / ต่อ DB ไม่ได้
# {"error":"interface log API ปิดอยู่ (ยังไม่ตั้ง ITLOG_API_KEY)"}
```

`limit` ต้องอยู่ระหว่าง 1 ถึง 200 (ไม่ส่ง = 50)

---

## หมายเหตุที่ไม่เห็นจาก API

**resend ยิง JSON ที่ความหมายเท่าเดิม ไม่ใช่ byte-exact ของเดิม** —
คอลัมน์เป็น `jsonb` ซึ่ง PostgreSQL เก็บแบบ parsed ไม่ใช่ bytes ดิบ
ช่องว่างหาย ลำดับ key อาจเปลี่ยน key ซ้ำถูกทิ้ง ไม่มีผลกับ SAP B1
แต่ถ้าวันไหนปลายทางต้องเซ็น signature จาก raw body ต้องเพิ่มคอลัมน์ `text` แยก

**ไม่เก็บ `api_key` และ `resp_headers`** — `api_key` อ่านสดจาก env ทุกครั้งที่ยิง
จึง resend ได้โดยไม่ต้องเก็บ (และ `req_headers` ที่เก็บก็ mask เป็น `****` แล้ว)
`resp_headers` เป็น noise ของ Cloudflare ~1.5KB/แถว ไม่เก็บ — หาใน Mongo ได้ถ้าต้องการ

**ต้องตั้ง `API_LOG_EXCLUDE=/interface-log`** ไม่งั้น response ของ list
(ซึ่งมี payload ของทุกแถวที่แสดง) จะถูกคัดลอกซ้ำลง Mongo ทุกครั้งที่เปิดหน้าจอ
