// TODO: Redo variables in loop with Lock instead of set, this is how kOS is meant to be used, this is a full refactor and messes up printing (printing needs to be done better anyway)
// Also, 0.1 tick length does not mean 10 ticks is one second

// Primary Launch Pad: -0.0972078320140506, -74.5576718763811
// Landing site north: -0.185407556445315, -74.4729356049979
// VAB East Helipad:   -0.0967999401268479, -74.617417864482
SET targetSite to LATLNG(-0.0967999401268479, -74.617417864482).

SET flightPhase to 0.
SET tickLength to 0.1.

SET pitchLimit to 45.
SET craftHeight to 7. // Adjust to true radar altitude, not quite full craft height just where its controlled from

SET ImpactPos to SHIP:GEOPOSITION.
SET TargetPosAltituide to 0. // Altitude of impact point (used for aerodynamic control to a point above the surface)
SET TargetPos to V(targetSite:LAT, targetSite:LNG, 0). // This is the adjusted landing site, used for aerodynamic control above ~5km
SET TrueAltituide to 0.

SET impactToTargetDir to 100.
SET impactToTargetDistance to 100.
SET changeInDistanceToTargetPerSecond to 100.
SET previousImpactToTargetDistance to 100.

SET suicideBurnLength to 100.
SET suicideBurnAltError to 100.
SET previousSuicideBurnAltError to 100.
SET changeInSuicudeBurnAltError to 100.

SET TargetVerticalVelocity to 0.
SET ChangeInVerticalVelocity to 1.
SET previousVerticalVelocity to 1.

SET RetrogradePitch to 100.
SET RetrogradeBearing to 100.

run HelperFunctions.

CLEARSCREEN.
CLEARVECDRAWS().

SET gear to false.
StartReorientationForBoostbackBurn().

UNTIL false {
    // If impact or zero key pressed, stop the script
    if NOT ADDONS:TR:HASIMPACT { LOCK THROTTLE TO 0. CLEARSCREEN. BREAK. }
    if AG10 { LOCK THROTTLE TO 0. CLEARSCREEN. BREAK. }

    UpdateFlightVariables().

    drawLineToTarget().
    drawLineToImpact().

    if flightPhase = 0 {
        PRINT "Flight Phase: Orient For Boostback (1/6)" at (0, 0).

        OrientForBoostback().

        // Completion handled by function
    } else if flightPhase = 1 {
        PRINT "Flight Phase: Boostback (2/6)" at (0, 0).

        Boostback().

        // Completion handled by function
    } else if flightPhase = 2 {
        PRINT "Flight Phase: High Aerodynamic Control (3/6)" at (0, 0).

        SET pitchLimit to CLAMP((400/ship:velocity:surface:mag)*40, 0, 50). // Adjust pitch limit based on velocity

        GlideToTarget().

        if TrueAltituide < 4000 { GlideToLandingSite(). }
    } else if flightPhase = 3 {
        PRINT "Flight Phase: Final Aerodynamic Descent (4/6)" at (0, 0).

        GlideToTarget().

        PrintValue("Suicude Burn Alt Error", suicideBurnAltError, 11).
        if suicideBurnAltError < 0 { StartSuicideBurn(). } // If Suicide Burn is Required
    } else if flightPhase = 4 {
        PRINT "Flight Phase: Propulsive Descent (5/6)" at (0, 0).

        SET gear to TrueAltituide < 300.

        ControlSuicideBurn().

        if TrueAltituide < TargetPosAltituide OR ABS(ship:velocity:surface:mag) < 45 { StartTouchdown. }
    } else if flightPhase = 5{
        PRINT "Flight Phase: Soft Touchdown (6/6)" at (0, 0).

        SET gear to TrueAltituide < 300.

        SoftTouchdown().
    }
}

