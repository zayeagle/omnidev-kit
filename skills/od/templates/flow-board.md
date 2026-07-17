# OmniDev Flow Board

- status: idle
- mode: manual
- autopilot: false
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
- **Full autopilot**: `/od auto` or `/od al` or `/od board run`
- Autopilot + requirement: `/od auto [requirement]`
- Skip optional phases: `/od board start --mode auto --skip 1,5`
- Next (manual pause): `/od board next`
- Reset: `/od board reset`

Required phases **0** and **3** cannot be skipped.
Hard gates (`b0_confirm`, `pre_dev` M/L/XL, `deploy_prod`, `test_gate_fail`) always confirm — then autopilot **resumes automatically**.
