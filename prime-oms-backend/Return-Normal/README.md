# Return-Normal: บันทึกยอดหัวบิลใบคืน

ใบคืน (`/sell-order/create-return`) เก็บ Trade Discount / Shipping Fee / ยอดรวมที่หน้าเว็บคำนวณลง header

รันตามลำดับ (ต้องส่ง `--env-var token=<JWT>` ห้ามเก็บ token ลงไฟล์ เพราะ repo นี้เป็น public):

1. `01 Create Return Draft With Totals`: สร้างใบคืน draft (TEMP) พร้อมยอดหัวบิล แล้วเก็บ `returnId` ไว้
2. `02 Get Return Detail`: เช็กว่า header มี tradeDiscount / shippingFee / totalAmount ตรงกับที่ส่งไป
3. `03 Delete Return Draft`: ลบ draft ที่สร้างขึ้นมาทดสอบ
4. `04 Get Return List`: รันแยกได้ (ไม่ขึ้นกับ 01-03) เช็กว่าทุกแถวมี `platformOrderRefDisplay` (TSN = `poNumber/returnNo`)

ขั้น 02 ยังเช็กว่า header มี `platformOrderRefDisplay` ด้วย

```bash
npx @usebruno/cli@2 run prime-oms-backend/Return-Normal --env Dev --env-var token=<JWT>
```
