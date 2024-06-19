// Landing from 70km up

// Sites:
// Launch Pad: -0.09729775, -74.55767274
// North Landing Pad: -0.185407556445315, -74.4729356049979

// Flight Phases
// 0: Aerodynamic Control down to point near landing site at ~5000m
// 1: Fine aerodynamic control aiming for landing site
// 2: When alt - est burn altitude < 0, fire engines and modulate until reach point above landing site
// 3: Touchdown, kill horizontal velocity and center above landing site

// MORE IMPORTANT TODO: When impact pos reaches target pos there is over correction, lower the exponent here
// TODO: Redo variables in loop with Lock instead of set, this is how kOS is meant to be used
// Also, 0.1 tick length does not mean 10 ticks is one second

// Primary Launch Pad: -0.0972078320140506, -74.5576718763811
// Landing site north: -0.185407556445315, -74.4729356049979
SET targetSite to LATLNG(-0.185407556445315, -74.4729356049979).

SET flightPhase to 0.
SET tickLength to 0.25.

// CONTROL VARIABLES //
SET pitchLimit to 50.  // Pitch limit has to be high to counter act the undercorrection of kOS steering lock

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

CLEARSCREEN.

GlideToPointAboveLandingSite().

UNTIL false {
    UpdateFlightVariables().

    // Make better win condition later
    if NOT ADDONS:TR:HASIMPACT { LOCK THROTTLE TO 0. CLEARSCREEN. BREAK. }

    if flightPhase = 0 {
        GlideToTarget().

        PRINT "Suicide Burn Alt Error: " + suicideBurnAltError at (0, 9).

        if suicideBurnAltError < 0 { StartSuicideBurn(). } // If Suicide Burn is Required
        if altitude < 4000 { GlideToLandingSite(). }
    } else if flightPhase = 1 {
        GlideToTarget().

        PRINT "Suicide Burn Alt Error: " + suicideBurnAltError at (0, 9).

        if suicideBurnAltError < 0 { StartSuicideBurn(). } // If Suicide Burn is Required
    } else if flightPhase = 2 {
        LOCK STEERING TO SRFRETROGRADE.

        ControlThrottle().
    }
}

function UpdateFlightVariables{
    SET ImpactPos to GetLatLngAtAltitude(TargetPosAltituide, SHIP:OBT:ETA:PERIAPSIS, 10).

    SET suicideBurnLength to GetSuicideBurnLength().
    SET suicideBurnAltError to SHIP:ALTITUDE - GetSuicudeBurnAltitude() - 7. // -7 adjustment for craft height REMEMBER REMEMBER REMEMBER
    SET changeInSuicudeBurnAltError to (previousSuicideBurnAltError - suicideBurnAltError) / tickLength.
    SET previousSuicideBurnAltError to suicideBurnAltError.

    local impactPosAsVector to V(ImpactPos:LAT, ImpactPos:LNG, 0).
    SET impactToTargetDistance to LatLngDist(impactPosAsVector, TargetPos). // Impact point to Target point distance
    SET impactToTargetDir to DirToPoint(impactPosAsVector, TargetPos).
    
    SET changeInDistanceToTargetPerSecond to (previousImpactToTargetDistance - impactToTargetDistance) / tickLength.
    SET previousImpactToTargetDistance to impactToTargetDistance.
}

function StartSuicideBurn {
    LOCK THROTTLE TO 0.8. 
    SET TargetPosAltituide to 0. 

    SET flightPhase to 2. 
    CLEARSCREEN. 
}

function GlideToPointAboveLandingSite {
    // In first glide phase, target point 4km above landing site and offset towards our position, -180 to point towards us not away
    local offsetDir to DirToPoint(V(SHIP:geoposition:lat, SHIP:geoposition:lng, 0), V(targetSite:lat, targetSite:lng, 0))-180.
    SET offset to V(cos(offsetDir), sin(offsetDir), 0) * 280. // *150 to make offset 150 meters, hypotenuse

    SET TargetPos to AddMetersToGeoPos(targetSite, offset).
    SET TargetPosAltituide to 4000.

    SET flightPhase to 0.
    CLEARSCREEN.
}

function GlideToLandingSite {
    // In second glide phase, target point 500m above landing site
    SET TargetPos to V(targetSite:LAT, targetSite:LNG, 0).
    SET TargetPosAltituide to 0.

    SET flightPhase to 1.
    CLEARSCREEN.
}

