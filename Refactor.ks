@LAZYGLOBAL OFF.

// Refactoring land.ks
// Global variables are capitalized

// Use LOCK on all variables instead of loop
// Only use a loop to print variables
// WAIT UNTIL for flight phase changes

// Primary Launch Pad: -0.0972078320140506, -74.5576718763811
// Landing site north: -0.185407556445315, -74.4729356049979
// VAB East Helipad:   -0.0967999401268479, -74.617417864482

// IT NEEDS TO USE WHEN NOT UNTIL!!!!!
// IT NEEDS TO USE WHEN NOT UNTIL!!!!!
// IT NEEDS TO USE WHEN NOT UNTIL!!!!!
// IT NEEDS TO USE WHEN NOT UNTIL!!!!!
// IT NEEDS TO USE WHEN NOT UNTIL!!!!!

run HelperFunctions.

// - - - Config Variables - - - //
// - - - Config Variables - - - //
// - - - Config Variables - - - //

DECLARE GLOBAL TargetSite to LATLNG(-0.0972078320140506, -74.5576718763811).

DECLARE GLOBAL PrintTickLength to 0.1. // Prints variables every x seconds

DECLARE GLOBAL RadarOffset to 6.5.

// - - - Flight Variables - - - //
// - - - Flight Variables - - - //
// - - - Flight Variables - - - //

DECLARE GLOBAL FlightPhase to 0.

DECLARE GLOBAL TargetPos to targetSite. // Adjusted landing site, eg. if you want to be 50m away from site to overshoot during aero guidance
DECLARE GLOBAL TargetPosAltitude to 0.
DECLARE GLOBAL TargetVerticalVelocity to 0.

// - - - Flight Variables Updated Every Frame - - - //
// - - - Flight Variables Updated Every Frame - - - //
// - - - Flight Variables Updated Every Frame - - - //

LOCK TargetHeading to HEADING(0, 0).
LOCK STEERING to TargetHeading.

LOCK TrueAltitude to SHIP:ALTITUDE - RadarOffset.

LOCK PitchLimit to 45.

LOCK ImpactPos to GetImpactPos().

LOCK ImpactToTargetDir to DirToPoint(ImpactPos, TargetPos).
LOCK ImpactToTargetDist to LatLngDist(ImpactPos, TargetPos).
LOCK ChangeInDistanceToTargetPerSecond to GetChangeInDistanceToTargetPerSecond().

LOCK SuicideBurnLength to GetSuicideBurnLength().
LOCK SuicideBurnAltitude to GetSuicudeBurnAltitude().
LOCK TargetChangeInAltError to 1.
LOCK ChangeInSuicideBurnAltError to GetChangeInSuicideBurnAltError().

LOCK ChangeInVerticalVelocity to GetChangeInVerticalVelocity().

LOCK RetrogradePitch to 90 - vang(srfretrograde:forevector, up:forevector).
LOCK RetrogradeBearing to GetRetrogradeBearing().

// - - - Local Variables That Must Be Printed - - - //
// - - - Local Variables That Must Be Printed - - - //
// - - - Local Variables That Must Be Printed - - - //

DECLARE GLOBAL PitchMultiplier to 1.
DECLARE GLOBAL HeadingMultiplier to 1.
DECLARE GLOBAL AproxTimeRemaining to 1.
DECLARE GLOBAL TargetChangeInDistanceToTargetPerSecond to 1.
DECLARE GLOBAL TargetChangeInVerticalVelocity to 1.
DECLARE GLOBAL BaseThrottle to 1.
DECLARE GLOBAL ThrottleChange to 1.
DECLARE GLOBAL SuicideBurnAltError to 1.

// - - - Begin Flight - - - //
// - - - Begin Flight - - - //
// - - - Begin Flight - - - //

CLEARSCREEN.
CLEARVECDRAWS().

SET gear to false.
//OrientForBoostbackBurn().
GlideToLandingSite().

