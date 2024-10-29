//Author: sushiboi
//main.ks is a boot file that will run this program on start
//designed for booster propulsive landing on !KERBIN! only
//all heights are in meters unless stated otherwise
//all speed, velocities and acceleration are in meters per second (squared) unless stated otherwise

///////////////////////////////////////////////initialization....
set agloffset to 70.
set entryburnendalt to 40000. 
set entryburnendspeed to 600.
set maxaoa to 30.
set geardeployheight to 90.
set targpos to 0.
set landingpos to 0.
set main_engine to SHIP:PARTSNAMED("SEP.23.BOOSTER.CLUSTER")[0].
lock maxacc to ship:maxthrust/ship:mass.
lock desiredacc to ship:verticalspeed^2/(2*(alt:radar-agloffset)) + constant:g0.

/////////////////////////////////FUNCTIONS AND CUSTOM EXPRESSIONS////////////////////////////////////////////

function geodist {
    parameter pos1.
    parameter pos2.
    return (pos1:position - pos2:position):mag. 
}


function errorvec {
    local v1 to impactpos:position-targpos:position.
    local v2 to VECTOREXCLUDE(ship:up:forevector, v1).
    return(v2).
}


function vec_to_target {
    local v1 to targpos:position-ship:position. 
    local v2 to VECTOREXCLUDE(ship:up:forevector, v1).
    return(v2).    
}

function landingspeed {
    parameter speed.
    return(((constant:g0)-(speed + ship:verticalSpeed))/maxacc).
}

function entrydisplacement {
    return (abs((entryburnendspeed^2 - ship:velocity:SURFACE:mag^2)/(2*maxacc))).
}

function getentryburnstartalt {
    return entryburnendalt + entrydisplacement.
}

function getsteeringlanding {
    local vec is -ship:velocity:surface - errorvec.
    if vAng(vec, -ship:velocity:surface) > maxaoa {
        set vec to -ship:velocity:surface:normalized - tan(maxaoa)*errorvec:normalized.
    }
    return vec.
}

function getsteeringlanding2 {
    local vec is up:forevector*100 - errorvec.
    if vAng(vec, up:forevector) > maxaoa {
        set vec to up:forevector:normalized - tan(maxaoa)*errorvec:normalized.
    }
    return vec.
}

function getsteeringlanding3 {
    local vec is up:forevector*70 - vxcl(ship:up:forevector, ship:velocity:surface).
    if vAng(vec, up:forevector) > maxaoa {
        set vec to up:forevector:normalized - tan(maxaoa)*vxcl(ship:up:forevector, ship:velocity:surface):normalized.
    }
    return vec.
}

function getsteeringgliding {
    local vec is -ship:velocity:surface + 3*errorvec.
    if vAng(vec, -ship:velocity:surface) > maxaoa {
        set vec to -ship:velocity:surface:normalized + tan(maxaoa)*errorvec:normalized.
    }
    return vec.
}

function getlandingthrottle {
    return ((desiredacc/maxacc)).
}

function compheading {
    parameter geo1.
    parameter geo2.
    return arcTan2(geo1:lng - geo2:lng, geo1:lat - geo2:lat).
}

function landingburnalt {
    //return (ship:verticalSpeed^2)/(2*(maxacc-constant:g0)) + (agloffset - ship:verticalSpeed)*1.
    local landingDisplacement is abs((0^2 - ship:velocity:SURFACE:mag^2)/(2*maxacc)).
    return (1000 + landingDisplacement)*1.
}

function horiznontalacc {
    //return maxacc*sin(arcTan(geodist(ship:geoposition, landingpos)/(alt:radar - agloffset))).
    return maxacc*sin(vAng(-up:forevector, -ship:velocity:surface)).
}

function landingtime {
    return (landingburnalt - agloffset)/((ship:velocity:surface:mag)/2).
}

