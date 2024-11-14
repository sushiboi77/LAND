// Author: sushiboi
// main.ks is a boot file that will run this program on start
// designed for booster propulsive landing on KERBIN only
// all heights are in meters unless stated otherwise
// all speed, velocities, and acceleration are in meters per second (squared) unless stated otherwise

/////////////////////////////////////////////// Initialization
set agloffset to 70.
set entryburnendalt to 40000.
set entryburnendspeed to 600.
set maxaoa to 30.
set geardeployheight to 90.
set targpos to 0.
set landingpos to 0.
set main_engine to SHIP:PARTSNAMED("SEP.23.BOOSTER.CLUSTER")[0].

/////////////////////////////// FUNCTIONS AND CUSTOM EXPRESSIONS /////////////////////////////////

function geodist {
    parameter pos1.
    parameter pos2.
    return (pos1:position - pos2:position):mag.
}

function errorvec {
    parameter impactpos.
    parameter targposs.
    local v1 to impactpos:position - targposs:position.
    local v2 to VECTOREXCLUDE(ship:up:forevector, v1).
    return v2.
}

function vec_to_target {
    parameter targposs.
    local v1 to targposs:position - ship:position.
    local v2 to VECTOREXCLUDE(ship:up:forevector, v1).
    return v2.
}

function landingspeed {
    parameter speed.
    parameter maxacc.
    parameter shipVerticalSpeed.
    return ((constant:g0) - (speed + shipVerticalSpeed)) / maxacc.
}

function entrydisplacement {
    parameter entryburnendspeedd.
    parameter shipVelocityMag.
    parameter maxacc.
    return abs((entryburnendspeedd^2 - shipVelocityMag^2) / (2 * maxacc)).
}

function getentryburnstartalt {
    parameter entryburnendaltt.
    parameter entryDisplacementValue.
    return entryburnendaltt + entryDisplacementValue.
}

function getsteeringlanding {
    parameter maxaoaa.
    parameter errorvecValue.
    parameter shipVelocitySurface.
    local vec is -shipVelocitySurface - errorvecValue.
    if vAng(vec, -shipVelocitySurface) > maxaoaa {
        set vec to -shipVelocitySurface:normalized - tan(maxaoaa) * errorvecValue:normalized.
    }
    return vec.
}

function getsteeringlanding2 {
    parameter upForeVector.
    parameter maxaoaa.
    parameter errorvecValue.
    local vec is upForeVector * 70 - errorvecValue.
    if vAng(vec, upForeVector) > maxaoaa {
        set vec to upForeVector:normalized - tan(maxaoaa) * errorvecValue:normalized.
    }
    return vec.
}

function getsteeringlanding3 {
    parameter upForeVector.
    parameter shipVelocitySurface.
    parameter maxaoaa.
    local vec is upForeVector * 70 - vxcl(ship:up:forevector, shipVelocitySurface).
    if vAng(vec, upForeVector) > maxaoaa {
        set vec to upForeVector:normalized - tan(maxaoaa) * vxcl(ship:up:forevector, shipVelocitySurface):normalized.
    }
    return vec.
}

function getsteeringgliding {
    parameter maxaoaa.
    parameter errorvecValue.
    parameter shipVelocitySurface.
    parameter mult.
    local vec is -shipVelocitySurface + mult * errorvecValue.
    if vAng(vec, -shipVelocitySurface) > maxaoaa {
        set vec to -shipVelocitySurface:normalized + tan(maxaoaa) * errorvecValue:normalized.
    }
    return vec.
}

function getlandingthrottle {
    parameter desiredacc.
    parameter maxacc.
    return desiredacc / maxacc.
}

function compheading {
    parameter geo1.
    parameter geo2.
    return arcTan2(geo1:lng - geo2:lng, geo1:lat - geo2:lat).
}

function landingburnalt {
    parameter maxacc.
    parameter shipVelocityMag.
    local landingDisplacement is abs((0^2 - shipVelocityMag^2) / (2 * maxacc)).
    return (100 + landingDisplacement) * 1.
}

function horiznontalacc {
    parameter maxacc.
    return maxacc * sin(vAng(-up:forevector, -ship:velocity:surface)).
}

function landingtime {
    parameter landingburnaltValue.
    parameter agloffsett.
    parameter shipVelocityMag.
    return (landingburnaltValue - agloffsett) / ((shipVelocityMag) / 2).
}

