-- 27_autovacuum_bank_transactions.sql
--
-- bank_transactions adalah tabel paling sibuk: satu baris per transaksi
-- (pemain maupun bot) dan retensi WorldTick menghapusnya lagi di batas hari.
-- Dengan setelan default (scale factor 0.2) autovacuum baru jalan setelah
-- ~20% baris mati — diamati di prod: ~468k baris hidup vs ~49k mati, jadi
-- ruang mati bisa menumpuk sampai ~90k tuple sebelum dibersihkan.
--
-- Turunkan ambang khusus tabel ini (0.05 → mulai sekitar ~23k mati). Hanya
-- storage parameter: tidak mengubah skema maupun data, dan idempoten
-- (dijalankan ulang hanya menulis nilai yang sama).
ALTER TABLE bank_transactions SET (
  autovacuum_vacuum_scale_factor = 0.05,
  autovacuum_analyze_scale_factor = 0.02
);
