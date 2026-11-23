# Group (Customer Permission / Master)

ลำดับรัน: login ที่ `prime-wms-authentication-core/Auth/Login` เอา token แล้วรัน

```
npx @usebruno/cli@2 run Group --env Dev --env-var token=<token>
```

1. `Get Group` — หน้า Permission ต้องไม่มี CGnn
2. `Create Group - Reserved CG` — ต้องได้ 500 reserved (ไม่เขียนข้อมูล)
3. `Get Customer Group Master List` — master ยังตอบ 200

ห้ามใส่ token ลงไฟล์ (repo เป็น public)
