// Areodynamic Control Test
// Steering to a target location

// Control Flow, Loop:
// Get difference between current impact and target site
// Get heading to target site in a form suitable for vehicle control
// Get time until burn start (eg. time to 1000m)
// Use remaining time and difference between current impact and target site to calculate / modulate steering
// Display pertinent variables
// When low enough, 100% throttle for 10 seconds, then end

// TODO: Target point above the landing location (so landing is more vertical)
// TODO: Redo variables in loop with Lock instead of set, this is how kOS is meant to be used

SET targetSite to LATLNG(-0.09729775, -74.55767274). // Launch pad // -0.09729775, -74.55767274
SET previousImpactToTargetDistance to 1000.
SET pitchLimit to 50.  // Pitch limit has to be high to counter act the undercorrection of kOS steering lock
SET tickLength to 0.25.
SET iters to 0.

until iters > 1500 {
    CLEARSCREEN.

    // THIS IS TEMPORARY, DO IT BETTER LATER
    if NOT ADDONS:TR:HASIMPACT { BREAK. }
    //if SHIP:ALTITUDE < 750 { Lock STEERING to retrograde. }

    SET impactGeoPos to GetLatLngAtAltitude(0, 200, 10).
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

    SET anArrow TO VECDRAW(
      V(0,0,0),
      impactGeoPos:position,
      RGB(1,0,0),
      "See the arrow?",
      1.0,
      TRUE,
      0.2,
      TRUE,
      TRUE
    ).

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

    WAIT tickLength.
    SET iters to iters + 1.
}

// HELPER FUNCTIONS
// HELPER FUNCTIONS
// HELPER FUNCTIONS

// Return the lat/long of the position at a given altitude a future range
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
    SET vEast to vDot(ship:velocity:surface, ship:north:starvector).
    SET vNorth to vDot(ship:velocity:surface, ship:north:forevector).
    return v(vEast, vNorth, 0).
}

function GetVerticalVelocity {
    return vDot(ship:velocity, ship:up:vector).
}

function Clamp {
    Parameter value.
    Parameter minValue.
    Parameter maxValue.

    if value < minValue { return minValue. }
    if value > maxValue { return maxValue. }
    return value.
}