// This loop is mainly necessary for printing variables, maybe there's a better way
// Horrible code, GUI widget is required for printing, then move completion into flight functions using WAIT UNTIL
until false {
    // If impact or zero key pressed, stop the script
    if NOT ADDONS:TR:HASIMPACT { LOCK THROTTLE TO 0. CLEARSCREEN. BREAK. }
    if AG10 { LOCK THROTTLE TO 0. CLEARSCREEN. BREAK. }
    
    // Print the current flight phase
    if FlightPhase = 0 { PrintOrientForBoostbackBurn(). }
    else if FlightPhase = 1 { PrintBoostbackBurn(). }
    else if FlightPhase = 2 { PrintGlideToLandingSite(). }
    else if FlightPhase = 3 { PrintFinalAeroDescent(). }
    else if FlightPhase = 4 { PrintSuicideBurn(). }
    else if FlightPhase = 5 { PrintTouchdown(). }

    // Flight Phase Completion
    if FlightPhase = 0 AND vAng(targetHeading:vector, ship:facing:vector) < 30 { BoostbackBurn(). }
    else if FlightPhase = 1 AND (ABS(ImpactToTargetDist) < 1000 OR ChangeInDistanceToTargetPerSecond > 100) { GlideToLandingSite(). }
    else if FlightPhase = 2 AND TrueAltitude < 4000 { FinalAeroDescent(). }
    else if FlightPhase = 3 AND TrueAltitude < SuicideBurnAltitude { SuicideBurn(). }
    else if FlightPhase = 4 AND (TrueAltitude < TargetPosAltitude OR ship:velocity:surface:mag < 45) { Touchdown(). }

    WAIT PrintTickLength.
}

// - - - Flight Functions - - - //
// - - - Flight Functions - - - //
// - - - Flight Functions - - - //
// - - - Flight Functions - - - //
// - - - Flight Functions - - - //

function OrientForBoostbackBurn {
    SET FlightPhase to 0.
    CLEARSCREEN.

    LOCK TargetHeading to Heading(ImpactToTargetDir, 0).
}

function BoostbackBurn {
    SET FlightPhase to 1.
    CLEARSCREEN.

    LOCK THROTTLE to 1.
}

function GlideToLandingSite {
    SET FlightPhase to 2.
    CLEARSCREEN.

    LOCK THROTTLE to 0.

    SET TargetPos to V(targetSite:LAT, targetSite:LNG, 0).
    SET TargetPosAltitude to 0.

    LOCK PitchLimit to CLAMP((400/ship:velocity:surface:mag)*40, 0, 50). // Adjust pitch limit based on velocity
    LOCK PitchMultiplier to (ImpactToTargetDist^1.6)/15. // Fine control that asymptotically approaches the target, avoid large overcorrection
    LOCK TargetHeading To GetSteeringRelativeToRetrograde(PitchMultiplier).
}

function FinalAeroDescent {
    SET FlightPhase to 3.
    CLEARSCREEN.

    SET TargetPos to AddMetersToGeoPos(targetSite, GetOffsetPosFromTargetSite(-30)).
    SET TargetPosAltitude to 0.

    LOCK PitchLimit to 45.
    LOCK PitchMultiplier to (ImpactToTargetDist^1.6)/15. // Fine control that asymptotically approaches the target, avoid large overcorrection
    LOCK TargetHeading To GetSteeringRelativeToRetrograde(PitchMultiplier).
}

function SuicideBurn {
    SET FlightPhase to 4.
    CLEARSCREEN.

    local magnitude to -(GetHorizationVelocity():mag^1.67) / 45. // Offset by multiple of current horizontal velocity
    SET TargetPos to AddMetersToGeoPos(targetSite, GetOffsetPosFromTargetSite(magnitude)).
    SET TargetPosAltitude to 20.
    
    LOCK PitchLimit to 15.
    LOCK PitchMultiplier to CLAMP((ImpactToTargetDist^1.5)/10, 0, pitchLimit).
    LOCK TargetHeading to GetSteeringRelativeToRetrograde(-pitchMultiplier). // Negative because we are propulsive, not aero now, it's simple

    LOCK SuicideBurnAltError to TrueAltitude - GetSuicudeBurnAltitude().
    LOCK TargetChangeInAltError to (SuicideBurnAltError / SuicideBurnLength) * 4.  // *4 so that we correct throttle in a fourth of remaining time
    LOCK ThrottleChange to CLAMP(TargetChangeInAltError, -0.05, 0.05).
    LOCK THROTTLE to CLAMP(SHIP:CONTROL:PILOTMAINTHROTTLE + ThrottleChange, 0, 1).
}

