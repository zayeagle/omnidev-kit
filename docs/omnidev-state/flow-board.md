# OmniDev Flow Board

- status: idle
- mode: manual
- current: Phase 0

| Phase | Name | State |
|-------|------|-------|
| 0 | Assessment | pending |
| 1 | Blueprint | pending |
| 2 | Planning | pending |
| 3 | Development | pending |
| 4 | Testing | pending |
| 5 | Deploy | pending |

## Controls

- Open: `/od board` or `$od board`
- Start (default manual): `/od board start --mode manual`
- Autopilot: `/od board start --mode auto`
- Skip optional phases: `/od board start --skip 1,5`
- Next (manual pause): `/od board next`
- Reset: `/od board reset`

Required phases **0** and **3** cannot be skipped. Hard gates (`b0_confirm`, `deploy_prod`, manual `security_iterate_confirm`) always confirm. Autopilot soft-picks security iterate on FAIL.
