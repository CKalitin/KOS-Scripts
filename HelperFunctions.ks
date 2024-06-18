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

// FAILURE:
function FindImpactLatLng {
    Parameter searchTime. // How many seconds to search for the impact point, 10 mins recommened
    Parameter altitudePrecision. // How close to 0 meters the impact point must be, 5m recommended

    Set futureTime to TIME:SECONDS + searchTime.
    Set findImpactIters to 0. // So not confused with global variables
    Set lowCutoff to 100000.
    Set highCutoff to 0.
    Set impactAltitude to lowCutoff.

    until (ABS(impactAltitude) < altitudePrecision OR findImpactIters > 50) {
        Set impactAltitude to body:altitudeof(positionat(SHIP, futureTime)).

        if impactAltitude < 0 { 
            Set lowCutoff to futureTime.
        }
        else { 
            Set highCutoff to futureTime.
        }

        Set futureTime to (lowCutoff + highCutoff) / 2.
        Set findImpactIters to findImpactIters + 1.

        Print impactAltitude.
        if ABS(impactAltitude) < altitudePrecision { break. }
    }
    
    SET anArrow TO VECDRAW(
      V(0,0,0),
      positionat(SHIP, futureTime),
      RGB(1,0,0),
      "See the arrow?",
      1.0,
      TRUE,
      0.2,
      TRUE,
      TRUE
    ).

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

    return BODY:GEOPOSITIONOF(orbitAt(SHIP, futureTime):position).
}