// Ascent Variables Test
// Testing the interactions between different target variables (Variables at stage sep: velocity, ap, alt, lofted trajectory constant (quadratic equation), etc.)

// Pad geoposition: LATLNG(-0.09729775, -74.55767274)

SET padpos TO LATLNG(-0.09729775, -74.55767274).

CLEARSCREEN.

//LOCK STEERING to padpos:ALTITUDEPOSITION(10000).

SET X to padpos.

PRINT(padpos:distance).
PRINT(X:distance).

SET a TO V(padpos:LAT, 0, padpos:LNG).

SET iters TO 0.

UNTIL iters > 30 {
    SET current TO V(SHIP:GEOPOSITION:LAT, 0, SHIP:GEOPOSITION:LNG).
    
    PRINT("---").
    PRINT (a).
    PRINT (current).
    PRINT (a - current).
    PRINT (a - current):MAG * 10471.975. 
    // 10471.975 is the length of one degree on Kerbin. 3769911/360

    WAIT 1.
    SET iters to iters + 1.
}
