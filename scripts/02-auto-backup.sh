#!/bin/bash
# =====================================================
# BLM4522 Proje 7: Otomatik Yedekleme Scripti
# Her çalıştığında backup alır ve sonucu DB'ye kaydeder
# =====================================================

DB_NAME="autodb"
DB_USER="admin"
BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/backups/backup.log"

mkdir -p "$BACKUP_DIR/daily" "$BACKUP_DIR/schema" "$BACKUP_DIR/tables"

echo "=========================================" | tee -a $LOG_FILE
echo "  OTOMATİK YEDEKLEME - $(date)" | tee -a $LOG_FILE
echo "=========================================" | tee -a $LOG_FILE

# --- 1. Başlangıç kaydı oluştur ---
START_TIME=$(date +%s)
BACKUP_FILE="daily/backup_${TIMESTAMP}.dump"

psql -U $DB_USER -d $DB_NAME -t -c "
INSERT INTO backup_history (backup_type, file_name, start_time, status)
VALUES ('full', '$BACKUP_FILE', NOW(), 'running')
RETURNING backup_id;" > /tmp/backup_id.txt

BACKUP_ID=$(cat /tmp/backup_id.txt | tr -d ' ')
echo "[INFO] Backup ID: $BACKUP_ID" | tee -a $LOG_FILE

# --- 2. Tablo ve satır sayısını al ---
TABLES=$(psql -U $DB_USER -d $DB_NAME -t -c "
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';")

ROWS=$(psql -U $DB_USER -d $DB_NAME -t -c "
SELECT SUM(n_live_tup) FROM pg_stat_user_tables;")

# --- 3. Backup al ---
echo "[INFO] Full backup alınıyor..." | tee -a $LOG_FILE
pg_dump -U $DB_USER -d $DB_NAME -Fc -f "$BACKUP_DIR/$BACKUP_FILE" 2>> $LOG_FILE

RESULT=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ $RESULT -eq 0 ]; then
    FILE_SIZE=$(stat -c%s "$BACKUP_DIR/$BACKUP_FILE" 2>/dev/null || stat -f%z "$BACKUP_DIR/$BACKUP_FILE" 2>/dev/null)
    STATUS="success"
    echo "[SUCCESS] Backup tamamlandı: $BACKUP_FILE ($(numfmt --to=iec $FILE_SIZE 2>/dev/null || echo "${FILE_SIZE} bytes"))" | tee -a $LOG_FILE

    # Başarı kaydını güncelle
    psql -U $DB_USER -d $DB_NAME -c "
    UPDATE backup_history SET
        end_time = NOW(),
        duration_seconds = $DURATION,
        status = 'success',
        file_size_bytes = $FILE_SIZE,
        tables_count = $TABLES,
        rows_count = $ROWS
    WHERE backup_id = $BACKUP_ID;"

    # Info alert
    psql -U $DB_USER -d $DB_NAME -c "
    INSERT INTO backup_alerts (severity, message, backup_id)
    VALUES ('INFO', 'Backup başarılı: $BACKUP_FILE ($DURATION saniye)', $BACKUP_ID);"
else
    STATUS="failed"
    echo "[ERROR] Backup başarısız!" | tee -a $LOG_FILE

    # Hata kaydını güncelle
    psql -U $DB_USER -d $DB_NAME -c "
    UPDATE backup_history SET
        end_time = NOW(),
        duration_seconds = $DURATION,
        status = 'failed',
        error_message = 'pg_dump exit code: $RESULT'
    WHERE backup_id = $BACKUP_ID;"

    # Critical alert
    psql -U $DB_USER -d $DB_NAME -c "
    INSERT INTO backup_alerts (severity, message, backup_id)
    VALUES ('CRITICAL', 'BACKUP BAŞARISIZ! Dosya: $BACKUP_FILE, Hata kodu: $RESULT', $BACKUP_ID);"
fi

# --- 4. Schema backup ---
echo "[INFO] Schema backup alınıyor..." | tee -a $LOG_FILE
SCHEMA_FILE="schema/schema_${TIMESTAMP}.sql"
pg_dump -U $DB_USER -d $DB_NAME --schema-only -f "$BACKUP_DIR/$SCHEMA_FILE"

psql -U $DB_USER -d $DB_NAME -c "
INSERT INTO backup_history (backup_type, file_name, start_time, end_time, duration_seconds, status, file_size_bytes)
VALUES ('schema', '$SCHEMA_FILE', NOW() - INTERVAL '1 second', NOW(), 1, 'success',
    $(stat -c%s "$BACKUP_DIR/$SCHEMA_FILE" 2>/dev/null || stat -f%z "$BACKUP_DIR/$SCHEMA_FILE" 2>/dev/null || echo 0));"

# --- 5. Eski backupları temizle (retention policy) ---
echo "[INFO] Retention policy uygulanıyor..." | tee -a $LOG_FILE
RETENTION_DAYS=$(psql -U $DB_USER -d $DB_NAME -t -c "
SELECT retention_days FROM backup_policy WHERE policy_name = 'Günlük Full Backup';")
RETENTION_DAYS=$(echo $RETENTION_DAYS | tr -d ' ')

DELETED=$(find "$BACKUP_DIR/daily" -name "*.dump" -mtime +${RETENTION_DAYS:-7} -delete -print | wc -l)
echo "[INFO] $DELETED eski backup silindi (>${RETENTION_DAYS} gün)" | tee -a $LOG_FILE

if [ "$DELETED" -gt 0 ]; then
    psql -U $DB_USER -d $DB_NAME -c "
    INSERT INTO backup_alerts (severity, message)
    VALUES ('INFO', '$DELETED adet eski backup temizlendi (retention: ${RETENTION_DAYS} gün)');"
fi

# --- 6. Özet ---
echo "" | tee -a $LOG_FILE
echo "=========================================" | tee -a $LOG_FILE
echo "  ÖZET" | tee -a $LOG_FILE
echo "  Durum: $STATUS" | tee -a $LOG_FILE
echo "  Süre: ${DURATION}s" | tee -a $LOG_FILE
echo "  Tablolar: $TABLES" | tee -a $LOG_FILE
echo "  Satırlar: $ROWS" | tee -a $LOG_FILE
echo "=========================================" | tee -a $LOG_FILE
