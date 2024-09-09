// New Refactor

// With only initial locks, code runs at 80% real time
// Had to stop using LOCKs, far too slow, maybe something to do with the functions
// Just 4 iterations of glide take 1 second. Cant do that as fast as physics ticks. Something is very wrong with the code.

// Use LOCK on all variables instead of loop
// Only use a loop to print variables
// WHEN inside loop for flight phase changes

// Primary Launch Pad: -0.0972078320140506, -74.5576718763811
// Landing site north: -0.185407556445315, -74.4729356049979
// VAB East Helipad:   -0.0967999401268479, -74.617417864482

run HelperFunctions.

// - - - Config Variables - - - //
// - - - Config Variables - - - //
// - - - Config Variables - - - //

DECLARE GLOBAL TargetSite to LATLNG(-0.0972078320140506, -74.5576718763811).

DECLARE GLOBAL TickLength to 0.1.

DECLARE GLOBAL RadarOffset to 6.5.

// - - - Global Flight Variables - - - //
// - - - Global Flight Variables - - - //
// - - - Global Flight Variables - - - //

DECLARE GLOBAL TargetPos to targetSite. // Adjusted landing site, eg. if you want to be 50m away from site to overshoot during aero guidance
DECLARE GLOBAL TargetPosAltitude to 0.

// - - - Global Flight Variables Updated Every Frame - - - //
// - - - Global Flight Variables Updated Every Frame - - - //
// - - - Global Flight Variables Updated Every Frame - - - //

LOCK TrueAltitude to SHIP:ALTITUDE - RadarOffset.

SET PitchLimit to 45.

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

    UNTIL FALSE {
        SET ImpactPos to GetImpactPos().
        SET TargetPos to AddMetersToGeoPos(targetSite, V(0, 0, 0)).

        local ImpactToTargetDir to DirToPoint(ImpactPos, TargetPos).
        local TargetHeading to Heading(ImpactToTargetDir, 0).
        LOCK STEERING to TargetHeading.

        PRINT "Flight Phase: Orient for Boostback Burn (" + FlightPhase + "/4)" at (0, 0).

        PrintValue("Direction Error", vAng(targetHeading:vector, ship:facing:vector), 2).
    
        if AG10 { BREAK. } // Manual User Break
        if vAng(targetHeading:vector, ship:facing:vector) < 30 { BREAK. }

        WAIT TickLength.
    }

    BoostbackBurn(). 
}

function BoostbackBurn {
    SET FlightPhase to 1.
    CLEARSCREEN.

    LOCK THROTTLE TO 1.

    SET TargetPos to targetSite.

    UNTIL FALSE {
        SET ImpactPos to GetImpactPos().

        local ImpactToTargetDist to LatLngDist(ImpactPos, TargetPos).
        local ChangeInDistanceToTargetPerSecond to GetChangeInDistanceToTargetPerSecond().
        
        PRINT "Flight Phase: Boostback Burn (" + FlightPhase + "/4)" at (0, 0).

        PrintValue("Impact to Target Error", ImpactToTargetDist, 2).
        PrintValue("Change in Distance to Target", ChangeInDistanceToTargetPerSecond, 3).

        if AG10 { BREAK. } // Manual User Break
        if (ABS(ImpactToTargetDist) < 500 OR (ChangeInDistanceToTargetPerSecond > 100 AND ChangeInDistanceToTargetPerSecond < 5000)) { BREAK. } // For whatever reason, printing is required above this line to not trigger the break

        WAIT TickLength.
    }

    LOCK THROTTLE TO 0.

    GlideToLandingSite().
}

function GlideToLandingSite {
    SET FlightPhase to 2.
    CLEARSCREEN.

    UNTIL FALSE {
        SET PitchLimit to CLAMP((400/ship:velocity:surface:mag)*40, 0, 50). // Adjust pitch limit based on velocity

        local DisplacementEstimate to GetSuicideBurnNetDisplacementEstimate() + 8. // Offset by 8 meters, I don't like this kind of tuning
        SET TargetPos to AddMetersToGeoPos(targetSite, GetOffsetPosFromTargetSite(-displacementEstimate)).
        SET TargetPosAltitude to 0.

        SET ImpactPos to GetImpactPos().
        local ImpactToTargetDist to LatLngDist(ImpactPos, TargetPos).

        local PitchMultiplier to (ImpactToTargetDist^1.5)/80. // Fine control that asymptotically approaches the target, avoid large overcorrection
        local TargetHeading To GetSteeringRelativeToRetrograde(PitchMultiplier).
        LOCK STEERING TO TargetHeading.

        SET SuicideBurnAltitude to GetSuicideBurnAltitude().

        PRINT "Flight Phase: Glide to Landing Site (" + FlightPhase + "/4)" at (0, 0).

        PrintValue("Distance from Impact to Target", ImpactToTargetDist, 2).

        PrintValue("Pitch Limit", pitchLimit, 4).
        PrintValue("Pitch Multiplier", PitchMultiplier, 5).

        PrintValue("Displacement Estimate", DisplacementEstimate, 7).

        PrintValue("True Altitude", TrueAltitude, 9).
        PrintValue("Suicide Burn Altitude", SuicideBurnAltitude, 10).

        if AG10 { BREAK. } // Manual User Break
        if TrueAltitude < 4000 AND TrueAltitude < SuicideBurnAltitude { BREAK. }

        WAIT TickLength.
    }

    SuicideBurn().
}

