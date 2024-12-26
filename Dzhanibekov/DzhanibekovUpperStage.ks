run HelperFunctions.

SET leoVel to 2100.

CLEARSCREEN.
PRINT "WAITING FOR STAGING" at (0, 0).

// These values were found in the kOS terminal with "LIST ENGINES in var" "PRINT(var[1]:MAXMASSFLOW)"
SET isp to 345. // 345 is Terrier isp
SET massFlowRate to 0.017734.  // Again, Terrier engine

// Arbitrary mass between the wet mass of the upper stage and payload vs. the adding in the core stage mass
UNTIL SHIP:MASS < 4 {}
WAIT 1.

CLEARSCREEN.
Print "BURNING TO ORBIT" at (0, 0).

LOCK STEERING to HEADING(90, 0, 0).

// We aim to burn until 10 seconds after the apoapsis to get into orbit, so calculate throttle based off this target burn time
UNTIL ORBIT:PERIAPSIS > 80000 {
    SET shipdV to 9.81 * isp * ln(SHIP:MASS / SHIP:DRYMASS).
    SET remainingdVToLEO to leoVel - SHIP:VELOCITY:ORBIT:MAG.

    SET finalWetMass to SHIP:DRYMASS * 2.71828^(remainingdVToLEO / (9.81 * isp)).
    SET burnMass to SHIP:MASS - finalWetMass.
    SET burnTime to burnMass / massFlowRate.

    SET timeToAp to ETA:APOAPSIS.

    SET targetBurnTime to TimeToAp+10.

    SET targetThrottle to CLAMP(burnTime/targetBurnTime, 0.2, 1).

    LOCK THROTTLE TO CLAMP(targetThrottle, 0, 1).

    PrintValue("Engine ISP", isp, 2).
    PrintValue("Engine Mass Flow Rate (t)", massFlowRate, 3).

    PrintValue("Ship dV", shipdV, 5).
    PrintValue("Remaining dV to LEO", remainingdVToLEO, 6).

    PrintValue("Final Wet Mass (t)", finalWetMass, 8).
    PrintValue("Current Wet Mass (t)", SHIP:MASS, 9).
    PrintValue("Current Dry Mass (t)", SHIP:DRYMASS, 10).

    PrintValue("Burn Mass (t)", burnMass, 12).
    PrintValue("Burn Time Theoretical(s)", burnTime, 13).
    PrintValue("Time to Apoapsis (s)", timeToAp, 14).

    PrintValue("Target Burn Time", targetBurnTime, 16).
    PrintValue("Target Throttle", targetThrottle, 17).

    PrintValue("Apoapsis", ORBIT:APOAPSIS, 19).
    PrintValue("Periapsis", ORBIT:PERIAPSIS, 20).
}

LOCK THROTTLE TO 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

CLEARSCREEN.
Print "IN ORBIT" at (0, 0).
