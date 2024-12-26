// Primary Launch Pad: -0.097207832014050, -74.557671876381
// VAB East Helipad:   -0.096799940126847, -74.617417864482
// Landing site north: -0.185407556445315, -74.472935604997
// Landing site west:  -0.195569576365325, -74.485179404773
// Landing site south: -0.205672396373067, -74.473056581505
// Landing site mid:   -0.195555039290476, -74.473845384726

// LS North Middle: -0.185407556445315, -74.472935604997
// LS North North: -0.187407556445315, -74.472935604997
// LS North East: -0.185407556445315, -74.452935604997
// LS North South: -0.183407556445315, -74.472935604997
// LS North West: -0.185407556445315, -74.492935604997

SET targetSite to LATLNG(-0.185407556445315, -74.472935604997).

SET PitchMultiplierMultiplier to 0.0005. // Lower value means less aggressive pitch control
SET EstThrottleInSuicideBurn to 2. // What percentage of throttle is used during the final burn, this is used to estimate offset before the burn
SET OverEstThrottleInSuicideBurn to 0.90. // Get Suicide Burn functions are a little off, just give them a bigger value
SET craftHeight to 12.1.
SET AeroControlThreshold to 80. // Below this velocity, propulsive control is used in the final burn, above, aero control
SET DirectionErrorPreBoostbackBurn to 30. // How many degrees away from the boostback burn heading we can be when starting the engine

CLEARSCREEN.
PRINT "WAITING FOR ACTION GROUP 10" at (0, 0).

UNTIL AG10 {}

run HelperFunctions.

CLEARSCREEN.
PRINT "ASCENT" at (0, 0).

SET initialStageNum to SHIP:STAGENUM.

STAGE.

SET maxTWR to 1.9.

UNTIL SHIP:ALTITUDE > 30000 {
    SET targetBearing to 90.
    SET targetPitch to LERP(90, 45, CLAMP(SHIP:ALTITUDE, 0, 25000)/25000).
    SET targetRoll to LERP(-90, 0, CLAMP(SHIP:ALTITUDE, 0, 2000)/2000).
    LOCK STEERING TO HEADING(targetBearing, targetPitch, targetRoll).
    
    SET throttleValue to CLAMP(maxTWR/(SHIP:AVAILABLETHRUST/SHIP:MASS/10), 0, 1).
    LOCK THROTTLE to throttleValue.

    PrintValue("Bearing", targetBearing, 2).
    PrintValue("Pitch", targetPitch, 3).
    PrintValue("Roll", targetRoll, 4).

    PrintValue("Max TWR", SHIP:AVAILABLETHRUST/SHIP:MASS/10, 6).
    PrintValue("Current TWR", SHIP:THRUST/SHIP:MASS/10, 7).
    PrintValue("Throttle", throttleValue, 8).

    PrintValue("Ship Mass", SHIP:MASS, 10).

    PrintValue("Stage Num", SHIP:STAGENUM, 12).
    PrintValue("Initial Stage Num", initialStageNum, 13).

    IF (SHIP:MASS < 35.5 and SHIP:STAGENUM >= initialStageNum - 1) {
        LOCK STEERING TO srfPrograde.
        WAIT 2.5.
        STAGE.
        LOCK STEERING TO HEADING(targetBearing, targetPitch, -90).
        WAIT 0.5.
    }
}

CLEARSCREEN.

LOCK THROTTLE TO 0.7.
LOCK STEERING TO HEADING(targetBearing, targetPitch, 0).

PRINT "HOLDING ATTITUDE" at (0, 1).
UNTIL SHIP:ALTITUDE > 45000 { PRINT "WAITING FOR 45km ALTITUDE FOR FAIRING DEPLOY" at (0, 0). }

// Staging doesn't work on non-active (not looking at) vessels, so action groups are the way to go
Toggle AG6.

CLEARSCREEN.

UNTIL ORBIT:apoapsis > 77000 { PRINT "WAITING FOR 77km AP FOR STAGING" at (0, 0). }

LOCK THROTTLE TO 0.

Toggle AG7.
WAIT 0.5.

run Land.
