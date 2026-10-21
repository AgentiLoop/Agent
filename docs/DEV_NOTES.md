
## Compaction threshold cap (2026-09-22)
Kimi K3 / 1M-window providers looped on compaction because threshold was 50% of
the *advertised* window (1M → 500K). Fixed by capping the window used for the
threshold at 256K → all big windows compact at 128K. See CompactionState.compactionWindowCap.
The symptom "threshold 16000" was the local 32_000 fallback window (threshold
0.5×32K = 16K) firing when a model's real/fetched window hadn't landed yet, or
when a provider never reports a per-model window.
