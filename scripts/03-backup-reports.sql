-- =====================================================
-- BLM4522 Proje 7: Yedekleme Raporları ve İzleme
-- =====================================================

\echo '=============================='
\echo '  YEDEKLEME RAPORLARI'
\echo '=============================='

-- =====================================================
-- 1. YEDEKLEME GEÇMİŞİ
-- =====================================================

\echo ''
\echo '=== 1. Yedekleme Geçmişi ==='

SELECT
    backup_id,
    backup_type AS tip,
    file_name AS dosya,
    pg_size_pretty(file_size_bytes) AS boyut,
    start_time::timestamp(0) AS baslangic,
    duration_seconds || 's' AS sure,
    status AS durum,
    tables_count AS tablo,
    rows_count AS satir
FROM backup_history
ORDER BY start_time DESC
LIMIT 20;

-- =====================================================
-- 2. BAŞARI İSTATİSTİKLERİ
-- =====================================================

\echo ''
\echo '=== 2. Başarı İstatistikleri ==='

SELECT
    backup_type AS tip,
    COUNT(*) AS toplam,
    COUNT(*) FILTER (WHERE status = 'success') AS basarili,
    COUNT(*) FILTER (WHERE status = 'failed') AS basarisiz,
    round(100.0 * COUNT(*) FILTER (WHERE status = 'success') / COUNT(*), 1) AS basari_orani,
    round(AVG(duration_seconds)::numeric, 1) AS ort_sure_sn,
    pg_size_pretty(AVG(file_size_bytes)::bigint) AS ort_boyut
FROM backup_history
WHERE status != 'running'
GROUP BY backup_type;

-- =====================================================
-- 3. GÜNLÜK YEDEKLEME ÖZETİ
-- =====================================================

\echo ''
\echo '=== 3. Günlük Yedekleme Özeti ==='

SELECT
    start_time::date AS tarih,
    COUNT(*) AS backup_sayisi,
    COUNT(*) FILTER (WHERE status = 'success') AS basarili,
    COUNT(*) FILTER (WHERE status = 'failed') AS basarisiz,
    pg_size_pretty(SUM(file_size_bytes)) AS toplam_boyut,
    SUM(duration_seconds) || 's' AS toplam_sure
FROM backup_history
GROUP BY start_time::date
ORDER BY tarih DESC
LIMIT 7;

-- =====================================================
-- 4. UYARI RAPORU
-- =====================================================

\echo ''
\echo '=== 4. Son Uyarılar ==='

SELECT
    alert_id,
    alert_time::timestamp(0) AS zaman,
    severity AS seviye,
    LEFT(message, 80) AS mesaj,
    CASE WHEN acknowledged THEN 'Onaylandı' ELSE 'Bekliyor' END AS durum
FROM backup_alerts
ORDER BY alert_time DESC
LIMIT 15;

\echo ''
\echo 'Uyarı özeti:'
SELECT
    severity AS seviye,
    COUNT(*) AS toplam,
    COUNT(*) FILTER (WHERE NOT acknowledged) AS onaylanmamis
FROM backup_alerts
GROUP BY severity
ORDER BY CASE severity WHEN 'CRITICAL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END;

-- =====================================================
-- 5. POLİTİKA UYUM RAPORU
-- =====================================================

\echo ''
\echo '=== 5. Politika Uyum Raporu ==='

SELECT
    p.policy_name AS politika,
    p.schedule AS zamanlama,
    p.retention_days || ' gün' AS saklama,
    COALESCE(h.son_backup::text, 'HİÇ') AS son_backup,
    COALESCE(h.backup_sayisi::text, '0') AS toplam_backup,
    CASE
        WHEN h.son_backup IS NULL THEN '⚠ HİÇ YEDEK YOK'
        WHEN h.son_backup < NOW() - INTERVAL '1 day' * 2 THEN '⚠ GECİKMİŞ'
        ELSE '✓ GÜNCEL'
    END AS durum
FROM backup_policy p
LEFT JOIN (
    SELECT
        backup_type,
        MAX(start_time) AS son_backup,
        COUNT(*) AS backup_sayisi
    FROM backup_history
    WHERE status = 'success'
    GROUP BY backup_type
) h ON p.backup_type = h.backup_type
WHERE p.is_active = true;

-- =====================================================
-- 6. DİSK KULLANIM TAHMİNİ
-- =====================================================

\echo ''
\echo '=== 6. Disk Kullanım Tahmini ==='

SELECT
    backup_type AS tip,
    COUNT(*) AS mevcut_yedek,
    pg_size_pretty(SUM(file_size_bytes)) AS toplam_boyut,
    pg_size_pretty(AVG(file_size_bytes)::bigint) AS ort_boyut,
    pg_size_pretty((AVG(file_size_bytes) * (SELECT retention_days FROM backup_policy bp WHERE bp.backup_type = bh.backup_type LIMIT 1))::bigint) AS tahmini_max_boyut
FROM backup_history bh
WHERE status = 'success'
GROUP BY backup_type;

\echo ''
\echo '=============================='
\echo '  RAPORLAR TAMAMLANDI'
\echo '=============================='
