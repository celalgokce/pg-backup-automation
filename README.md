# Proje 7: Veritabanı Yedekleme ve Otomasyon Çalışması

## Amaç
Veritabanı yedekleme işlemlerini otomatikleştirmek, yedeklerin düzenli alındığını doğrulamak ve denetim/raporlama mekanizmaları kurmak.

## Kullanılan Teknolojiler
- PostgreSQL 16 (Docker)
- Bash Scripting (otomasyon)
- pg_dump / pg_restore
- cron / pg_cron
- PostgreSQL NOTIFY/LISTEN (bildirim)

## Kapsam
1. **Otomatik Yedekleme:** Bash script ile zamanlanmış yedekleme
2. **Yedekleme Raporları:** Her yedeklemenin detaylı log ve raporu
3. **Uyarı Sistemi:** Başarısız yedeklemelerde bildirim
4. **Denetim:** Yedek geçmişi, boyut takibi, retention yönetimi

## Kurulum
```bash
cd docker/
docker compose up -d
docker exec -i pg-auto psql -U admin -d autodb < ../scripts/01-setup-db.sql
```