function UpdateFlightVariables{
    if TargetPosAltituide = 0 { SET ImpactPos to ADDONS:TR:IMPACTPOS. }
    else SET ImpactPos to GetLatLngAtAltitude(TargetPosAltituide, SHIP:OBT:ETA:PERIAPSIS, 1).

    SET TrueAltituide to alt:radar - craftHeight.

    SET suicideBurnLength to GetSuicideBurnLength().
    SET suicideBurnAltError to TrueAltituide - GetSuicudeBurnAltitude().
    SET changeInSuicudeBurnAltError to (previousSuicideBurnAltError - suicideBurnAltError) / tickLength.
    SET previousSuicideBurnAltError to suicideBurnAltError.

    local impactPosAsVector to V(ImpactPos:LAT, ImpactPos:LNG, 0).
    SET impactToTargetDistance to LatLngDist(impactPosAsVector, TargetPos).
    SET impactToTargetDir to DirToPoint(impactPosAsVector, TargetPos).
    
    SET changeInDistanceToTargetPerSecond to (previousImpactToTargetDistance - impactToTargetDistance) / tickLength.
    SET previousImpactToTargetDistance to impactToTargetDistance.

    SET ChangeInVerticalVelocity to -(previousVerticalVelocity - GetVerticalVelocity()) / tickLength.
    SET previousVerticalVelocity to GetVerticalVelocity().
    
    SET RetrogradePitch to 90 - vang(srfretrograde:forevector, up:forevector).
    SET RetrogradeBearing to GetRetrogradeBearing().
}

// - - - Flight Phase Control Functions - - - //
// - - - Flight Phase Control Functions - - - //
// - - - Flight Phase Control Functions - - - //
// - - - Flight Phase Control Functions - - - //
// - - - Flight Phase Control Functions - - - //

function StartReorientationForBoostbackBurn {
    SET flightPhase to 0. 
    CLEARSCREEN. 
}

function StartBoostbackBurn {
    LOCK throttle to 1.

    SET flightPhase to 1. 
    CLEARSCREEN. 
}

function GlideToPointAboveLandingSite {
    SET TargetPos to V(targetSite:LAT, targetSite:LNG, 0).
    SET TargetPosAltituide to 0.

    SET flightPhase to 2.
    CLEARSCREEN.
}

function GlideToLandingSite {
    SET TargetPos to V(targetSite:LAT, targetSite:LNG, 0).
    SET TargetPosAltituide to 0.
    
    // Offset by 30 meters away from ship's current position
    SET TargetPos to AddMetersToGeoPos(targetSite, GetOffsetPosFromTargetPos(-30)).
    SET TargetPosAltituide to 0.

    SET pitchLimit to 45.

    SET flightPhase to 3.
    CLEARSCREEN.
}

function StartSuicideBurn {
    local magnitude to -(GetHorizationVelocity():mag^1.67) / 45. // Offset by multiple of current horizontal velocity
    SET TargetPos to AddMetersToGeoPos(targetSite, GetOffsetPosFromTargetPos(magnitude)).
    SET TargetPosAltituide to 20.

    LOCK THROTTLE TO 0.8. 

    SET pitchLimit to 10.

    SET flightPhase to 4. 
    CLEARSCREEN. 
}

function StartTouchdown {
    SET TargetPosAltituide to 0. 

    SET pitchLimit to 5.

    SET flightPhase to 5. 
    CLEARSCREEN. 
}

// - - - FLIGHT FUNCTIONS - - - //
// - - - FLIGHT FUNCTIONS - - - //
// - - - FLIGHT FUNCTIONS - - - //
// - - - FLIGHT FUNCTIONS - - - //
// - - - FLIGHT FUNCTIONS - - - //

function OrientForBoostback {
    // Heading Control
    local targetBearing to impactToTargetDir.
    local targetPitch to 0.

    local targetHeading to HEADING(targetBearing, targetPitch).
    LOCK STEERING TO targetHeading.

    local directionError to vAng(targetHeading:vector, ship:facing:vector).

    PrintValue("Direction Error", directionError, 2).

    if directionError < 30 { StartBoostbackBurn(). }
}

function Boostback {
    local targetBearing to impactToTargetDir.
    local targetHeading to HEADING(targetBearing, 0).
    LOCK STEERING TO targetHeading.

    PrintValue("Impact to Target Error", impactToTargetDistance, 2).
    PrintValue("Change in Distance to Target", changeInDistanceToTargetPerSecond, 3).

    if impactToTargetDistance < 500 OR changeInDistanceToTargetPerSecond < -50 { LOCK throttle to 0. GlideToPointAboveLandingSite(). }
}

