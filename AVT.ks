// Ascent Variables Test
// Testing the interactions between different target variables (Variables at stage sep: velocity, ap, alt, lofted trajectory constant (quadratic equation), etc.)

SET iters to 0.

until iters > 20 {
    PRINT "- - -".
    //PRINT SHIP:geoposition.
    //PRINT ADDONS:TR:IMPACTPOS.
    //PRINT LatLngDist(V(SHIP:GEOPOSITION:LAT, SHIP:GEOPOSITION:LNG, 0), V(ADDONS:TR:IMPACTPOS:LAT, ADDONS:TR:IMPACTPOS:LNG, 0)).

    // Direction to landing geoposition
    PRINT DirToPos(V(SHIP:GEOPOSITION:LAT, SHIP:GEOPOSITION:LNG, 0), V(ADDONS:TR:IMPACTPOS:LAT, ADDONS:TR:IMPACTPOS:LNG, 0))-180.
    
    SET anArrow TO VECDRAW(
      V(0,0,0),
      ADDONS:TR:IMPACTPOS:POSITION,
      RGB(1,0,0),
      "See the arrow?",
      1.0,
      TRUE,
      0.2,
      TRUE,
      TRUE
    ).

    SET iters to iters + 1.
    wait 1.
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
function DirToPos {
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
