// Sites:
// Launch Pad: -0.09729775, -74.55767274
// North Landing Pad: -0.185407556445315, -74.4729356049979

// TODO: Redo variables in loop with Lock instead of set, this is how kOS is meant to be used
// Also, 0.1 tick length does not mean 10 ticks is one second

// Primary Launch Pad: -0.0972078320140506, -74.5576718763811
// Landing site north: -0.185407556445315, -74.4729356049979
// VAB East Helipad:   -0.0967999401268479, -74.617417864482
SET targetSite to LATLNG(-0.185407556445315, -74.4729356049979).

SET flightPhase to 0.
SET tickLength to 0.1.

// CONTROL VARIABLES //
SET pitchLimit to 45.
SET craftHeight to 7. // Adjust to true radar altitude, not quite full craft height just where its controlled from

// FLIGHT VARIABLES //
SET ImpactPos to SHIP:GEOPOSITION.
SET TargetPosAltituide to 0. // Altitude of impact point (used for aerodynamic control to a point above the surface)
SET TargetPos to V(targetSite:LAT, targetSite:LNG, 0). // This is the adjusted landing site, used for aerodynamic control above ~5km

SET impactToTargetDir to 100.
SET impactToTargetDistance to 100. // Impact point to Target point distance
SET changeInDistanceToTargetPerSecond to 100.
SET previousImpactToTargetDistance to 100.

SET suicideBurnLength to 100.
SET suicideBurnAltError to 100.
SET previousSuicideBurnAltError to 100. // Altitude minus est burn alt
SET changeInSuicudeBurnAltError to 100.

SET TargetVerticalVelocity to 0.
SET ChangeInVerticalVelocity to 1.
SET previousVerticalVelocity to 1.

SET RetrogradePitch to 100.
SET RetrogradeBearing to 100.

CLEARSCREEN.
CLEARVECDRAWS().

SET gear to false.
StartReorientationForBoostbackBurn().
//GlideToLandingSite().

UNTIL false {
    // Make better win condition later
    if NOT ADDONS:TR:HASIMPACT { LOCK THROTTLE TO 0. CLEARSCREEN. BREAK. }
    if AG10 { LOCK THROTTLE TO 0. CLEARSCREEN. BREAK. }

    UpdateFlightVariables().

    //drawLineToTarget().
    //drawLineToImpact().

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

        if altitude < 4000 { GlideToLandingSite(). }
    } else if flightPhase = 3 {
        PRINT "Flight Phase: Final Aerodynamic Descent (4/6)" at (0, 0).

        GlideToTarget().

        PrintValue("Suicude Burn Alt Error", suicideBurnAltError, 11).
        if suicideBurnAltError < 0 { StartSuicideBurn(). } // If Suicide Burn is Required
    } else if flightPhase = 4 {
        PRINT "Flight Phase: Propulsive Descent (5/6)" at (0, 0).

        SET gear to alt:radar < 300.

        ControlSuicideBurn().

        if alt:radar < TargetPosAltituide OR ABS(ship:velocity:surface:mag) < 45 { StartTouchdown. }
    } else if flightPhase = 5{
        PRINT "Flight Phase: Soft Touchdown (6/6)" at (0, 0).

        SET gear to alt:radar < 300.

        local t to (alt:radar - craftHeight) / 25.
        SET TargetVerticalVelocity to Lerp(-2, -5, CLAMP(t, 0, 1)).

        SoftTouchdown().
    }
}

