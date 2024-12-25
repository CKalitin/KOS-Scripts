// Primary Launch Pad: -0.097207832014050, -74.557671876381
// VAB East Helipad:   -0.096799940126847, -74.617417864482
// Landing site north: -0.185407556445315, -74.472935604997
// Landing site west:  -0.195569576365325, -74.485179404773
// Landing site south: -0.205672396373067, -74.473056581505
// Landing site mid:   -0.195555039290476, -74.473845384726
SET targetSite to LATLNG(-0.205672396373067, -74.473056581505).

SET PitchMultiplierMultiplier to 0.006. // Lower value means less aggressive pitch control
SET EstThrottleInSuicideBurn to 1. // What percentage of throttle is used during the final burn, this is used to estimate offset before the burn
SET OverEstThrottleInSuicideBurn to 0.90. // Get Suicide Burn functions are a little off, just give them a bigger value
SET craftHeight to 2.3.
SET AeroControlThreshold to 80. // Below this velocity, propulsive control is used in the final burn, above, aero control

// Wait until booster separation
SET initialStageNum to SHIP:STAGENUM.
UNTIL SHIP:STAGENUM < initialStageNum - 1 { }

// Don't want to hit the center core after separation
WAIT 3.

run Land.
