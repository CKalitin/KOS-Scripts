
// - - - Flight Functions - - - //
// - - - Flight Functions - - - //
// - - - Flight Functions - - - //
// - - - Flight Functions - - - //
// - - - Flight Functions - - - //

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

// - - - Mathematical Functions - - - //
// - - - Mathematical Functions - - - //
// - - - Mathematical Functions - - - //
// - - - Mathematical Functions - - - //
// - - - Mathematical Functions - - - //

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

function Clamp {
    Parameter value.
    Parameter minValue.
    Parameter maxValue.

    if value < minValue { return minValue. }
    if value > maxValue { return maxValue. }
    return value.
}

// Returns difference between two positions in meters
function LatLngDiff {
    // Only x and y are used for lat/long. z is to be ignored
    Parameter pos1.
    Parameter pos2.

    // 10471.975 is the length of one degree lat/long on Kerbin. 3769911/360
    return (pos1 - pos2) * 10471.975. 
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

// - - - Miscallaneous Functions - - - //
// - - - Miscallaneous Functions - - - //
// - - - Miscallaneous Functions - - - //
// - - - Miscallaneous Functions - - - //
// - - - Miscallaneous Functions - - - //

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
    SET arrowToTarget TO VECDRAW(
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
    SET arrowToImpact TO VECDRAW(
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
