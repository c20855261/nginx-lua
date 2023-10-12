# nginx-lua

此配置為nginx使用lua模組+redis

用途: nginx 代理，偵測一段時間內次數達到幾次後，自動加入黑名單

---
目錄: lua-conf
白名單: whitelist.txt
黑名單lua配置檔: block_ip.lua

---
nginx 配置
目錄: config

---
note:
nginx.conf內
resolver 127.0.0.11 valid=30s; #Docker 中的 DNS 服务器的默认 IP 地址
此配置使用docker需配置，不然lua config配置的redis host會抓不到
