// TODO: Redo variables in loop with Lock instead of set, this is how kOS is meant to be used, this is a full refactor and messes up printing (printing needs to be done better anyway)
// Also, 0.1 tick length does not mean 10 ticks is one second

// Primary Launch Pad: -0.0972078320140506, -74.5576718763811
// Landing site north: -0.185407556445315, -74.4729356049979
// VAB East Helipad:   -0.0967999401268479, -74.617417864482
//SET targetSite to LATLNG(-0.190507556445315, -74.4729356049979).

SET flightPhase to 0.
SET tickLength to 0.1.

SET pitchLimit to 45.
//SET craftHeight to 7. // Adjust to true radar altitude, not quite full craft height just where its controlled from

SET ImpactPos to SHIP:GEOPOSITION.
SET TargetPosAltitude to 0. // Altitude of impact point (used for aerodynamic control to a point above the surface)
SET TargetPos to V(targetSite:LAT, targetSite:LNG, 0). // This is the adjusted landing site, used for aerodynamic control above ~5km
SET TrueAltitude to 0.

SET impactToTargetDir to 100.
SET impactToTargetDistance to 100.
SET changeInDistanceToTargetPerSecond to 100.
SET previousImpactToTargetDistance to 100.

SET suicideBurnLength to 100.
SET suicideBurnAltError to 100.
SET previousSuicideBurnAltError to 100.
SET changeInSuicideBurnAltError to 100.

SET TargetVerticalVelocity to 0.
SET ChangeInVerticalVelocity to 1.
SET previousVerticalVelocity to 1.

SET RetrogradePitch to 100.
SET RetrogradeBearing to 100.

run HelperFunctions.

CLEARSCREEN.
CLEARVECDRAWS().

Toggle RCS.

SET gear to false.
StartReorientationForBoostbackBurn().
//GlideToLandingSite().

UNTIL false {
    // If impact or zero key pressed, stop the script
    //if NOT ADDONS:TR:HASIMPACT { LOCK THROTTLE TO 0. CLEARSCREEN. BREAK. }
    //if AG10 { LOCK THROTTLE TO 0. CLEARSCREEN. BREAK. }

    UpdateFlightVariables().
    
    // Terminal flight when we're probably landed
    if (flightPhase = 5 and (TrueAltitude < 2 or GetVerticalVelocity() >= -0.25)) { SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. CLEARSCREEN. BREAK. }

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

        if TrueAltitude < 3000 { GlideToLandingSite(). }
    } else if flightPhase = 3 {
        PRINT "Flight Phase: Final Aerodynamic Descent (4/6)" at (0, 0).

        // Update Target Position based on expected x displacement due to landing burn
        SET displacementEstimate to GetSuicideBurnNetDisplacementEstimate(). // Offset by 8 meters, I don't like this kind of tuning
        SET TargetPos to AddMetersToGeoPos(targetSite, GetOffsetPosFromTargetSite(-displacementEstimate)).

        GlideToTarget().
        if suicideBurnAltError < 0 { StartSuicideBurn(). } // If Suicide Burn is Required
    } else if flightPhase = 4 {
        PRINT "Flight Phase: Propulsive Descent (5/6)" at (0, 0).

        SET gear to TrueAltitude < 300.

        ControlSuicideBurn().

        if TrueAltitude < TargetPosAltitude OR ABS(ship:velocity:surface:mag) < 45 { StartTouchdown. }
    } else if flightPhase = 5{
        PRINT "Flight Phase: Soft Touchdown (6/6)" at (0, 0).

        SET gear to TrueAltitude < 300.

        SoftTouchdown().
    }
}

// A few of these are backwards (negative), very stupid, refactor 2 needed
function UpdateFlightVariables{
    //if TargetPosAltitude = 0 { SET ImpactPos to ADDONS:TR:IMPACTPOS. }
    SET ImpactPos to GetLatLngAtAltitude(TargetPosAltitude, SHIP:OBT:ETA:PERIAPSIS, 1).

    SET TrueAltitude to alt:radar - craftHeight.

    SET suicideBurnLength to GetSuicideBurnLength().
    SET suicideBurnAltError to TrueAltitude - GetSuicideBurnAltitude().
    SET changeInSuicideBurnAltError to (previousSuicideBurnAltError - suicideBurnAltError) / tickLength.
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
    SET TargetPosAltitude to 0.

    Toggle AG5. // Landing Mode

    SET flightPhase to 2.
    CLEARSCREEN.
}

function GlideToLandingSite {
    SET TargetPos to V(targetSite:LAT, targetSite:LNG, 0).
    SET TargetPosAltitude to 0.
    
    // Offset by 30 meters away from ship's current position
    SET TargetPos to AddMetersToGeoPos(targetSite, GetOffsetPosFromTargetSite(-30)).
    SET TargetPosAltitude to 0.

    SET pitchLimit to 20.

    SET flightPhase to 3.
    CLEARSCREEN.
}

function StartSuicideBurn {
    SET TargetPos to AddMetersToGeoPos(targetSite, V(0, 0, 0)).
    SET TargetPosAltitude to 10.

    LOCK THROTTLE TO 0.8. 

    SET pitchLimit to 10.

    SET flightPhase to 4. 
    CLEARSCREEN. 
}

function StartTouchdown {
    SET TargetPosAltitude to 0. 

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

    local targetHeading to HEADING(targetBearing, targetPitch, 0).
    LOCK STEERING TO targetHeading.

    local directionError to vAng(targetHeading:vector, ship:facing:vector).

    PrintValue("Direction Error", directionError, 2).

    if directionError < 30 { StartBoostbackBurn(). }
}

