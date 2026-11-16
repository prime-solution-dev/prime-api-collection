# Master-Import (reports)

Import product / product unit / location: reports อ่านไฟล์ + ตรวจรูปแบบ แล้วส่งแถวเป็น JSON ให้ core

## Prerequisite

- product-core deploy เส้น JSON `/product/Product/import-product`, `/product/Product/import-product-unit` แล้ว
- warehouse-core deploy เส้น JSON `/warehouse/Warehouse/upsert-location` แล้ว
- ข้อมูลตัวอย่างใน `fixtures/*.xlsx` (UOM `PCS`, warehouse `WO`, zone `Normal`, size `Mezzanine 0.55` ฯลฯ) ต้องมีใน master ของ env ที่ยิง หรือแก้ไฟล์ให้ตรงกับ env
- token: `--env-var token=...` (ห้ามเขียนลงไฟล์)

## ลำดับการรัน

1. Export Product Template / Export Product Unit Template / Export Location Template
2. Import Product
3. Import Product Unit (ต้องมี product จากข้อ 2)
4. Import Location

```bash
npx @usebruno/cli@2 run Master-Import --env Dev --env-var token=<token>
```
