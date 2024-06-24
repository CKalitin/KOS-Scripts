// Landing from 70km up

// Sites:
// Launch Pad: -0.09729775, -74.55767274
// North Landing Pad: -0.185407556445315, -74.4729356049979

// Flight Phases
// 0: Aerodynamic Control down to point near landing site at ~5000m
// 1: Fine aerodynamic control aiming for landing site
// 2: When alt - est burn altitude < 0, fire engines and modulate until reach point above landing site
// 3: Touchdown, kill horizontal velocity and center above landing site

// TODO: Redo variables in loop with Lock instead of set, this is how kOS is meant to be used
// Also, 0.1 tick length does not mean 10 ticks is one second

// Primary Launch Pad: -0.0972078320140506, -74.5576718763811
// Landing site north: -0.185407556445315, -74.4729356049979
// VAB East Helipad:   -0.0967999401268479, -74.617417864482
SET targetSite to LATLNG(-0.185407556445315, -74.4729356049979).

SET flightPhase to 0.
SET tickLength to 0.25.

// CONTROL VARIABLES //
SET pitchLimit to 45.  // Pitch limit has to be high to counter act the undercorrection of kOS steering lock
SET bearingLimit to 360.  // Pitch limit has to be high to counter act the undercorrection of kOS steering lock

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

SET RetrogradePitch to 100.
SET RetrogradeBearing to 100.

CLEARSCREEN.

SET gear to false.
//StartReorientationForBoostbackBurn().
GlideToLandingSite().

UNTIL false {
    // Make better win condition later
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

        if altitude < 5000 { GlideToLandingSite(). }
    } else if flightPhase = 3 {
        PRINT "Flight Phase: Final Aerodynamic Descent (4/6)" at (0, 0).

        GlideToTarget().

        //PrintValue("Suicude Burn Alt Error", suicideBurnAltError, 9).
        if suicideBurnAltError < 0 { StartSuicideBurn(). } // If Suicide Burn is Required
    } else if flightPhase = 4 {
        PRINT "Flight Phase: Propulsive Descent (5/6)" at (0, 0).

        SET gear to alt:radar < 300.

        ControlSuicideBurnThrottle().
        ControlSuicideBurnHeading().

        if alt:radar < TargetPosAltituide OR ship:velocity:surface:mag < 2 { StartTouchdown. }
    } else if flightPhase = 5{
        PRINT "Flight Phase: Soft Touchdown (6/6)" at (0, 0).

        SET gear to alt:radar < 300.

        SoftTouchdown().
    }
}

function UpdateFlightVariables{
    if TargetPosAltituide = 0 { SET ImpactPos to ADDONS:TR:IMPACTPOS. }
    else SET ImpactPos to GetLatLngAtAltitude(TargetPosAltituide, SHIP:OBT:ETA:PERIAPSIS, 1).

    SET suicideBurnLength to GetSuicideBurnLength().
    SET suicideBurnAltError to SHIP:ALTITUDE - GetSuicudeBurnAltitude() - 6. // -7 adjustment for craft height REMEMBER REMEMBER REMEMBER
    SET changeInSuicudeBurnAltError to (previousSuicideBurnAltError - suicideBurnAltError) / tickLength.
    SET previousSuicideBurnAltError to suicideBurnAltError.

    local impactPosAsVector to V(ImpactPos:LAT, ImpactPos:LNG, 0).
    SET impactToTargetDistance to LatLngDist(impactPosAsVector, TargetPos). // Impact point to Target point distance
    SET impactToTargetDir to DirToPoint(impactPosAsVector, TargetPos).
    
    SET changeInDistanceToTargetPerSecond to (previousImpactToTargetDistance - impactToTargetDistance) / tickLength.
    SET previousImpactToTargetDistance to impactToTargetDistance.
    
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
    SET offset to V(cos(offsetDir), sin(offsetDir), 0) * 0. // *150 to make offset 150 meters, hypotenuse

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
    SET offset to V(cos(offsetDir), sin(offsetDir), 0) * -10. // *150 to make offset 150 meters, hypotenuse

    SET TargetPos to AddMetersToGeoPos(targetSite, offset).
    SET TargetPosAltituide to 0.

    SET pitchLimit to 45.

    SET flightPhase to 3.
    CLEARSCREEN.
}

