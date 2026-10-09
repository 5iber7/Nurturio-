# Data inventory and retention

| Data | Location | Default retention/deletion |
| --- | --- | --- |
| Progress/preferences | Local SQLite | Until parent deletion or device/app data removal |
| Preview photo | Screen memory | Released after leaving/retaking; not uploaded by default |
| Manual journal entries | Local SQLite | Up to 50 entries; removed with local data |
| Curated chat | Screen memory | Up to 20 messages; released with screen/session |
| Adult auth session | Platform secure storage | Until sign-out or credential removal |
| Parent PIN hash/salt | Platform secure storage | Separate from game save; app/device secure-data cleanup |
| Cloud progress | Supabase private rows | Until account deletion; actual backup retention depends on plan |
| Sync idempotency records | Supabase | Production retention/compaction policy required before cloud launch |
| AI quota counters | Private database table | Production expiry cleanup required before live AI launch |

Deleting local progress clears local save/outbox, journal and reminders. The parent PIN remains to protect setup; this behavior must be explained in support guidance. It does not delete a cloud account.

Cloud deletion marks the account as deleting, removes owned Storage objects, revokes sessions, and removes Auth identity with cascading application rows. Test interruption and retry against the deployed service. Provider logs/backups may have separate retention; no promise of immediate deletion from those systems is made.