function SuicideBurn {
    SET FlightPhase to 3.
    CLEARSCREEN.

    SET TargetPos to V(targetSite:Lat, targetSite:Lng, 0).
    SET TargetPosAltitude to 20.
    SET PitchLimit to 15.

    UNTIL FALSE {
        SET ImpactPos to GetImpactPos().
        local ImpactToTargetDist to LatLngDist(ImpactPos, TargetPos).

        local PitchMultiplier to (ImpactToTargetDist^1.5)/80. // Fine control that asymptotically approaches the target, avoid large overcorrection
        local TargetHeading To GetSteeringRelativeToRetrograde(-PitchMultiplier).

        LOCK STEERING TO TargetHeading.

        SET SuicideBurnAltitude to GetSuicideBurnAltitude() + 50.
        SET SuicideBurnAltError to SuicideBurnAltitude - TrueAltitude.
        SET SuicideBurnLength to GetSuicideBurnLength().

        SET TargetChangeInAltError to (SuicideBurnAltError / SuicideBurnLength) * 4.  // *4 so that we correct throttle in a fourth of remaining time
        SET CurrentThrottle to throttle.
        SET ThrottleChange to CLAMP(TargetChangeInAltError, -0.1, 0.1).
        LOCK THROTTLE to CLAMP(CurrentThrottle + ThrottleChange, 0, 1).

        PRINT "Flight Phase: Suicide Burn (" + FlightPhase + "/4)" at (0, 0).

        PrintValue("Pitch Multiplier", PitchMultiplier, 2).

        PrintValue("True Altitude", TrueAltitude, 4).
        PrintValue("Suicide Burn Alt", SuicideBurnAltitude, 5).
        PrintValue("Suicide Burn Alt Error", SuicideBurnAltError, 6).
        PrintValue("Suicide Burn Length", SuicideBurnLength, 7).

        PrintValue("Target Change In Alt Error", TargetChangeInAltError, 9).
        PrintValue("Throttle Change", ROUND(ThrottleChange, 2), 10).

        PrintValue("Current Throttle", Round(throttle, 2), 11).

        if AG10 { BREAK. } // Manual User Break
        if (TrueAltitude < TargetPosAltitude OR ship:velocity:surface:mag < 45) { BREAK. }

        WAIT TickLength.
    }

    SoftTouchdown().
}

function SoftTouchdown {
    SET FlightPhase to 4.
    CLEARSCREEN.

    SET TargetPos to V(targetSite:Lat, targetSite:Lng, 0).
    SET TargetPosAltitude to 0.

    UNTIL FALSE {
        SET PitchLimit to 5.
        SET TargetVerticalVelocity to Lerp(-2, -10, CLAMP(TrueAltitude / 50, 0, 1)). // Lerp from -2 to -10 based on altitude, slowly touch down
        SET AproxTimeRemaining to CLAMP((TrueAltitude - TargetPosAltitude) / (SHIP:velocity:surface:mag*2), 0, 10). // Assuming Constant Velocity
        SET PitchMultiplier to Lerp(0, pitchLimit, CLAMP(GetHorizontalVelocity():MAG/10, 0, 1)). // Lerp from 0 to pitch limit based on horizontal velocity

        SET TargetHeading to HEADING(RetrogradeBearing, 90 - pitchMultiplier, 0).
        LOCK STEERING TO TargetHeading.

        SET BaseThrottle to SHIP:Mass/(SHIP:MAXTHRUST / 9.964016384)-0.02. // Hover, 9.964016384 for Kn to tons, -0.02 adjustment
        SET ChangeInVerticalVelocity to GetChangeInVerticalVelocity().
        SET TargetChangeInVerticalVelocity to (TargetVerticalVelocity - GetVerticalVelocity()) / aproxTimeRemaining / 50. // 50 frames per second ew, get delta time do better
        SET ThrottleChange to Clamp(TargetChangeInVerticalVelocity, -0.2, 0.2).
        LOCK THROTTLE to Clamp(BaseThrottle + ThrottleChange, 0, 1).

        
        PRINT "Flight Phase: Touchdown (" + FlightPhase + "/4)" at (0, 0). 

        PrintValue("Aprox Time Remaining", AproxTimeRemaining, 2).

        PrintValue("Vertical Velocity", GetVerticalVelocity(), 4).
        PrintValue("Target Vertical Velocity", TargetVerticalVelocity, 5).

        PrintValue("Change in Vertical Velocity", ChangeInVerticalVelocity, 7).
        PrintValue("Target Change in Vertical Velocity", TargetChangeInVerticalVelocity, 8).

        PrintValue("Base Throttle", BaseThrottle, 10).
        PrintValue("Throttle Change", ThrottleChange, 11).

        PrintValue("Current Throttle", Round(throttle, 2), 13).

        PrintValue("Pitch Multiplier", PitchMultiplier, 15).

        PrintValue("True Altitude", TrueAltitude, 17).

        if AG10 { BREAK. } // Manual User Break
        if NOT ADDONS:TR:HASIMPACT { BREAK. }
        
        WAIT TickLength.
    }
}