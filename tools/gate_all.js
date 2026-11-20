#!/usr/bin/env node
/* Runs both repo gates and fails if either one fails. */
const path = require('path');
const { spawnSync } = require('child_process');

let failed = false;
for (const script of ['gate_no_literals.js', 'gate_no_status_switch.js']) {
  const result = spawnSync(process.execPath, [path.join(__dirname, script)], {
    stdio: 'inherit',
  });
  if (result.status !== 0) failed = true;
}
process.exitCode = failed ? 1 : 0;
