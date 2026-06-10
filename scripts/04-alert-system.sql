-- =====================================================
-- BLM4522 Proje 7: Uyarı ve Bildirim Sistemi
-- Başarısız yedeklemelerde otomatik uyarı
-- =====================================================

\echo '=============================='
\echo '  UYARI SİSTEMİ'
\echo '=============================='

-- =====================================================
-- 1. UYARI FONKSİYONU
-- =====================================================

\echo ''
\echo '=== 1. Uyarı Fonksiyonları ==='

-- Yedekleme kontrolü: Son 24 saatte backup alınmış mı?
CREATE OR REPLACE FUNCTION check_backup_status()
RETURNS TABLE (
    policy_name VARCHAR,
    status TEXT,
    severity TEXT,
    message TEXT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.policy_name,
        CASE
            WHEN h.son IS NULL THEN 'CRITICAL'
            WHEN h.son < NOW() - INTERVAL '2 days' THEN 'WARNING'
            ELSE 'OK'
        END,
        CASE
            WHEN h.son IS NULL THEN 'CRITICAL'
            WHEN h.son < NOW() - INTERVAL '2 days' THEN 'WARNING'
            ELSE 'INFO'
        END,
        CASE
            WHEN h.son IS NULL THEN p.policy_name || ': HİÇ YEDEK ALINMAMIŞ!'
            WHEN h.son < NOW() - INTERVAL '2 days' THEN p.policy_name || ': Son yedek ' || h.son::date || ' tarihli, gecikmiş!'
            ELSE p.policy_name || ': Güncel (' || h.son::timestamp(0) || ')'
        END
    FROM backup_policy p
    LEFT JOIN (
        SELECT backup_type, MAX(start_time) AS son
        FROM backup_history WHERE status = 'success'
        GROUP BY backup_type
    ) h ON p.backup_type = h.backup_type
    WHERE p.is_active = true;
END; $$;

\echo 'Yedekleme durumu kontrolü:'
SELECT * FROM check_backup_status();

-- =====================================================
-- 2. BAŞARISIZ BACKUP TRİGGER
-- =====================================================

\echo ''
\echo '=== 2. Otomatik Uyarı Trigger ==='

CREATE OR REPLACE FUNCTION notify_backup_failure()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status = 'failed' THEN
        INSERT INTO backup_alerts (severity, message, backup_id)
        VALUES ('CRITICAL',
            'BACKUP BAŞARISIZ! Dosya: ' || NEW.file_name ||
            ', Hata: ' || COALESCE(NEW.error_message, 'Bilinmiyor'),
            NEW.backup_id);

        -- PostgreSQL NOTIFY ile anlık bildirim
        PERFORM pg_notify('backup_alerts',
            json_build_object(
                'severity', 'CRITICAL',
                'backup_id', NEW.backup_id,
                'file', NEW.file_name,
                'error', NEW.error_message
            )::text);

        RAISE NOTICE 'UYARI: Backup başarısız! ID: %, Dosya: %', NEW.backup_id, NEW.file_name;
    END IF;

    -- Başarılı backup sonrası boyut kontrolü
    IF NEW.status = 'success' AND NEW.file_size_bytes IS NOT NULL THEN
        -- Ortalama boyutun 2 katından büyükse uyar
        DECLARE
            avg_size BIGINT;
        BEGIN
            SELECT AVG(file_size_bytes) INTO avg_size
            FROM backup_history
            WHERE backup_type = NEW.backup_type AND status = 'success'
            AND backup_id != NEW.backup_id;

            IF avg_size IS NOT NULL AND NEW.file_size_bytes > avg_size * 2 THEN
                INSERT INTO backup_alerts (severity, message, backup_id)
                VALUES ('WARNING',
                    'Backup boyutu normalden büyük! ' ||
                    pg_size_pretty(NEW.file_size_bytes) || ' (ortalama: ' || pg_size_pretty(avg_size) || ')',
                    NEW.backup_id);
            END IF;
        END;
    END IF;

    RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_backup_notify ON backup_history;
CREATE TRIGGER trg_backup_notify
    AFTER UPDATE OF status ON backup_history
    FOR EACH ROW
    EXECUTE FUNCTION notify_backup_failure();

\echo 'Trigger oluşturuldu: trg_backup_notify'

-- =====================================================
-- 3. BAŞARISIZ BACKUP SİMÜLASYONU
-- =====================================================

\echo ''
\echo '=== 3. Başarısız Backup Simülasyonu ==='

-- Başarısız backup kaydı ekle
INSERT INTO backup_history (backup_type, file_name, start_time, end_time, duration_seconds, status, error_message)
VALUES ('full', 'daily/backup_FAILED.dump', NOW(), NOW(), 0, 'failed', 'Disk alanı yetersiz: No space left on device');

\echo 'Başarısız backup simüle edildi. Uyarılar:'
SELECT alert_id, severity, message
FROM backup_alerts
WHERE severity = 'CRITICAL'
ORDER BY alert_time DESC LIMIT 5;

-- =====================================================
-- 4. UYARI ONAYLAMA
-- =====================================================

\echo ''
\echo '=== 4. Uyarı Yönetimi ==='

-- Onaylanmamış uyarılar
\echo 'Onaylanmamış uyarılar:'
SELECT alert_id, severity, alert_time::timestamp(0), LEFT(message, 60) AS mesaj
FROM backup_alerts
WHERE acknowledged = false
ORDER BY alert_time DESC;

-- Uyarıları onayla
UPDATE backup_alerts SET acknowledged = true
WHERE acknowledged = false AND severity = 'INFO';

\echo ''
\echo 'INFO uyarıları onaylandı.'

\echo ''
\echo '=============================='
\echo '  UYARI SİSTEMİ TAMAMLANDI'
\echo '=============================='
