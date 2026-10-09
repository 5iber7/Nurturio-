# Data model

| Model | Local representation | Cloud representation |
| --- | --- | --- |
| Profile | UUID and age band in aggregate save | UUID and owner account |
| Settings | Reading, pace, accessibility, sound, reminders, session limit | Selected non-sensitive preferences in snapshot |
| Topic/Quest | Versioned JSON pack and stable ID | Published content-version metadata |
| ProcessInstance | State, action count, started/ready/observed UTC times, content version | Bounded snapshot entries |
| Progress | Unique completed quest IDs | Revisioned merged snapshot |
| Rewards | Local XP/coin counters and completed IDs | Unique per-profile quest ledger |
| Inventory/collection | Unlocked quest knowledge, four topic badges, earned decorations | Quest ledger and decoration ownership |
| ScanResult | Validated result/manual library entry, date, local journal | Disabled by default; optional schema reserved |
| ChatMessage | Bounded in-memory curated conversation | Not stored |
| SyncOperation | UUID and pending snapshot in SQLite outbox | Idempotent result keyed by profile and operation |
| ConsentState | Local-only; minors denied restricted services | Server-managed permission/consent records |

The SQLite schema has a save row and operation outbox. The aggregate payload has `schemaVersion: 1`; unsupported future saves fail with recovery instructions rather than being deleted. PostgreSQL applies explicit foreign keys, reward bounds, unique keys and ownership checks.

All timers are UTC. Streak display follows the device's local calendar and is not an authoritative cloud metric. Settings are not authorization claims. Photos are excluded from synchronization. No full birth date, precise location or public profile is needed.
