#!/usr/bin/env bash
# login Crossmax-main แล้วเก็บ token ไว้ที่ ~/.crossmax-main-token (ไม่แสดง password/token บนจอ)
set -euo pipefail
read -rp "user_code: " U
read -rsp "password: " P; echo
curl -fsS -X POST https://crossmax.prime-solution.cc/api/authentication/authen/login \
  -H 'Content-Type: application/json' \
  -d "$(jq -n --arg u "$U" --arg p "$P" '{user_code:$u,password:$p}')" \
  | jq -er .token > ~/.crossmax-main-token
chmod 600 ~/.crossmax-main-token
echo "saved ~/.crossmax-main-token"
