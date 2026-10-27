# Master-Config

ใช้ตรวจว่า master_config ของหน้า Product Group (insert ของ Crossmax) มีผลจริงหรือไม่
- Crossmax: คาดหวัง `actions` มี `HIDE_FIELD` ทั้ง `parent_group` (HEADER) และ `parent_group_name` (ITEM)
- Thaimetal: คาดหวังไม่มี action

`Get Master Config Crossmax Hide Actions` ตรวจ row ที่ซ่อนเมนู/ปุ่มในหน้า list (Plan GR, GR, Customer Return, Packing, STO)
- Crossmax: คาดหวัง `HIDE_FIELD` ครบทั้ง 8 field หลังรัน `prime-wms-authentication-core/seeds/Crossmax-uat|Crossmax-main/20261027170000_hide_crossmax_list_actions.sql`
- env อื่น: คาดหวังไม่มี action

endpoint อยู่ใน auth service (นอก repo prime-wms) ผ่าน `{{AUTH_URL}}`
(Local ใช้ gateway ของ Dev เพราะไม่ทราบพอร์ต auth service ในเครื่อง)

## รัน

```bash
cd prime-wms-product-core
npx @usebruno/cli@2 run Master-Config --env Dev --env-var <tokenVarName>=<token>
```

ส่ง token ตอนรันผ่าน `--env-var` เท่านั้น ห้าม commit token ลง repo (repo เป็น PUBLIC)
