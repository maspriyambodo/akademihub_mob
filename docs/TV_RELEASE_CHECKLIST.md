# TV release gate — 10 September 2026

Status: **NO-GO pending device/build/integration validation**. Source changes only; no production migration/deployment performed.

## Implemented

- Calendar requires explicit `metadata.is_public_display: true`, active status, same school, no role/class/department targeting. Default deny. Configure via calendar form.
- Forum publication requires `forum.moderate`; edits by non-moderators remove publication. Datetimes cast immutable; date range validated. Publication form sends actual `judul`/`konten` API fields.
- Web `/tv-pair`, sidebar Kelola TV: approve, list paginated school devices, revoke. Requires `tv-device.manage`. Login first on the correct school web host, then open Kelola TV. Set backend `TV_PAIR_URL` (mapped to `app.tv_pair_url`) to the deployed web route.
- Snapshot school identity restored; izin counts as absent, not late. Lateness remains zero until a real arrival-time policy/source exists.
- Active snapshot expires at 24h including resume; HTTP 304 renews validated cache; no conditional fetch without an active snapshot. Cache version changed to exclude pre-fix cached content.
- Left/right slides, Back exit confirmation, idle pause, lifecycle polling, TV-only keep-awake. School clock/calendar use server UTC offset (offline DST transitions are not recalculated).
- Release no longer uses debug signing. Supply ignored `android/key.properties`: `storeFile` (absolute keystore path recommended), `storePassword`, `keyAlias`, `keyPassword`. Missing configuration fails release tasks. Do not commit secrets.

## Checks executed

- Standalone PostgreSQL 16 regression: calendar visibility, tenant filter, soft-delete, immutable forum dates. Disposable `--network none` PostgreSQL, PHP shares only its network namespace; no production DB config loaded.
- Frontend production build passed in tmpfs; chunk-size warning remains.
- Frontend targeted tests: 16 passed. ESLint: zero errors, existing hook/refresh warnings.
- PHP syntax checks passed. New clock-controlled Flutter regression covers active expiry at 24h and startup after 25h; **not executed** (Flutter/Dart unavailable).

Standalone DB check: `/home/bodo/prod-app/akademihub/be/tests/tv_postgres_check.php`. Requires `TV_TEST_HOST=127.0.0.1`, `TV_TEST_DATABASE=tv_test`, disposable PostgreSQL credentials `tv_test`, and Composer autoload. It creates TEMP tables inside a rolled-back transaction; never run against production.

## Required before release

1. Install dev dependencies in an isolated workspace; run full Laravel TV feature suite against PostgreSQL, including real control/tenant schema isolation and pairing races. Standalone check is not a substitute. Apply existing TV migrations only to disposable/staging DB first.
2. Run `flutter analyze`, `flutter test test/features/tv`, release APK/AAB build with real signing secrets; verify certificate fingerprint. No release artifact has been built here.
3. Finish/validate full classroom presentation (class identity, active/next labels, public materials), 24sp body/22sp labels, 720p/1080p/4K layout. Current typography/layout does not yet meet the full specification.
4. Physical TV: Leanback launch, correct school host pairing, D-pad focus/Enter/Back/dialogs, idle 30s, standby/resume, keep-awake, revoked token, reboot, HTTP 304 recovery, wrong device timezone.
5. Physical offline soak: sync, disconnect >24h without closing app; confirm content disappears at expiry and stays hidden after standby/reboot; reconnect and verify full refresh. Verify publication end times during offline operation; per-item expiry still needs acceptance testing.
6. Verify web login/tenant routing, moderation authorization, audit trail and cross-school revoke. No physical TV/ADB available in this environment.