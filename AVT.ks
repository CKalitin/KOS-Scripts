// Ascent Variables Test
// Testing the interactions between different target variables (Variables at stage sep: velocity, ap, alt, lofted trajectory constant (quadratic equation), etc.)

SET iters to 0.

until iters > 10 {
    PRINT GetVelocityInCompassDirections().
    Print DirToPos(V(0,0,0), GetVelocityInCompassDirections()).

    SET iters to iters + 1.
    wait 1.
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
function GetVelocityInCompassDirections {
    // https://www.reddit.com/r/Kos/comments/bwy79n/clarifications_on_shipvelocitysurface/
    SET vEast to vDot(ship:velocity:surface, ship:north:starvector).
    SET vNorth to vDot(ship:velocity:surface, ship:north:forevector).
    return v(vEast, vNorth, 0).
}