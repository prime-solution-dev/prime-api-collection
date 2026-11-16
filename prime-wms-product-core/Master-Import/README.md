# Master-Import

เส้น JSON ของ import product / product unit ใน product-core (reports เป็นคน parse Excel แล้วยิงเส้นนี้)
เส้น Excel เดิม `/Product/upload-product-master`, `/Product/upload-product-unit-master` และ template ถูกลบแล้ว

## ลำดับการรัน

1. `Import Product` สร้าง/อัปเดต `QA-IMPORT-001` (base unit PCS)
2. `Import Product Unit` อัปเดต unit PCS ของ `QA-IMPORT-001` (ต้องมี product จากข้อ 1)
3. `Import Product Invalid Master` base unit ไม่มีจริง ต้องได้ 400 และ `errors[0].row == 2`
4. `Import Product Invalid Row` product_code ว่าง ต้องได้ 400 จากกฎระดับแถวที่ core ตรวจเอง (ไม่แตะ DB)

## รัน

```bash
cd prime-wms-product-core
npx @usebruno/cli@2 run Master-Import --env Local --env-var token=<token> --env-var companyCode=<company> --env-var siteCode=<site>
```

ส่ง token ตอนรันผ่าน `--env-var` เท่านั้น ห้าม commit token ลง repo (repo เป็น PUBLIC)
เส้นนี้เขียนข้อมูล: รันได้บน Dev / Local ที่ต่อ Dev, UAT ถามผู้ใช้ก่อน, production ห้ามรัน