function UpdateFlightVariables{
    if TargetPosAltituide = 0 { SET ImpactPos to ADDONS:TR:IMPACTPOS. }
    else SET ImpactPos to GetLatLngAtAltitude(TargetPosAltituide, SHIP:OBT:ETA:PERIAPSIS, 1).

    SET suicideBurnLength to GetSuicideBurnLength().
    SET suicideBurnAltError to SHIP:ALTITUDE - GetSuicudeBurnAltitude() - craftHeight. // -7 adjustment for craft height REMEMBER REMEMBER REMEMBER
    SET changeInSuicudeBurnAltError to (previousSuicideBurnAltError - suicideBurnAltError) / tickLength.
    SET previousSuicideBurnAltError to suicideBurnAltError.

    local impactPosAsVector to V(ImpactPos:LAT, ImpactPos:LNG, 0).
    SET impactToTargetDistance to LatLngDist(impactPosAsVector, TargetPos). // Impact point to Target point distance
    SET impactToTargetDir to DirToPoint(impactPosAsVector, TargetPos).
    
    SET changeInDistanceToTargetPerSecond to (previousImpactToTargetDistance - impactToTargetDistance) / tickLength.
    SET previousImpactToTargetDistance to impactToTargetDistance.

    SET ChangeInVerticalVelocity to -(previousVerticalVelocity - GetVerticalVelocity()) / tickLength.
    SET previousVerticalVelocity to GetVerticalVelocity().
    
    SET RetrogradePitch to 90 - vang(srfretrograde:forevector, up:forevector).
    SET RetrogradeBearing to GetRetrogradeBearing().
}

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
    // In first glide phase, target point 4km above landing site and offset towards our position, -180 to point towards us not away
    local offsetDir to DirToPoint(V(SHIP:geoposition:lat, SHIP:geoposition:lng, 0), V(targetSite:lat, targetSite:lng, 0))-180.
    SET offset to V(cos(offsetDir), sin(offsetDir), 0) * 0. // 0 meter offset at this stage of flight

    SET TargetPos to AddMetersToGeoPos(targetSite, offset).
    SET TargetPosAltituide to 0.

    SET flightPhase to 2.
    CLEARSCREEN.
}

function GlideToLandingSite {
    SET TargetPos to V(targetSite:LAT, targetSite:LNG, 0).
    SET TargetPosAltituide to 0.

    // Offset to opposite of current position, try to slightly overshoot so that we can cancel out horizontal velocity on the way down
    local offsetDir to DirToPoint(V(SHIP:geoposition:lat, SHIP:geoposition:lng, 0), V(targetSite:lat, targetSite:lng, 0))-180.
    SET offset to V(cos(offsetDir), sin(offsetDir), 0) * -30.

    SET TargetPos to AddMetersToGeoPos(targetSite, offset).
    SET TargetPosAltituide to 0.

    SET pitchLimit to 45.

    SET flightPhase to 3.
    CLEARSCREEN.
}

function StartSuicideBurn {
    // Offset to opposite of current position, try to slightly overshoot so that we can cancel out horizontal velocity on the way down and land on target without much complexity
    local offsetDir to DirToPoint(V(SHIP:geoposition:lat, SHIP:geoposition:lng, 0), V(targetSite:lat, targetSite:lng, 0))-180.
    local magnitude to -(GetHorizationVelocity():mag^1.67) / 45. // Offset by multiple of current horizontal velocity
    SET offset to V(cos(offsetDir), sin(offsetDir), 0) * magnitude.

    SET TargetPos to AddMetersToGeoPos(targetSite, offset).
    SET TargetPosAltituide to 25.

    LOCK THROTTLE TO 0.8. 

    SET pitchLimit to 10.

    SET flightPhase to 4. 
    CLEARSCREEN. 
}

function StartTouchdown {
    SET TargetPosAltituide to 0. 

    SET pitchLimit to 10.

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

    if directionError < 15 { StartBoostbackBurn(). }
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
    local aproxTimeRemaining to (SHIP:altitude - TargetPosAltituide) / (SHIP:velocity:surface:mag*2). // Assuming terminal velocity
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
    if ship:velocity:surface:mag < 180 { SET headingMultiplier to -1. }

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
    local aproxTimeRemaining to (SHIP:altitude - TargetPosAltituide) / (SHIP:velocity:surface:mag*2). // Assuming Constant Velocity
    SET aproxTimeRemaining to CLAMP(aproxTimeRemaining, 0, 10). // Clamp to 10 seconds, incase you want to hover

    local pitchMultiplier to (GetHorizationVelocity():MAG / aproxTimeRemaining) * 5.
    LOCK STEERING TO HEADING(RetrogradeBearing, 90 - pitchMultiplier, 0).

    local baseThrottle to SHIP:Mass/(SHIP:MAXTHRUST / 9.964016384)-0.02. // Hover, Kn to tons, -0.02 adjustment
    local targetChangeInVerticalVelocity to (TargetVerticalVelocity - GetVerticalVelocity()) / aproxTimeRemaining * tickLength * 10.
    local throttleChange to CLAMP(targetChangeInVerticalVelocity, -0.5, 0.5).

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
}