function StartSuicideBurn {
    SET TargetPos to V(targetSite:LAT, targetSite:LNG, 0).
    SET TargetPosAltituide to 20.

    LOCK THROTTLE TO 0.8. 

    SET pitchLimit to 15.
    SET bearingLimit to 360.

    SET flightPhase to 4. 
    CLEARSCREEN. 
}

function StartTouchdown {
    SET TargetPosAltituide to 0. 

    SET flightPhase to 5. 
    CLEARSCREEN. 
}

// - - - FLIGHT FUNCTIONS - - - //
// - - - FLIGHT FUNCTIONS - - - //
// - - - FLIGHT FUNCTIONS - - - //
// - - - FLIGHT FUNCTIONS - - - //
// - - - FLIGHT FUNCTIONS - - - //

function SoftTouchdown {
    
}

function OrientForBoostback {
    // Heading Control
    local targetBearing to impactToTargetDir.
    local targetPitch to 0.

    local targetHeading to HEADING(targetBearing, targetPitch).
    LOCK STEERING TO targetHeading.

    local bearingError to ABS(-ship:bearing - targetBearing).
    local pitchError to ABS(vang(ship:facing:forevector, up:forevector) - 90 - targetPitch). // vang(ship:facing:forevector, up:forevector) - 90 = ship pitch

    PrintValue("Bearing Error", bearingError, 2).
    PrintValue("Pitch Error", pitchError, 3).

    PrintValue("Ship Bearing", -ship:bearing, 5).
    PrintValue("Target Bearing", targetBearing, 6).

    if bearingError < 15 AND pitchError < 15 { StartBoostbackBurn(). }
}

function Boostback {
    local targetBearing to impactToTargetDir.
    local targetHeading to HEADING(targetBearing, 0).
    LOCK STEERING TO targetHeading.

    PrintValue("Impact to Target Error", impactToTargetDistance, 2).
    PrintValue("Change in Distance to Target", changeInDistanceToTargetPerSecond, 3).

    if impactToTargetDistance < 500 OR changeInDistanceToTargetPerSecond < -50 { LOCK throttle to 0. GlideToPointAboveLandingSite(). }
}

function ControlSuicideBurnThrottle {
    local targetChangeInAltError to suicideBurnAltError / suicideBurnLength * 2. // why *2?
    local currentThrottle to THROTTLE.

    // Proportional throttle control
    local throttleChange to CLAMP(targetChangeInAltError/2, 0.01, 0.05).

    if changeInSuicudeBurnAltError > targetChangeInAltError {
        LOCK THROTTLE to CLAMP(currentThrottle + throttleChange, 0, 1).
    } else {
        LOCK THROTTLE to CLAMP(currentThrottle - throttleChange, 0, 1).
    }

    PrintValue("Suicide Burn Alt Error", suicideBurnAltError, 2).
    PrintValue("Target Change in Alt Error", targetChangeInAltError, 3).

    PrintValue("Throttle Change", ROUND(throttleChange, 2), 5).

    PrintValue("Current Throttle", Round(throttle, 2), 7).
}

function ControlSuicideBurnHeading {
    local pitchMultiplier to CLAMP((impactToTargetDistance^1.5)/10, 0, pitchLimit).
    LOCK STEERING TO HEADING(impactToTargetDir, pitchMultiplier).
}

