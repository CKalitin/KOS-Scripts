// Pad geoposition: LATLNG(-0.09729775, -74.55767274)

// Examples
function ThrustMassTWR {
    // Prograde Vector 2D
    Print DirToPoint(V(0,0,0), GetHorizationVelocity()).
    
    // Altitude of point of the orbit
    PRINT (ORBITAT(SHIP, TIME:SECONDS):body:altitudeof(SHIP:position)).
    
    // Direction to landing geoposition
    PRINT DirToPoint(V(SHIP:GEOPOSITION:LAT, SHIP:GEOPOSITION:LNG, 0), V(ADDONS:TR:IMPACTPOS:LAT, ADDONS:TR:IMPACTPOS:LNG, 0))-180.

    // Convert Kn to tons
    SET _thrust to SHIP:THRUST / 9.964016384.
    SET _mass to SHIP:MASS.
    SET _twr to _thrust / _mass -0.002.

    PRINT "thrust tons: " + _thrust.
    Print "mass: " + _mass.
    PRINT "twr: " + _twr.

    // For some reason, -0.002 is needed to make the throttle work correctly
    // When out of fuel there a divide by 0 error
    LOCK THROTTLE to SHIP:Mass/(SHIP:MAXTHRUST / 9.964016384)-0.02.

    // Use :position to get vector from geoposition
    
    SET anArrow TO VECDRAW(
      V(0,0,0),
      geoposition:position,
      RGB(1,0,0),
      "See the arrow?",
      1.0,
      TRUE,
      0.2,
      TRUE,
      TRUE
    ).
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
    Parameter min.
    Parameter max.

    if value < min { return min. }
    if value > max { return max. }
    return value.
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