function Boostback {
    local targetBearing to impactToTargetDir.
    local targetHeading to HEADING(targetBearing, 0, 0).
    LOCK STEERING TO targetHeading.

    PrintValue("Impact to Target Error", impactToTargetDistance, 2).
    PrintValue("Change in Distance to Target", changeInDistanceToTargetPerSecond, 3).

    if impactToTargetDistance < 500 OR changeInDistanceToTargetPerSecond < -50 { LOCK throttle to 0. GlideToPointAboveLandingSite(). }
}

function GlideToTarget {
    local aproxTimeRemaining to (TrueAltitude - TargetPosAltitude) / (SHIP:velocity:surface:mag*2). // Assuming terminal velocity
    local targetChangeInDistanceToTargetPerSecond to impactToTargetDistance/aproxTimeRemaining. 

    // If impact dist < 50, do fine control that asymptotically approaches the target, avoid large overcorrection
    local pitchMultiplier to targetChangeInDistanceToTargetPerSecond * 2.5.
    if impactToTargetDistance < 100 { SET pitchMultiplier to (impactToTargetDistance^1.5)*PitchMultiplierMultiplier. }

    LOCK STEERING TO GetSteeringRelativeToRetrograde(pitchMultiplier).

    PrintValue("Aprox Time Remaining", aproxTimeRemaining, 2).
    PrintValue("Distance from Impact to Target", impactToTargetDistance, 3).

    PrintValue("Target Change in Distance to Target", targetChangeInDistanceToTargetPerSecond, 5).
    PrintValue("Change in Distance to Target", changeInDistanceToTargetPerSecond, 6).

    PrintValue("Pitch Limit", pitchLimit, 8).
    PrintValue("Pitch Multiplier", pitchMultiplier, 9).

    PrintValue("Suicide Burn Alt Error", suicideBurnAltError, 11).
    PrintValue("Suicide Burn Length", suicideBurnLength, 12).
}

function ControlSuicideBurn {
    local targetChangeInAltError to (suicideBurnAltError / suicideBurnLength) * 6. // *4 so that we correct throttle in a fourth of remaining time
    local currentThrottle to THROTTLE.

    // Proportional throttle control
    local throttleChange to CLAMP(ABS(targetChangeInAltError), 0.01, 0.05).

    if changeInSuicideBurnAltError > targetChangeInAltError {
        LOCK THROTTLE to CLAMP(currentThrottle + throttleChange, 0, 1).
    } else {
        LOCK THROTTLE to CLAMP(currentThrottle - throttleChange, 0, 1).
    }

    // There is a trade off between using aerodynamic control and propulsive control
    // At the right time we must switch between these two modes by flipping our heading relative to retrograde
    // When under 50 m/s vertical velocity, we switch to propulsive control (ie. point the engine in the opposite direction of where you want to go)
    local headingMultiplier to 1.
    if ship:velocity:surface:mag < AeroControlThreshold { SET headingMultiplier to -1. } 

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
    local t to TrueAltitude / 50.
    SET TargetVerticalVelocity to Lerp(-2, -10, CLAMP(t, 0, 1)).

    local aproxTimeRemaining to (TrueAltitude - TargetPosAltitude) / (SHIP:velocity:surface:mag*2 + 0.001). // Assuming Constant Velocity
    SET aproxTimeRemaining to CLAMP(aproxTimeRemaining, 5, 10). // Clamp to 10 seconds, incase you want to hover

    local pitchMultiplier to Lerp(0, pitchLimit, CLAMP(GetHorizontalVelocity():MAG/3, 0, 1)).
    LOCK STEERING TO HEADING(RetrogradeBearing, 90 - pitchMultiplier).

    local baseThrottle to SHIP:Mass/(SHIP:MAXTHRUST / 9.964016384)-0.02. // Hover, Kn to tons, -0.02 adjustment

    local vertVelError to TargetVerticalVelocity - GetVerticalVelocity().
    local throttleChange to CLAMP(vertVelError^1.7/50, 0.01, 0.25) * ((vertVelError + 1.1)/ABS(vertVelError + 1)/1.1). // keep the sign on vertVelError, +1.5 & +1 to avoid getting infinity/divide by zero

    //local targetChangeInVerticalVelocity to (TargetVerticalVelocity - GetVerticalVelocity()) * tickLength * 10.
    //local throttleChange to CLAMP(targetChangeInVerticalVelocity, -0.2, 0.2).

    LOCK throttle to CLAMP(baseThrottle + throttleChange, 0, 1).

    PrintValue("Aprox Time Remaining", aproxTimeRemaining, 2).

    PrintValue("Vertical Velocity", GetVerticalVelocity(), 4).
    PrintValue("Target Vertical Velocity", TargetVerticalVelocity, 5).

    PrintValue("Change in Vertical Velocity", ChangeInVerticalVelocity, 7).
    //PrintValue("Target Change in Vertical Velocity", targetChangeInVerticalVelocity, 8).

    PrintValue("Base Throttle", baseThrottle, 10).
    PrintValue("Throttle Change", throttleChange, 11).

    PrintValue("Current Throttle", throttle, 13).

    PrintValue("Pitch Multiplier", pitchMultiplier, 15).

    PrintValue("True Altitude", TrueAltitude, 17).

    PrintValue("Ship Available Thrust", SHIP:AVAILABLETHRUST, 19).
    PrintValue("Ship Thrust", SHIP:THRUST, 20).
    PrintValue("Ship Mass", SHIP:MASS, 21).
}