// - - - FLIGHT FUNCTIONS - - - //
// - - - FLIGHT FUNCTIONS - - - //
// - - - FLIGHT FUNCTIONS - - - //
// - - - FLIGHT FUNCTIONS - - - //
// - - - FLIGHT FUNCTIONS - - - //

function ControlThrottle {
    local targetChangeInAltError to suicideBurnAltError / suicideBurnLength * 2.
    local currentThrottle to THROTTLE.

    if changeInSuicudeBurnAltError > targetChangeInAltError {
        LOCK THROTTLE to currentThrottle + 0.01.
    } else {
        LOCK THROTTLE to currentThrottle - 0.01.
    }

    CLAMP(currentThrottle, 0, 1).

    PRINT "Suicide Burn Alt Error: " + suicideBurnAltError at (0, 1).
    PRINT "Target Change in Alt Error: " + targetChangeInAltError at (0, 2).
    PRINT "Current Throttle: " + throttle at (0, 3).
}

// TODO TODO TODO: Adjust pitch to be around retrograde, not up
function GlideToTarget {
    // Multiply so we overcorrect, this assumes we're at terminal velocity
    // TargetPos:TERRAINHEIGHT could be use instead of ImpactPosAltitude depending on use case
    SET aproxTimeRemaining to (SHIP:altitude - TargetPosAltituide) / (SHIP:velocity:surface:mag*2).

    SET targetChangeInDistanceToTargetPerSecond to impactToTargetDistance/aproxTimeRemaining. 

    SET pitch to Clamp(targetChangeInDistanceToTargetPerSecond, 0, pitchLimit).
    SET targetHeading to Heading(impactToTargetDir-180, 90-pitch).  // -180 because aerodynamic control means we point in the opposite direction

    LOCK STEERING to targetHeading.

    PRINT "Impact to target distance: " + impactToTargetDistance at (0, 1).
    PRINT "Aprox Time Remaining: " + aproxTimeRemaining at (0, 2).

    PRINT "Change in distance to target per second: " + changeInDistanceToTargetPerSecond at (0, 4).
    PRINT "Target Change in distance to target per second: " + targetChangeInDistanceToTargetPerSecond at (0, 5).

    PRINT "Pitch: " + pitch at (0, 7).
}

// - - - HELPER FUNCTIONS - - - //
// - - - HELPER FUNCTIONS - - - //
// - - - HELPER FUNCTIONS - - - //
// - - - HELPER FUNCTIONS - - - //
// - - - HELPER FUNCTIONS - - - //

// Engines must be active to return accurate value
// Eg. use (SHIP:ALTITUDE - GetSuicudeBurnAltitude()) to get the whether the engines should be firing or not, <0 = fire
function GetSuicudeBurnAltitude {
    if SHIP:MAXTHRUST = 0 { return 0. }

    local g to body:mu / (altitude + body:radius)^2.

    // Drag isn't factored in but this causes a greater margin for error, undercalculating net acceleration, -2 to further undercalculate
    local netAcc to (SHIP:MAXTHRUST / SHIP:MASS) - g - 2.

    // Kinematics equation to find displacement, +5 bc code isn't perfect
    local estBurnAlt to ((GetVerticalVelocity()^2) / (netAcc*2)) + CLAMP(ImpactPos:TERRAINHEIGHT, 0, 100000). 
    //local estBurnTime to (estBurnAlt/(0.5*netAcc))^0.5.

    return estBurnAlt.
}

function GetSuicideBurnLength {
    if SHIP:MAXTHRUST = 0 { return 0. }

    local g to body:mu / (altitude + body:radius)^2.

    // Drag isn't factored in but this causes a greater margin for error, undercalculating net acceleration
    local netAcc to (SHIP:MAXTHRUST / SHIP:MASS) - g.

    // Kinematics equation to find displacement, +5 bc code isn't perfect
    local estBurnAlt to ((GetVerticalVelocity()^2) / (netAcc*2)) + CLAMP(ImpactPos:TERRAINHEIGHT, 0, 100000) + 5. 
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
    for x in range(0, 25) {
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
    local result to DirToPoint(V(Ship:geoposition:lat, Ship:geoPosition:lng, 0), retrogradeGeoPos) * -1 + 270. // Vector math, adjust to be centered on north
    if result > 360 { SET result to result - 360. }
    return result.
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