function overshootpos {
    //local horoffset is horiznontalacc * landingtime.
    local dist is geodist(ship:geoPosition, landingpos).
    local ovrshtmultiplier is (landingtime*horiznontalacc*1)/dist.
    local x is (ovrshtmultiplier * (landingpos:lat - ship:geoPosition:lat)) + landingpos:lat.
    local y is (ovrshtmultiplier * (landingpos:lng - ship:geoPosition:lng)) + landingpos:lng.
    return latlng(x, y).
    
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

print "checking if trajectories mod is installed...(Version Alpha)".
wait 1.
if addons:tr:available {
    print "tracjectories mod is installed, program is allowed to proceed.".
}
else {
    print "trajectories mod is not installed, rebooting...". 
    wait 1.
    reboot.
}

print "program is overiding all guidance systems of booster from this point onwards...".
print "DO NOT TURN ON SAS!!!".

unlock all.
sas off.
rcs off.
gear off.
brakes off.
set steeringManager:rollts to 4*steeringManager:rollts.
set steeringManager:pitchts to 0.4*steeringManager:pitchts.
set steeringManager:yawts to 0.4*steeringManager:yawts.
rcs on.
lock throttle to 0.
lock steering to ship:facing:forevector.
set navMode to "SURFACE".

wait 1.

// until hastarget {
//     print "select target for landing...".
//     print "time to apoapsis:" + round(eta:apoapsis).
//     print "no target selected".
//     wait 0.001.
//     clearscreen.
// }
set landingpos to latlng(-0.0972043516185744, -74.5576786324102). //target:geoposition.
set targpos to landingpos.
addons:tr:settarget(landingpos).
lock impactpos to addons:tr:impactpos.
clearscreen.

print "target coordinates recorded, target has been set on TRAJECTORIES mod".
wait 0.5.
print "target selected, initialization complete, stand-by for landing program activation...".
wait 0.5.

///////////////////////////////////////////////initialization complete!

///////////////////////////////////////////////BOOSTBACK
set steeringManager:maxstoppingtime to 20.
lock steering to heading(compheading(targpos,impactpos),0).
set navMode to "SURFACE".

// set ervec to vecdraw(ship:position, vxcl(up:forevector, errorvec):normalized, black, "errorVector", 50, true, 0.01, true, true).
// set ervec:startupdater to {return ship:position.}.
// set ervec:vecupdater to {return vxcl(up:forevector, errorvec):normalized*2.}.

toggle AG1.

until vAng(heading(compheading(targpos,impactpos),0):forevector,ship:facing:forevector) < 30 {
    print "executing flip manueaver for boostback/correction burn".
    print "current guidance error in degrees:" + round(vAng(heading(compheading(targpos,impactpos),0):forevector,ship:facing:forevector)).
    wait 0.1.
    clearScreen.
}

set steeringManager:maxstoppingtime to 6.
lock throttle to 1.

// when vAng(heading(compheading(targpos,impactpos),0):forevector,ship:facing:forevector) < 10 then {
//     lock throttle to 1.
// }

until errorvec:mag < 300 {
    print "trajectory error " + round(errorvec:mag).
    //wait 0.01.
    clearScreen.
}
// wait until errorvec:mag < 30000.
// print("Zone 3").
// wait until errorvec:mag < 3000.
// print("Zone 2").
// wait until errorvec:mag < 300.
// print("Zone 1").
// wait until errorvec:mag < 150.
// print("Zone 0").

lock throttle to 0.
print "trajectory error (pre completion)" + round(errorvec:mag).
print "boostback complete".

///////////////////////////////////////////////COAST TO ENTRY BURN
clearscreen.
lock maxacc to ship:maxthrust/ship:mass.
lock desiredacc to ship:verticalspeed^2/(2*(alt:radar-agloffset)) + constant:g0.
print "coasting to entry burn altitude. stand-by...".
set steeringManager:maxstoppingtime to 1.
set maxaoa to 5.
lock steering to ship:velocity:surface * -1.//up:forevector.
// when ship:verticalspeed < -1 then {
//     lock steering to ship:velocity:surface * -1.
//     set steeringManager:maxstoppingtime to 2.
// }
brakes on.
until alt:radar < getentryburnstartalt {
    print "coasting to entry burn altitude. stand-by...".
    print "entryburn altitude is:" + round(getentryburnstartalt).
    print "guidance AoA for 'getsteeringgliding': " + round(vAng(ship:velocity:surface * -1, getsteeringgliding)).
    print "error: " + round(errorvec:mag).
    wait 0.5.
    clearScreen.
}
///////////////////////////////////////////////ENTRY BURN
// set steeringManager:maxstoppingtime to 0.05.
// if alt:radar < getentryburnstartalt {
//     lock throttle to 1.
// }
// //lock targpos to overshootpos.
// set maxaoa to 30.
// set navMode to "SURFACE".
set top_facing to ship:north:rightvector. //vec_to_target().
// lock steering to lookDirUp(getsteeringlanding, top_facing).
// until ship:velocity:surface:mag < entryburnendspeed {
//     print "entryburn in progress".
//     print "guidance AoA for 'getsteeringgliding': " + round(vAng(ship:velocity:surface * -1, getsteeringgliding)).
//     print "error: " + round(errorvec:mag).
//     wait 0.1.
//     //addons:tr:settarget(overshootpos). 
//     clearScreen.
// }
// lock throttle to 0.

///////////////////////////////////////////////ATMOPHERIC GLIDING
set steeringManager:maxstoppingtime to 0.7.
set maxaoa to 40.
//lock targpos to overshootpos.

lock steering to lookDirUp(getsteeringgliding, top_facing).

//addons:tr:settarget(overshootpos).

when alt:radar < 25000 then {
    rcs off.
}
when errorvec:mag < 100 then {
    set maxaoa to 15.
}
// when errorvec:mag < 10 then {
//     set maxaoa to 10.
// }
until alt:radar < landingburnalt {
    print "landing burn altitude: " + round(landingburnalt).
    Print "error: " + round(errorvec:mag).
    wait 0.1.
    //addons:tr:settarget(overshootpos).
    clearScreen. 
}

///////////////////////////////////////////////LANDING BURN
set vspeed to 15.
set maxaoa to 10.
set steeringManager:maxstoppingtime to 1.
lock steering to lookDirUp(ship:velocity:surface * -1, top_facing).
lock throttle to 0.3.

wait until vAng(ship:facing:forevector, ship:velocity:surface * -1) < 5.

lock throttle to getlandingthrottle + 0.5*sin(vAng(up:forevector, facing:forevector)).
rcs off.

//lock steering to lookDirUp(getsteeringlanding, ship:facing:topvector).

when alt:radar < geardeployheight then {
    gear on.
}
when ship:velocity:surface:mag < 400 then {
    unlock targpos.
    lock targpos to landingpos.
    addons:tr:settarget(landingpos).
    lock steering to lookDirUp(getsteeringlanding, top_facing).
}
// when alt:radar < 120 then {
//     set vspeed to 3.
// }

when ship:velocity:surface:mag < 100 then {
    set steeringManager:maxstoppingtime to 0.6.
    set maxaoa to 12.
}
until ship:verticalspeed > -30 {
    print "landing".
    Print "error: " + round(errorvec:mag).
    print "throttle input: " + getlandingthrottle.
    wait 0.1.
    clearScreen.
}

set last_height to alt:radar.
lock vspeed to 30 - 30*(last_height-alt:radar)/(last_height-42).
lock throttle to landingspeed(vspeed).
lock steering to lookDirUp(getsteeringlanding2, top_facing).

when landingspeed(vspeed) < 0.33 and abs(ship:verticalSpeed - (-vspeed)) < 5 and (last_height-alt:radar)/(last_height-40) > 0.1 then {
    toggle AG1.
}

set TowerConnection to vessel("Starship Test Base"):connection.
set final_steering to 0.

until alt:radar < 43 {
    print "error: " + round(errorvec:mag).
    wait 0.1.
    clearScreen.
}

if TowerConnection:isconnected {
    TowerConnection:sendmessage("close").
} else {
    set final_steering to 1.
}

unlock vspeed.
lock vspeed to 0.3.
set last_error to round(errorvec:mag).

if final_steering = 0 {
    lock steering to lookDirUp(getsteeringlanding3, ship:facing:topvector).
} else {
    lock steering to lookDirUp(up:forevector*70 + vxcl(ship:up:forevector, ship:velocity:surface), ship:facing:topvector).
}

until ship:verticalspeed > -0.1 {
    print "error: " + last_error.
    wait 0.1.
    clearScreen.
}

set final_displacement to vec_to_target():mag.

lock throttle to 0.
unlock steering.
main_engine:SHUTDOWN(). //tag of the main engine
print("Main Engines Have Been Shut Down.").

wait 3.

LIST ENGINES IN myVariable.
FOR eng IN myVariable {
    //print "An engine exists with ISP = " + eng:name.
	if eng:name:contains("SEP.23.BOOSTER.INTEGRATED") //SEP.23.BOOSTER.INTEGRATED (Starship Test Ship)
        print("true").
        eng:activate().
        break.
}.

print("Final Error is: " + final_displacement).
print("End of script. Disengaging in 5 seconds").

wait 5.

lock throttle to 0.
unlock all.
rcs off.
print("Disengaged.").