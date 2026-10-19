# Price-List

ทดสอบ save ราคา kg ของ group ที่ไม่มีราคาฐาน (ราคาฐานของ uom นั้น = 0 เช่น GROUP_1_ITEM_6) แล้ว pcs ต้องถูกคำนวณให้

ลำดับการรัน (ตั้ง `subGroupId`, `kgPrice`, `weightSpec` ใน environment ก่อน — ห้ามใส่ token/secret, repo เป็น public):

1. `01 Save SubGroup kg` — บันทึก kg ที่กรอกเอง พร้อม pcs ที่คำนวณจาก kg ในการเขียนครั้งเดียว (`POST /price/UpdatePriceListSubGroup`) · warehouse ล้ม = 500 และไม่มีอะไรถูกบันทึก
2. `02 Verify pcs` — เช็ก kg คงเดิมและ pcs = kg x weight_spec (`POST /price/SubGroup/GetCalculated`)
3. `03 Update Latest SubGroup` — คำนวณใหม่ตามสูตร (`POST /price/SubGroup/UpdateLatest`) แล้วรัน 02 ซ้ำ ค่าต้องไม่เปลี่ยน

ใช้กับ Local/Dev เท่านั้น ห้ามรันกับ Pacifica-Uat หรือ production เพราะเขียนราคาจริงลง DB
