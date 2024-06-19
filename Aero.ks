// Areodynamic Control Test
// Steering to a target location

// MORE IMPORTANT TODO: When impact pos reaches target pos there is over correction, lower the exponent here
// TODO: Redo variables in loop with Lock instead of set, this is how kOS is meant to be used

// Primary Launch Pad: -0.09729775, -74.55767274
// Landing site north:  -0.185407556445315, -74.4729356049979
SET targetSite to LATLNG(-0.185407556445315, -74.4729356049979).
SET pitchLimit to 50.  // Pitch limit has to be high to counter act the undercorrection of kOS steering lock
SET tickLength to 0.1.
SET iters to 0.

SET previousImpactToTargetDistance to 1000.

// Flight Variables:
Set ImpactPos to LATLNG(0,0). 

until iters > 500 {
    if NOT ADDONS:TR:HASIMPACT { break. }
    CLEARSCREEN.

    // Flight Variables
    SET ImpactPos to GetLatLngAtAltitude(0, SHIP:OBT:ETA:PERIAPSIS, 10).

    DualStepControl().

    //if SHIP:ALTITUDE > 4000 {
    //    DualStepControl().
    //} else {
    //    UNLOCK STEERING.
    //    GetSuicudeBurnAltitude().
    //}

    WAIT tickLength.
    SET iters to iters + 1.
}

// Engines must be active to return accurate value
// Eg. use (SHIP:ALTITUDE - GetSuicudeBurnAltitude()) to get the whether the engines should be firing or not, <0 = fire
function GetSuicudeBurnAltitude {
    local g to body:mu / (altitude + body:radius)^2.

    // Drag isn't factored in but this causes a greater margin for error, undercalculating net acceleration
    local netAcc to (SHIP:MAXTHRUST / SHIP:MASS) - g.

    // Kinematics equation to find displacement, +5 bc code isn't perfect
    local estBurnAlt to ((GetVerticalVelocity()^2) / (netAcc*2)) + CLAMP(ImpactPos:TERRAINHEIGHT, 0, 100000) + 5. 
    //local estBurnTime to (estBurnAlt/(0.5*netAcc))^0.5.

    return estBurnAlt.
}

// Aiming for a point in two steps (first to x meters above target, then to target)
function DualStepControl{
    local impactGeoPos to V(0,0,0).
    local impactPosVector to V(0,0,0).

    if ship:altitude > 2000 {
        SET impactGeoPos to GetLatLngAtAltitude(2000, SHIP:OBT:ETA:PERIAPSIS, 10).
        SET impactPosVector to V(impactGeoPos:LAT, impactGeoPos:LNG, 0).

        // TODO: Use normalized latlng direction for adjustment
        SET targetPos to AddMetersToGeoPos(targetSite, V(70,100,0)).

    } else{
        SET impactGeoPos to GetLatLngAtAltitude(0, SHIP:OBT:ETA:PERIAPSIS, 10).
        SET impactPosVector to V(impactGeoPos:LAT, impactGeoPos:LNG, 0).

        SET targetPos to V(targetSite:lat, targetSite:lng, 0).
    }

    SET impactToTargetDistance to LatLngDist(impactPosVector, targetPos). // Impact point to Target point distance
    SET impactToTargetDir to DirToPoint(impactPosVector, targetPos)-180. // -180 because we're going retrograde
    SET aproxTimeRemaining to (SHIP:altitude) / (SHIP:velocity:surface:mag^1.5). // *4 to overcorrect, this works at terminal velocity

    SET changeInDistanceToTargetPerSecond to (previousImpactToTargetDistance - impactToTargetDistance) / tickLength.
    SET previousImpactToTargetDistance to impactToTargetDistance.
    SET targetChangeInDistanceToTargetPerSecond to impactToTargetDistance/aproxTimeRemaining. 

    SET pitch to Clamp(targetChangeInDistanceToTargetPerSecond, 0, pitchLimit).
    SET targetHeading to Heading(impactToTargetDir, 90-pitch).

    LOCK STEERING to targetHeading.

    PRINT "Impact to target direction: " + impactToTargetDir.
    PRINT "Aprox Time Remaining: " + aproxTimeRemaining.
    PRINT " ".
    PRINT "Impact to target distance: " + impactToTargetDistance.
    PRINT "Change in distance to target per second: " + changeInDistanceToTargetPerSecond.
    PRINT "Target Change in distance to target per second: " + targetChangeInDistanceToTargetPerSecond.
    PRINT " ".
    PRINT "Pitch: " + pitch.
    PRINT " ".
    PRINT "Iters: " + iters.
}

// Aiming for a point in a single step (directly to point)
function SingleStepControl{
    // THIS IS TEMPORARY, DO IT BETTER LATER
    if NOT ADDONS:TR:HASIMPACT { return. }

    SET impactGeoPos to GetLatLngAtAltitude(0, SHIP:OBT:ETA:PERIAPSIS, 10).
    SET impactPosVector to V(impactGeoPos:LAT, impactGeoPos:LNG, 0).

    SET impactToTargetDistance to LatLngDist(impactPosVector, V(targetSite:LAT, targetSite:LNG, 0)). // Impact point to Target point distance
    SET impactToTargetDir to DirToPoint(impactPosVector, V(targetSite:LAT, targetSite:LNG, 0))-180. // -180 because we're going retrograde
    SET aproxTimeRemaining to (SHIP:altitude - 1000) / (SHIP:velocity:surface:mag*4).

    SET changeInDistanceToTargetPerSecond to (previousImpactToTargetDistance - impactToTargetDistance) / tickLength.
    SET previousImpactToTargetDistance to impactToTargetDistance.
    SET targetChangeInDistanceToTargetPerSecond to impactToTargetDistance/aproxTimeRemaining. 

    SET pitch to Clamp(targetChangeInDistanceToTargetPerSecond, 0, pitchLimit).
    SET targetHeading to Heading(impactToTargetDir, 90-pitch).

    LOCK STEERING to targetHeading.

    PRINT "Impact to target direction: " + impactToTargetDir.
    PRINT "Aprox Time Remaining: " + aproxTimeRemaining.
    PRINT " ".
    PRINT "Impact to target distance: " + impactToTargetDistance.
    PRINT "Change in distance to target per second: " + changeInDistanceToTargetPerSecond.
    PRINT "Target Change in distance to target per second: " + targetChangeInDistanceToTargetPerSecond.
    PRINT " ".
    PRINT "Pitch: " + pitch.
    PRINT " ".
    PRINT "Iters: " + iters.
}

// HELPER FUNCTIONS
// HELPER FUNCTIONS
// HELPER FUNCTIONS

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
    SET result to arcTan2(diff:Y, diff:X).

    // Keep degress between 0 and 360
    if result < 0 { SET result to result + 360. }

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
    return vDot(ship:velocity:surface, ship:up:vector).
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