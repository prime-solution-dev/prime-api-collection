# Master (SAP) fan-out QA
ลำดับ: WarehouseMaster ข้ามคลัง → WarehouseMaster ปกติ → ItemMaster 001/002/003. ผลจริงต้องดู DB (interface_transaction topic_group=HOOK_INTERFACE, product ใน wms-product) เพราะ ItemMaster ตอบ SUCCESS เสมอเมื่อ validate ผ่าน