function Touchdown {
    SET FlightPhase to 5.
    CLEARSCREEN.

    SET TargetPos to V(targetSite:LAT, targetSite:LNG, 0).
    SET TargetPosAltitude to 0.

    LOCK PitchLimit to 5.
    LOCK TargetVerticalVelocity to Lerp(-2, -10, CLAMP(TrueAltitude / 50, 0, 1)). // Lerp from -2 to -10 based on altitude, slowly touch down
    LOCK AproxTimeRemaining to CLAMP((TrueAltitude - TargetPosAltitude) / (SHIP:velocity:surface:mag*2), 0, 10). // Assuming Constant Velocity
    LOCK PitchMultiplier to Lerp(0, pitchLimit, CLAMP(GetHorizationVelocity():MAG/10, 0, 1)). // Lerp from 0 to pitch limit based on horizontal velocity

    LOCK TargetHeading to HEADING(RetrogradeBearing, 90 - pitchMultiplier, 0).

    LOCK BaseThrottle to SHIP:Mass/(SHIP:MAXTHRUST / 9.964016384)-0.02. // Hover, 9.964016384 for Kn to tons, -0.02 adjustment
    LOCK TargetChangeInVerticalVelocity to (TargetVerticalVelocity - GetVerticalVelocity()) / aproxTimeRemaining / 50. // 50 frames per second ew, get delta time do better
    LOCK ThrottleChange to Clamp(TargetChangeInVerticalVelocity, -0.2, 0.2).
    LOCK THROTTLE to Clamp(BaseThrottle + ThrottleChange, 0, 1).
}

// - - - Print Functions - - - //
// - - - Print Functions - - - //
// - - - Print Functions - - - //
// - - - Print Functions - - - //
// - - - Print Functions - - - //

function PrintOrientForBoostbackBurn {
    PRINT "Flight Phase: Orient for Boostback Burn (" + FlightPhase + "/5)" at (0, 0).

    PrintValue("Direction Error", vAng(targetHeading:vector, ship:facing:vector), 2).
}

function PrintBoostbackBurn{
    PRINT "Flight Phase: Boostback Burn (" + FlightPhase + "/5)" at (0, 0).

    PrintValue("Impact to Target Error", ImpactToTargetDist, 2).
    PrintValue("Change in Distance to Target", ChangeInDistanceToTargetPerSecond, 3).
}

function PrintGlideToLandingSite {
    PRINT "Flight Phase: Glide to Landing Site (" + FlightPhase + "/5)" at (0, 0).

    PrintValue("Distance from Impact to Target", ImpactToTargetDist, 2).

    PrintValue("Target Change in Distance to Target Per Second", TargetChangeInDistanceToTargetPerSecond, 4).
    PrintValue("Change in Distance to Target Per Second", ChangeInDistanceToTargetPerSecond, 5).

    PrintValue("Pitch Limit", pitchLimit, 7).
    PrintValue("Pitch Multiplier", PitchMultiplier, 8).
}

function PrintFinalAeroDescent {
    PRINT "Flight Phase: Final Aero Descent (" + FlightPhase + "/5)" at (0, 0).

    PrintValue("Distance from Impact to Target", ImpactToTargetDist, 2).

    PrintValue("Target Change in Distance to Target Per Second", TargetChangeInDistanceToTargetPerSecond, 4).
    PrintValue("Change in Distance to Target Per Second", ChangeInDistanceToTargetPerSecond, 5).

    PrintValue("Pitch Limit", pitchLimit, 7).
    PrintValue("Pitch Multiplier", PitchMultiplier, 8).
}

function PrintSuicideBurn {
    PRINT "Flight Phase: Suicide Burn (" + FlightPhase + "/5)" at (0, 0).

    PrintValue("Pitch Multiplier", PitchMultiplier, 2).
    PrintValue("Heading Multiplier", HeadingMultiplier, 3).

    PrintValue("Suicide Burn Alt Error", SuicideBurnAltitude, 5).

    PrintValue("Throttle Change", ROUND(ThrottleChange, 2), 7).

    PrintValue("Current Throttle", Round(throttle, 2), 9).
}

function PrintTouchdown {
    PRINT "Flight Phase: Touchdown (" + FlightPhase + "/5)" at (0, 0). 

    PrintValue("Aprox Time Remaining", AproxTimeRemaining, 2).

    PrintValue("Vertical Velocity", GetVerticalVelocity(), 4).
    PrintValue("Target Vertical Velocity", TargetVerticalVelocity, 5).

    PrintValue("Change in Vertical Velocity", ChangeInVerticalVelocity, 7).
    PrintValue("Target Change in Vertical Velocity", TargetChangeInVerticalVelocity, 8).

    PrintValue("Base Throttle", BaseThrottle, 10).
    PrintValue("Throttle Change", ThrottleChange, 11).

    PrintValue("Current Throttle", throttle, 13).

    PrintValue("Pitch Multiplier", PitchMultiplier, 15).

    PrintValue("True Altitude", TrueAltitude, 17).

}