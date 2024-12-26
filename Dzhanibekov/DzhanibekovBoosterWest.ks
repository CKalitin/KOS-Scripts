// Primary Launch Pad: -0.097207832014050, -74.557671876381
// VAB East Helipad:   -0.096799940126847, -74.617417864482
// Landing site north: -0.185407556445315, -74.472935604997
// Landing site west:  -0.195569576365325, -74.485179404773
// Landing site south: -0.205672396373067, -74.473056581505
// Landing site mid:   -0.195555039290476, -74.473845384726

// LS North Middle: -0.185407556445315, -74.472935604997
// LS North North: -0.187007556445315, -74.472035604997
// LS North East: -0.185407556445315, -74.471285604997
// LS North South: -0.183807556445315, -74.472035604997
// LS North West: -0.185407556445315, -74.475385604997

SET targetSite to LATLNG(-0.185407556445315, -74.475385604997).

SET PitchMultiplierMultiplier to 0.002. // Lower value means less aggressive pitch control
SET EstThrottleInSuicideBurn to 1.5. // What percentage of throttle is used during the final burn, this is used to estimate offset before the burn
SET OverEstThrottleInSuicideBurn to 1. // Get Suicide Burn functions are a little off, just give them a bigger value
SET craftHeight to 2.3.
SET AeroControlThreshold to 80. // Below this velocity, propulsive control is used in the final burn, above, aero control
SET DirectionErrorPreBoostbackBurn to 90. // How many degrees away from the boostback burn heading we can be when starting the engine

CLEARSCREEN.

PRINT "WAITING FOR STAGING" at (0, 0).

UNTIL SHIP:MASS < 35.5 {}
WAIT 2.6.

Print "STAGED                 " at (0, 0).

LOCK THROTTLE TO 0.

// Don't want to hit the center core after separation
WAIT 0.5.

run Land.