function GlideToTarget {
    local aproxTimeRemaining to (SHIP:altitude - TargetPosAltituide) / (SHIP:velocity:surface:mag*2) / 2. // divide by 1.5 so you get to the target faster
    local targetChangeInDistanceToTargetPerSecond to impactToTargetDistance/aproxTimeRemaining. 

    // If impact dist < 50, do fine control that asymptotically approaches the target (but closed loop is badly tuned, so it overcorrects)
    local pitchMultiplier to targetChangeInDistanceToTargetPerSecond * 2.
    if impactToTargetDistance < 50 { SET pitchMultiplier to (impactToTargetDistance^1.5)/15. }

    if RetrogradePitch > 70 AND ship:velocity:surface:mag < 450 { SET bearingLimit to 360. }
    else SET bearingLimit to pitchLimit.
    
    local shipDirToTarget to impactToTargetDir - 180 - RetrogradeBearing.
    local bearingAndPitch to GetBearingAndPitchFromDir(shipDirToTarget, pitchMultiplier).
    LOCK STEERING TO HEADING(bearingAndPitch:x, bearingAndPitch:y).

    PrintValue("Aprox Time Remaining", aproxTimeRemaining, 2).
    PrintValue("Distance from Impact to Target", impactToTargetDistance, 3).

    PrintValue("Target Change in Distance to Target", targetChangeInDistanceToTargetPerSecond, 5).
    PrintValue("Change in Distance to Target", changeInDistanceToTargetPerSecond, 6).

    PrintValue("Raw Dir to Target", (impactToTargetDir - 180), 8).
    PrintValue("Ship Dir to Target", shipDirToTarget, 9).

    PrintValue("Bearing Limit", bearingLimit, 11).
    PrintValue("Pitch Limit", pitchLimit, 12).
    PrintValue("Pitch Multiplier", pitchMultiplier, 13).

    PrintValue("Retrograde Bearing", RetrogradeBearing, 15).
    PrintValue("Retrograde Pitch", RetrogradePitch, 16).

    PrintValue("Target Bearing", bearingAndPitch:x, 18).
    PrintValue("Target Pitch", bearingAndPitch:y, 19).

    // If retrograde pitch is nearing straight up, behaviour is not correct, so, lock to straight up and ignore retrograde
    if RetrogradePitch > 90 {
        Print "Guidance relative to Retrograde" at (0, 27).

        LOCK STEERING to HEADING(impactToTargetDir - 180, CLAMP(pitchMultiplier, 0 , pitchLimit)).
    }
}

// - - - HELPER FUNCTIONS - - - //
// - - - HELPER FUNCTIONS - - - //
// - - - HELPER FUNCTIONS - - - //
// - - - HELPER FUNCTIONS - - - //
// - - - HELPER FUNCTIONS - - - //

function PrintValue {
    local Parameter label.
    local Parameter value.
    local parameter yPos.

    // 60 spaces to clear the line
    PRINT "                                                            " at (0, yPos).
    PRINT label + ": " + value at (0, yPos).
}

// Instead of using raw direction as the bearing, make it relative to retrograde so it can be clamped (eg. for reentry)
// Returns as vector with x as bearing and y as pitch
function GetBearingAndPitchFromDir {
    local parameter dir.
    local parameter pitchMultiplier.

    // Get X and Y errors individually so that bearing and pitch can be clamped separately
    local xProportionalError to sin(dir).
    local yProportionalError to cos(dir).

    // Set the larger value to 1, adjust the smaller value accordingly, this way the maneuver is proportional in both x and y
    if ABS(xProportionalError) < ABS(yProportionalError) { 
        SET xProportionalError to xProportionalError/ABS(yProportionalError).
        SET yProportionalError to yProportionalError/ABS(yProportionalError).
    } else { 
        SET yProportionalError to yProportionalError/ABS(xProportionalError). 
        SET xProportionalError to xProportionalError/ABS(xProportionalError). 
    }

    local relativeBearing to CLAMP(xProportionalError * pitchMultiplier, -bearingLimit, bearingLimit).
    local relativePitch to -CLAMP(yProportionalError * pitchMultiplier, -pitchLimit, pitchLimit).
    
    PrintValue("Relative Bearing", relativeBearing, 21).
    PrintValue("Relative Pitch", relativePitch, 22).

    PrintValue("X Proportional Error", xProportionalError, 24).
    PrintValue("Y Proportional Error", yProportionalError, 25).


    local targetBearing to RetrogradeBearing + relativeBearing.
    local targetPitch to RetrogradePitch + relativePitch.

    return V(targetBearing, targetPitch, 0).
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
    local netAcc to (SHIP:AVAILABLETHRUST*0.8 / SHIP:MASS) - g.

    // Kinematics equation to find displacement
    local estBurnAlt to ((GetVerticalVelocity()^2) / (netAcc*2)) + CLAMP(ImpactPos:TERRAINHEIGHT + TargetPosAltituide, 0, 100000). 
    //local estBurnTime to (estBurnAlt/(0.5*netAcc))^0.5.

    return estBurnAlt.
}

function GetSuicideBurnLength {
    if SHIP:AVAILABLETHRUST = 0 { return 1. }

    local g to body:mu / (altitude + body:radius)^2.

    // Drag isn't factored in but this causes a greater margin for error, undercalculating net acceleration
    local netAcc to (SHIP:AVAILABLETHRUST*0.8 / SHIP:MASS) - g .

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
    return vDot(ship:velocity:surface, ship:north:TOPVECTOR).
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