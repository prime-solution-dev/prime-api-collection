# Basket label from order (packing / customer order)

หน้าที่มีแค่ order code (packing, customer order, co-consignment, co-internal) พิมพ์ป้ายตะกร้า IB-BASKET ตามลำดับนี้
เพราะ warehouse `cal-cart-outbound` รับแค่ `picking_codes` (ส่ง `order_codes` = data ว่าง → document 500)

1. `01 Get Outbounds by Order`: order_code → outbound_code (ตั้ง var `outboundCode`)
2. `02 Get Picks by Outbound`: document_ref = outbound_code → picking_code (ตั้ง var `pickingCode`)
3. `03 Print IB-BASKET by Picking`: ส่ง `picking_codes` → PDF

รัน: `npx @usebruno/cli@2 run Basket-Label-From-Order --env Crossmax-Main --env-var token=<jwt>` (จาก `prime-wms-document-core/`)
เปลี่ยน order ได้ด้วย `--env-var orderCode=<SO>`
