@LAZYGLOBAL OFF.

// Refactoring land.ks
// Global variables are capitalized

// Use LOCK on all variables instead of loop
// Only use a loop to print variables
// WAIT UNTIL for flight phase changes

// Primary Launch Pad: -0.0972078320140506, -74.5576718763811
// Landing site north: -0.185407556445315, -74.4729356049979
// VAB East Helipad:   -0.0967999401268479, -74.617417864482

run HelperFunctions.

// - - - Config Variables - - - //
// - - - Config Variables - - - //
// - - - Config Variables - - - //

DECLARE GLOBAL TargetSite to LATLNG(-0.0967999401268479, -74.617417864482).

DECLARE GLOBAL PrintTickLength to 0.5. // Prints variables every x seconds

DECLARE GLOBAL RadarOffset to 6.5.

// - - - Flight Variables - - - //
// - - - Flight Variables - - - //
// - - - Flight Variables - - - //

DECLARE GLOBAL FlightPhase to 0.
DECLARE GLOBAL PitchLimit to 45.

DECLARE GLOBAL TargetPos to targetSite. // Adjusted landing site, eg. if you want to be 50m away from site to overshoot during aero guidance
DECLARE GLOBAL TargetPosAltitude to 0.
DECLARE GLOBAL TargetVerticalVelocity to 0.

// - - - Flight Variables Updated Every Frame - - - //
// - - - Flight Variables Updated Every Frame - - - //
// - - - Flight Variables Updated Every Frame - - - //

LOCK TrueAltituide to SHIP:ALTITUDE - SHIP:OBT_ALTITUDE.

LOCK ImpactPos to GetImpactPos().

LOCK ImpactToTargetDir to DirToPoint(ImpactPos, TargetPos).
LOCK ImpactToTargetDist to GetChangeInDistanceToTargetPerSecond().

LOCK SuicideBurnLength to GetSuicideBurnLength().
LOCK SuicideBurnAltitude to GetSuicudeBurnAltitude().
// Maybe a changeinsuicudeburnalterror is needed? or new technique?

LOCK ChangeInVerticalVelocity to GetChangeInVerticalVelocity().

LOCK RetrogradePitch to 90 - vang(srfretrograde:forevector, up:forevector).
LOCK RetrogradeBearing to GetRetrogradeBearing().

// - - - Begin Flight - - - //
// - - - Begin Flight - - - //
// - - - Begin Flight - - - //

CLEARSCREEN.
CLEARVECDRAWS().

SET gear to false.
OrientForBoostbackBurn().

// - - - Flight Functions - - - //
// - - - Flight Functions - - - //
// - - - Flight Functions - - - //
// - - - Flight Functions - - - //
// - - - Flight Functions - - - //

function OrientForBoostbackBurn {
    SET FlightPhase to 0.
    CLEARSCREEN.

    LOCK targetHeading to Heading(ImpactToTargetDir, 0).
    LOCK STEERING to targetHeading.

    WAIT UNTIL vAng(targetHeading:vector, ship:facing:vector) < 30.
    BoostbackBurn().
}

function BoostbackBurn {
    SET FlightPhase to 1.
    CLEARSCREEN.
}

// - - - Print Functions - - - //
// - - - Print Functions - - - //
// - - - Print Functions - - - //
// - - - Print Functions - - - //
// - - - Print Functions - - - //

// This is below OrientForBoostbackBurn so it isn't printing
Until false {
    if FlightPhase = 1 { PrintOrientForBoostbackBurn(). }
    WAIT PrintTickLength.
}

function PrintOrientForBoostbackBurn {
    Print "Flight Phase: Orient for Boostback Burn (" + FlightPhase + "/6)" at (0, 0).

    PrintValue("Direction Error", vAng(targetHeading:vector, ship:facing:vector), 2).
}