// - - - HELPER FUNCTIONS - - - //
// - - - HELPER FUNCTIONS - - - //
// - - - HELPER FUNCTIONS - - - //
// - - - HELPER FUNCTIONS - - - //
// - - - HELPER FUNCTIONS - - - //

// I overengineered for 5 wasted days, this is the solution from: https://github.com/Donies1/kOS-Scripts/blob/main/heavy2fmrs.ks
function GetSteeringRelativeToRetrograde {
    local Parameter pitchMultiplier.

    // Retrograde vector is in the SHIP-RAW Reference Frame https://ksp-kos.github.io/KOS_DOC/math/ref_frame.html#reference-frames
    local retrogradeVector to -ship:velocity:surface.

    // :position converts from latlng to SHIP-RAW reference frame
    // Refactoring needed to minimize transforming values like LatLng
    local targetVector to ImpactPos:position - LATLNG(TargetPos:x, TargetPos:y):position.
    local targetDirection to retrogradeVector + targetVector * pitchMultiplier.

    // If relative angle is too high, limit it.
    // Normalize the vectors, then multiply the target direction by the tan of pitch limit to get proper x and y components
    local angleDifference to vAng(targetDirection, retrogradeVector). // Angle of two cartesians
    if angleDifference > pitchLimit { SET targetDirection to retrogradeVector:normalized + targetDirection:normalized*tan(pitchLimit). }

    return lookDirUp(targetDirection, facing:topvector).
}

function PrintValue {
    local Parameter label.
    local Parameter value.
    local parameter yPos.

    if value:typename = "SCALAR" { SET value to ROUND(value, 5). }

    // Add 10 blank spaces to clear previous value
    PRINT label + ": " + value + "          " at (0, yPos).
}

function drawLineToTarget {
    CLEARVECDRAWS().
    SET anArrow TO VECDRAW(
      V(0,0,0),
      LATLNG(TargetPos:x, TargetPos:y):position,
      RGB(1,0,0),
      "X",
      1.0,
      TRUE,
      0.2,
      TRUE,
      TRUE
    ).
}

function drawLineToImpact {
    SET anotherArrow TO VECDRAW(
      V(0,0,0),
      ImpactPos:position,
      RGB(0,1,0),
      "I",
      1.0,
      TRUE,
      0.2,
      TRUE,
      TRUE
    ).
}

// Engines must be active to return accurate value
// Eg. use (SHIP:ALTITUDE - GetSuicudeBurnAltitude()) to get the whether the engines should be firing or not, <0 = fire
function GetSuicudeBurnAltitude {
    if SHIP:AVAILABLETHRUST = 0 { return 1. }

    local g to body:mu / (altitude + body:radius)^2.

    // Drag isn't factored in but this causes a greater margin for error, undercalculating net acceleration, *0.8 to further undercalculate
    local netAcc to (SHIP:AVAILABLETHRUST*0.85 / SHIP:MASS) - g.

    // Kinematics equation to find displacement
    local estBurnAlt to ((GetVerticalVelocity()^2) / (netAcc*2)) + CLAMP(ImpactPos:TERRAINHEIGHT + TargetPosAltituide, 0, 100000). 
    //local estBurnTime to (estBurnAlt/(0.5*netAcc))^0.5.

    return estBurnAlt.
}

function GetSuicideBurnLength {
    if SHIP:AVAILABLETHRUST = 0 { return 1. }

    local g to body:mu / (altitude + body:radius)^2.

    // Drag isn't factored in but this causes a greater margin for error, undercalculating net acceleration
    local netAcc to (SHIP:AVAILABLETHRUST*0.9 / SHIP:MASS) - g.

    // Kinematics equation to find displacement
    local estBurnAlt to ((GetVerticalVelocity()^2) / (netAcc*2)) + CLAMP(ImpactPos:TERRAINHEIGHT + TargetPosAltituide, 0, 100000). 
    local estBurnTime to (estBurnAlt/(0.5*netAcc))^0.5.

    return estBurnTime.
}