function GlideToTarget {
    local aproxTimeRemaining to (TrueAltituide - TargetPosAltituide) / (SHIP:velocity:surface:mag*2). // Assuming terminal velocity
    local targetChangeInDistanceToTargetPerSecond to impactToTargetDistance/aproxTimeRemaining. 

    // If impact dist < 50, do fine control that asymptotically approaches the target, avoid large overcorrection
    local pitchMultiplier to targetChangeInDistanceToTargetPerSecond * 2.5.
    if impactToTargetDistance < 50 { SET pitchMultiplier to (impactToTargetDistance^1.6)/15. }

    LOCK STEERING TO GetSteeringRelativeToRetrograde(pitchMultiplier).

    PrintValue("Aprox Time Remaining", aproxTimeRemaining, 2).
    PrintValue("Distance from Impact to Target", impactToTargetDistance, 3).

    PrintValue("Target Change in Distance to Target", targetChangeInDistanceToTargetPerSecond, 5).
    PrintValue("Change in Distance to Target", changeInDistanceToTargetPerSecond, 6).

    PrintValue("Pitch Limit", pitchLimit, 8).
    PrintValue("Pitch Multiplier", pitchMultiplier, 9).
}

function ControlSuicideBurn {
    local targetChangeInAltError to (suicideBurnAltError / suicideBurnLength) * 6. // *4 so that we correct throttle in a fourth of remaining time
    local currentThrottle to THROTTLE.

    // Proportional throttle control
    local throttleChange to CLAMP(ABS(targetChangeInAltError), 0.01, 0.05).

    if changeInSuicudeBurnAltError > targetChangeInAltError {
        LOCK THROTTLE to CLAMP(currentThrottle + throttleChange, 0, 1).
    } else {
        LOCK THROTTLE to CLAMP(currentThrottle - throttleChange, 0, 1).
    }

    // There is a trade off between using aerodynamic control and propulsive contorl
    // At the right time we must switch between these two modes by flipping our heading relative to retrograde
    local headingMultiplier to 1.
    if ship:velocity:surface:mag < 500 { SET headingMultiplier to -1. }

    local pitchMultiplier to CLAMP((impactToTargetDistance^1.5)/10, 0, pitchLimit).
    LOCK STEERING TO GetSteeringRelativeToRetrograde(pitchMultiplier * headingMultiplier).

    PrintValue("Pitch Multiplier", pitchMultiplier, 2).
    PrintValue("Heading Multiplier", headingMultiplier, 3).

    PrintValue("Suicide Burn Alt Error", suicideBurnAltError, 5).
    PrintValue("Target Change in Alt Error", targetChangeInAltError, 6).

    PrintValue("Throttle Change", ROUND(throttleChange, 2), 8).

    PrintValue("Current Throttle", Round(throttle, 2), 10).
}

function SoftTouchdown {
    local t to TrueAltituide / 50.
    SET TargetVerticalVelocity to Lerp(-2, -10, CLAMP(t, 0, 1)).

    local aproxTimeRemaining to (TrueAltituide - TargetPosAltituide) / (SHIP:velocity:surface:mag*2). // Assuming Constant Velocity
    SET aproxTimeRemaining to CLAMP(aproxTimeRemaining, 0, 10). // Clamp to 10 seconds, incase you want to hover

    local pitchMultiplier to Lerp(0, pitchLimit, CLAMP(GetHorizationVelocity():MAG/10, 0, 1)).
    LOCK STEERING TO HEADING(RetrogradeBearing, 90 - pitchMultiplier, 0).

    local baseThrottle to SHIP:Mass/(SHIP:MAXTHRUST / 9.964016384)-0.02. // Hover, Kn to tons, -0.02 adjustment
    local targetChangeInVerticalVelocity to (TargetVerticalVelocity - GetVerticalVelocity()) / aproxTimeRemaining * tickLength * 10.
    local throttleChange to CLAMP(targetChangeInVerticalVelocity, -0.2, 0.2).

    LOCK throttle to CLAMP(baseThrottle + throttleChange, 0, 1).

    PrintValue("Aprox Time Remaining", aproxTimeRemaining, 2).

    PrintValue("Vertical Velocity", GetVerticalVelocity(), 4).
    PrintValue("Target Vertical Velocity", TargetVerticalVelocity, 5).

    PrintValue("Change in Vertical Velocity", ChangeInVerticalVelocity, 7).
    PrintValue("Target Change in Vertical Velocity", targetChangeInVerticalVelocity, 8).

    PrintValue("Base Throttle", baseThrottle, 10).
    PrintValue("Throttle Change", throttleChange, 11).

    PrintValue("Current Throttle", throttle, 13).

    PrintValue("Pitch Multiplier", pitchMultiplier, 15).

    PrintValue("True Altitude", TrueAltituide, 17).
}