function overshootpos {
    parameter landingtimeValue.
    parameter horiznontalaccValue.
    parameter shipGeoPosition.
    parameter landingposs.
    local dist is geodist(shipGeoPosition, landingposs).
    local ovrshtmultiplier is (landingtimeValue * horiznontalaccValue * 1) / dist.
    local x is (ovrshtmultiplier * (landingposs:lat - shipGeoPosition:lat)) + landingposs:lat.
    local y is (ovrshtmultiplier * (landingposs:lng - shipGeoPosition:lng)) + landingposs:lng.
    return latlng(x, y).
}

//////////////////////////////////////////////////////////////////////////////////////////////

print "Checking if Trajectories mod is installed...(Version Alpha)".
wait 1.
if addons:tr:available {
    print "Trajectories mod is installed, program is allowed to proceed.".
} else {
    print "Trajectories mod is not installed, rebooting...".
    wait 1.
    reboot.
}

print "Program is overriding all guidance systems of booster from this point onwards...".
print "DO NOT TURN ON SAS!!!".

unlock all.
sas off.
rcs off.
gear off.
brakes off.
set steeringManager:rollts to 4 * steeringManager:rollts.
set steeringManager:pitchts to 0.4 * steeringManager:pitchts.
set steeringManager:yawts to 0.4 * steeringManager:yawts.
rcs on.
lock throttle to 0.
lock steering to ship:facing:forevector.
set navMode to "SURFACE".

wait 1.

set landingpos to latlng(-0.0972043516185744, -74.5576786324102). // Target geoposition.
set targpos to landingpos.
addons:tr:settarget(landingpos).
lock impactpos to addons:tr:impactpos.
clearscreen.

print "Target coordinates recorded, target has been set on Trajectories mod".
wait 0.5.
print "Target selected, initialization complete, stand by for landing program activation...".
wait 0.5.

/////////////////////////////////////////////// Initialization complete!

/////////////////////////////////////////////// BOOSTBACK
set steeringManager:maxstoppingtime to 20.
lock steering to heading(compheading(targpos, impactpos), 0).
lock maxacc to ship:maxthrust/ship:mass + 0.0001.
set navMode to "SURFACE".

toggle AG1.

until vAng(heading(compheading(targpos, impactpos), 0):forevector, ship:facing:forevector) < 30 {
    print "Executing flip maneuver for boostback/correction burn".
    print "Current guidance error in degrees: " + round(vAng(heading(compheading(targpos, impactpos), 0):forevector, ship:facing:forevector)).
    wait 0.1.
    clearScreen.
}

set steeringManager:maxstoppingtime to 6.
lock throttle to 1.

until errorvec(impactpos, targpos):mag < 300 {
    print "Trajectory error: " + round(errorvec(impactpos, targpos):mag).
    wait 0.01.
    clearScreen.
}

lock throttle to 0.
print "Trajectory error (pre-completion): " + round(errorvec(impactpos, targpos):mag).
print "Boostback complete".

LIST ENGINES IN myVariable.
FOR eng IN myVariable {
    if eng:name:contains("SEP.23.BOOSTER.INTEGRATED") {
        print("Activating backup engine.").
        eng:activate().
        break.
    }
}.

print "Max Acc:   " + maxacc.

/////////////////////////////////////////////// COAST TO ENTRY BURN
clearscreen.
print "Coasting to entry burn altitude. Stand by...".
set steeringManager:maxstoppingtime to 1.
set maxaoa to 5.
lock steering to ship:velocity:surface * -1.
lock desiredacc to ship:verticalspeed^2/(2*(alt:radar-agloffset)) + constant:g0.
brakes on.

until maxacc > 41 {
    print maxacc.
    wait 0.1.
    clearScreen.
}

LIST ENGINES IN myVariable.
FOR eng IN myVariable {
    if eng:name:contains("SEP.23.BOOSTER.INTEGRATED") {
        print("Activating backup engine.").
        eng:shutdown().
        break.
    }
}.

until alt:radar < 60000{//getentryburnstartalt(entryburnendalt, entrydisplacement(entryburnendspeed, ship:velocity:SURFACE:mag, maxacc)) {
    print "Coasting to entry burn altitude. Stand by...".
    print "Entry burn altitude is: " + round(getentryburnstartalt(entryburnendalt, entrydisplacement(entryburnendspeed, ship:velocity:SURFACE:mag, maxacc))).
    print "Guidance AoA for 'getsteeringgliding': " + round(vAng(ship:velocity:surface * -1, getsteeringgliding(maxaoa, errorvec(impactpos, targpos), ship:velocity:surface, 3))).
    print "Error: " + round(errorvec(impactpos, targpos):mag).
    wait 0.5.
    clearScreen.
}

/////////////////////////////////////////////// ENTRY BURN
set top_facing to ship:north:rightvector.

