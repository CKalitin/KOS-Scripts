// Primary Launch Pad: -0.097207832014050, -74.557671876381
// VAB East Helipad:   -0.096799940126847, -74.617417864482
// Landing site north: -0.185407556445315, -74.472935604997
// Landing site west:  -0.195569576365325, -74.485179404773
// Landing site south: -0.205672396373067, -74.473056581505
// Landing site mid:   -0.195555039290476, -74.473845384726
SET targetSite to LATLNG(-0.195555039290476, -74.473845384726).

SET PitchMultiplierMultiplier to 0.0005. // Lower value means less aggressive pitch control
SET EstThrottleInSuicideBurn to 0.7. // What percentage of throttle is used during the final burn, this is used to estimate offset before the burn
SET OverEstThrottleInSuicideBurn to 0.90. // Get Suicide Burn functions are a little off, just give them a bigger value
SET craftHeight to 12.1.
SET AeroControlThreshold to 80. // Below this velocity, propulsive control is used in the final burn, above, aero control

run HelperFunctions.

CLEARSCREEN.
PRINT "ASCENT" at (0, 0).

SET initialStageNum to SHIP:STAGENUM.

STAGE.

SET maxTWR to 1.85.

UNTIL SHIP:ALTITUDE > 22000 {
    SET targetBearing to 90.
    SET targetPitch to LERP(90, 45, SHIP:ALTITUDE/20000).
    LOCK STEERING TO HEADING(targetBearing, targetPitch).
    
    SET throttleValue to CLAMP(maxTWR/(SHIP:AVAILABLETHRUST/SHIP:MASS/10), 0, 1).
    LOCK THROTTLE to throttleValue.

    PrintValue("Bearing", targetBearing, 2).
    PrintValue("Pitch", targetPitch, 3).

    PrintValue("Max TWR", SHIP:AVAILABLETHRUST/SHIP:MASS/10, 5).
    PrintValue("Current TWR", SHIP:THRUST/SHIP:MASS/10, 6).
    PrintValue("Throttle", throttleValue, 7).

    PrintValue("Ship Mass", SHIP:MASS, 9).

    PrintValue("Stage Num", SHIP:STAGENUM, 11).
    PrintValue("Initial Stage Num", initialStageNum, 12).

    IF (SHIP:MASS < 37 and SHIP:STAGENUM >= initialStageNum - 1) {
        LOCK STEERING TO srfPrograde.
        WAIT 1.
        STAGE.
        LOCK STEERING TO HEADING(targetBearing, targetPitch).
        WAIT 0.5.
    }
}

LOCK STEERING TO HEADING(targetBearing, targetPitch).

UNTIL ORBIT:apoapsis > 60000 { PRINT "WAITING FOR 60km AP" at (0, 0). }

LOCK THROTTLE TO 0.

STAGE.
WAIT 1.
STAGE.

run Land.
