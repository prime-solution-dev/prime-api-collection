# Master-Import (document-core)

Import product / product unit / location ผ่านตัวกลาง `/report/Import` และ `/report/Export` ของ document-core
document-core หา URL ปลายทางจาก `document_type_item.endpoint` (path ต่อท้าย env `base_url`) ก่อน แล้ว fallback `hook_config`
ส่ง `company_code` / `site_code` + header `Authorization` ต่อให้ reports และคืน status + body ของปลายทางตามจริง

## Prerequisite

- รัน seed `seeds/dev/20261116120000_master_import_document_types.sql` ของ document-core แล้ว (`make seed-dev-up CONFIRM=yes`)
- deploy document-core, reports, product-core และ warehouse-core เวอร์ชันที่มีงานนี้แล้ว
- fixture ใช้ไฟล์ของ collection `prime-wms-reports/fixtures/*.xlsx` (ข้อมูลตัวอย่างต้องมีใน master ของ env ที่ยิง)
- token: `--env-var token=...` (ห้ามเขียนลงไฟล์)

## ลำดับการรัน

1. Export Product Template / Export Product Unit Template / Export Location Template
2. Import Product
3. Import Product Unit (ต้องมี product จากข้อ 2)
4. Import Location
5. Import Unknown Hook (ต้องได้ 404)

```bash
npx @usebruno/cli@2 run Master-Import --env Dev --env-var token=<token>
```