/////////////////////////////////////////////// ATMOSPHERIC GLIDING
set steeringManager:maxstoppingtime to 0.7.
set maxaoa to 40.
lock errorfactor to 3.
lock steering to lookDirUp(getsteeringgliding(maxaoa, errorvec(impactpos, targpos), ship:velocity:surface, errorfactor), top_facing).

when alt:radar < 20000 then {
    rcs off.
    lock errorfactor to max(5, 5 * (20000 - alt:radar) / (20000 - 8000)).
}

when alt:radar < 8000 then {
    rcs off.
    lock errorfactor to max(14, 14 * (8000 - alt:radar) / (8000 - 4000)).
}

until alt:radar < landingburnalt(maxacc, ship:velocity:surface:mag) {
    print "Landing burn altitude: " + round(landingburnalt(maxacc, ship:velocity:surface:mag)).
    print "Error: " + round(errorvec(impactpos, targpos):mag).
    wait 0.1.
    clearScreen.
}

/////////////////////////////////////////////// LANDING BURN
set maxaoa to 10.
set steeringManager:maxstoppingtime to 1.
lock steering to lookDirUp(ship:velocity:surface * -1, top_facing).
lock throttle to 0.33.

wait until vAng(ship:facing:forevector, ship:velocity:surface * -1) < 5.

lock desiredacc to ship:verticalspeed^2 / (2 * (alt:radar - agloffset)) + constant:g0.
lock throttle to getlandingthrottle(desiredacc, maxacc) + 0.5 * sin(vAng(up:forevector, facing:forevector)).
rcs off.

when alt:radar < geardeployheight then {
    gear on.
}

when ship:velocity:surface:mag < 400 then {
    set targpos to landingpos.
    addons:tr:settarget(landingpos).
    lock steering to lookDirUp(getsteeringlanding(maxaoa, errorvec(impactpos, targpos), ship:velocity:surface), top_facing).
}

when ship:velocity:surface:mag < 300 then {
    set maxaoa to 20.
}

when errorvec(impactpos, targpos):mag < 30 then {
    //set steeringManager:maxstoppingtime to 0.7.
    set maxaoa to 12.
}

until ship:verticalspeed > -30 {
    print "Landing".
    print "Error: " + round(errorvec(impactpos, targpos):mag).
    print "Throttle input: " + getlandingthrottle(desiredacc, maxacc).
    wait 0.1.
    clearScreen.
}

set TowerConnection to vessel("Starship Test Base"):connection.
set final_steering to 0.

when alt:radar < 55 then {
    if TowerConnection:isconnected {
        TowerConnection:sendmessage("close").
    } else {
        set final_steering to 1.
    }   
}

set last_height to alt:radar.
lock vspeed to 30 - 30 * (last_height - alt:radar) / (last_height - 41).
lock throttle to landingspeed(vspeed, maxacc, ship:verticalSpeed).
lock steering to lookDirUp(getsteeringlanding2(up:forevector, maxaoa, errorvec(impactpos, targpos)), top_facing).

when landingspeed(vspeed, maxacc, ship:verticalSpeed) < 0.33 and abs(ship:verticalSpeed + vspeed) < 5 and (last_height - alt:radar) / (last_height - 41) > 0.1 then {
    toggle AG1.
}

until alt:radar < 43 {
    print "Error: " + round(errorvec(impactpos, targpos):mag).
    wait 0.1.
    clearScreen.
}

unlock vspeed.
set last_height to alt:radar.
lock vspeed to 1 - 1 * (last_height - alt:radar) / (last_height - 39).
set last_error to round(errorvec(impactpos, targpos):mag).

if final_steering = 0 {
    lock steering to lookDirUp(getsteeringlanding3(up:forevector, ship:velocity:surface, maxaoa), ship:facing:topvector).
} else {
    lock steering to lookDirUp(up:forevector * 70 + vxcl(ship:up:forevector, ship:velocity:surface), ship:facing:topvector).
}

until ship:verticalspeed > -0.1 {
    print "Error: " + last_error.
    wait 0.1.
    clearScreen.
}

set final_displacement to vec_to_target(landingpos):mag.

lock throttle to 0.
unlock steering.
main_engine:SHUTDOWN(). // Tag of the main engine
print("Main Engines have been shut down.").

wait 3.

LIST ENGINES IN myVariable.
FOR eng IN myVariable {
    if eng:name:contains("SEP.23.BOOSTER.INTEGRATED") {
        print("Activating backup engine.").
        eng:activate().
        break.
    }
}.

print("Final error is: " + final_displacement).
print("End of script. Disengaging in 5 seconds").

wait 5.

lock throttle to 0.
unlock all.
rcs off.
print("Disengaged.").
