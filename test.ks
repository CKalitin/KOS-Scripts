SET iters to 0.

// PRINT "Retrograde Pitch: " + vang(srfretrograde:forevector, up:forevector) at (0, 0).
// PRINT "Heading Pitch: " + vang(ship:facing:forevector, up:forevector) at (0, 3).

// Quaternion to Compass Heading: https://forum.castle-engine.io/t/get-compass-heading-from-axis-angle-rotation/866/2

CLEARSCREEN.
until iters > 5000 {
    if AG10 { LOCK THROTTLE TO 0. CLEARSCREEN. BREAK. }

    PRINT "Retrograde Bearing: " + GetRetrogradeBearing() at (0, 0).

    SET iters to iters + 1.
    wait 0.1.
}

// Get compass bearing of retrograde by getting geoposition of retrograde point and the direction from the ship to it
function GetRetrogradeBearing {
    local retrogradeGeoPos to AddMetersToGeoPos(Ship:geoposition, GetHorizationVelocity()*1000).
    return MOD(DirToPoint(V(Ship:geoposition:lat, Ship:geoPosition:lng, 0), retrogradeGeoPos) + 90, 360). // Adjust to be centered on north, MOD = %
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

// Add meters to geo position and return as vector with lat/lng values
function AddMetersToGeoPos{
    // Both vectors, z is to be ignored when dealing with latlngs
    local Parameter geopos.
    local Parameter meters.

    // 10471.975 is the length of one degree lat/long on Kerbin. 3769911/360
    return V(geopos:lat + meters:x/10471.975, geopos:lng + meters:y/10471.975, 0). 
}


// Return east/west and north/south components of velocity
function GetHorizationVelocity {
    // https://www.reddit.com/r/Kos/comments/bwy79n/clarifications_on_shipvelocitysurface/
    SET vEast to -vDot(ship:velocity:surface, ship:north:starvector).
    SET vNorth to vDot(ship:velocity:surface, ship:north:forevector).
    return v(vEast, vNorth, 0).
}

