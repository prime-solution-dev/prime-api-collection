# Location Import

1. `01 Download Location Template` — ดาวน์โหลด template แล้วเซฟเป็น `Location-Import/WMS_Location_Master_Template.xlsx` (ไม่ต้อง commit)
2. กรอกข้อมูล (รวม `Pick Seq.`) แล้วรัน `02 Upload Location Master V2`
3. ตรวจผล: `location.pick_sequence` และ `location_seq` (seq_type = PICK) ผ่าน `POST /location-seq/get-location-seq`
