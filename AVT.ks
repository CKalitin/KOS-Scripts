// Ascent Variables Test
// Testing the interactions between different target variables (Variables at stage sep: velocity, ap, alt, lofted trajectory constant (quadratic equation), etc.)

SET iters to 0.

until iters > 100 {
    clearScreen.

    PRINT GetHorizationVelocity().
    Print DirToPos(V(0,0,0), GetHorizationVelocity()).

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

    SET iters to iters + 1.
    wait 0.1.
}

// Return direction to position in degrees starting from 0 at north
function DirToPos {
    // Only x and y are used for lat/long. z is to be ignored
    Parameter pos1.
    Parameter pos2.

    SET diff to pos2 - pos1.

    // atan2 resolves arctan ambiguity (ASTC quadrants)
    // Reversing x and y to rotate by 90 degrees so we start at 0 degrees at north, usualy ATAN(Y, X)
    SET result to arcTan2(diff:X, diff:Y).

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