// Return the lat/long of the position in the future on the current orbit at a given altitude
// Ie. find the geolocation when we're at x meters above the surface in range y seconds
// SET impactGeoPos to GetLatLngAtAltitude(0, SHIP:OBT:ETA:PERIAPSIS, 10).
function GetLatLngAtAltitude {
    local parameter targetAltitude. // Meters
    local parameter timeRange. // Seconds
    local parameter altitudePrecision. // Allowable meters from given altitude to be considered correct, can't asymptote and crash the game

    // Replace 'SET' with 'Local'
    // Lower bound is present, upper bound is future
    local lowerBound to TIME:seconds.
    local upperBound to TIME:seconds + timeRange.
    local midTime to 0.

    // Binary Search
    for x in range(0, 35) {
        SET midTime to (lowerBound + upperBound) / 2.
        local midAltitude to body:altitudeof(positionat(SHIP, midTime)).

        if midAltitude < targetAltitude {
            SET upperBound to midTime.
        } else {
            SET lowerBound to midTime.
        }

        // If error less than precision
        if ABS(ABS(midAltitude) - targetAltitude) < altitudePrecision { BREAK. }
    }

    local geopos to BODY:GEOPOSITIONOF(positionat(SHIP, midTime)).
    // Longitude rotation of planet during coast to altitude ((360 degrees * seconds until impact) / seconds per rotation) * cos(cosine of latitude becuase of curvature)
    local rotationAdjustment to (360*(midTime-TIME:seconds)/BODY:rotationperiod) * cos(geopos:lat).

    return latlng(geopos:lat, geopos:lng - rotationAdjustment).
}

// Get distance between two positions without considering the altitude
// Eg. LatLngDist(V(SHIP:GEOPOSITION:LAT, SHIP:GEOPOSITION:LNG, 0), V(-0.09729775,-74.55767274,0))
function LatLngDist {
    // Only x and y are used for lat/long. z is to be ignored
    Parameter pos1.
    Parameter pos2.

    // 10471.975 is the length of one degree lat/long on Kerbin. 3769911/360
    return (pos1 - pos2):MAG * 10471.975. 
}

// Returns difference between two positions in meters
function LatLngDiff {
    // Only x and y are used for lat/long. z is to be ignored
    Parameter pos1.
    Parameter pos2.

    // 10471.975 is the length of one degree lat/long on Kerbin. 3769911/360
    return (pos1 - pos2) * 10471.975. 
}

// Return direction to position in degrees starting from 0 at north
function DirToPoint {
    // Only x and y are used for lat/long. z is to be ignored
    Parameter pos1.
    Parameter pos2.

    SET diff to pos2 - pos1.

    // atan2 resolves arctan ambiguity (ASTC quadrants)
    // Reversing x and y to rotate by 90 degrees so we start at 0 degrees at north, usualy ATAN(Y, X)
    local result to arcTan2(diff:Y, diff:X).

    // Keep degress between 0 and 360
    if result < 0 { SET result to result + 360. }

    return result.
}

// Get compass bearing of retrograde by getting geoposition of retrograde point and the direction from the ship to it
function GetRetrogradeBearing {
    local retrogradeGeoPos to AddMetersToGeoPos(Ship:geoposition, GetHorizationVelocity()*1000).
    return -MOD(DirToPoint(V(Ship:geoposition:lat, Ship:geoPosition:lng, 0), retrogradeGeoPos) + 90, 360)+360. // Adjust to be centered on north, MOD = %
}

// Return east/west and north/south components of velocity
function GetHorizationVelocity {
    // https://www.reddit.com/r/Kos/comments/bwy79n/clarifications_on_shipvelocitysurface/
    SET vEast to -vDot(ship:velocity:surface, ship:north:starvector).
    SET vNorth to vDot(ship:velocity:surface, ship:north:forevector).
    return v(vEast, vNorth, 0).
}

function GetVerticalVelocity {
    return -1 * vDot(ship:velocity:surface, ship:north:TOPVECTOR).
}

function Clamp {
    Parameter value.
    Parameter minValue.
    Parameter maxValue.

    if value < minValue { return minValue. }
    if value > maxValue { return maxValue. }
    return value.
}

// Add meters to geo position and return as vector with lat/lng values
function AddMetersToGeoPos{
    // Both vectors, z is to be ignored when dealing with latlngs
    local Parameter geopos.
    local Parameter meters.

    // 10471.975 is the length of one degree lat/long on Kerbin. 3769911/360
    return V(geopos:lat + meters:x/10471.975, geopos:lng + meters:y/10471.975, 0). 
}

function Lerp {
    local Parameter a.
    local Parameter b.
    local Parameter t.

    return a + (b - a) * t.
}