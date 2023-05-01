//Author: sushiboi
//main.ks is a boot file that will run this program on start
//designed for booster propulsive landing on !KERBIN! only
//all heights are in meters unless stated otherwise
//all speed, velocities and acceleration are in meters per second (squared) unless stated otherwise

///////////////////////////////////////////////initialization....
set agloffset to 50.
set entryburnendalt to 40000. 
set entryburnendspeed to 600.
set maxaoa to 30.
set geardeployheight to 90.
set targpos to 0.
set landingpos to 0.
lock maxacc to ship:maxthrust/ship:mass.
lock desiredacc to ship:verticalspeed^2/(2*(alt:radar-agloffset)) + constant:g0.

/////////////////////////////////FUNCTIONS AND CUSTOM EXPRESSIONS////////////////////////////////////////////

function geodist {
    parameter pos1.
    parameter pos2.
    return (pos1:position - pos2:position):mag. 
}


function errorvec {
    local v1 to v(impactpos:position:x,impactpos:position:y,0).
    local v2 to v(targpos:position:x,targpos:position:y,0).
    return(v1 - v2).
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
    local vec is up:forevector - errorvec.
    if vAng(vec, up:forevector) > maxaoa {
        set vec to up:forevector:normalized - tan(maxaoa)*errorvec:normalized.
    }
    return vec.
}

function getsteeringgliding {
    local vec is -ship:velocity:surface + 10*errorvec.
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
    return (ship:verticalSpeed^2)/(2*(maxacc-constant:g0)) + (agloffset - ship:verticalSpeed)*1.
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

print "checking if trajectories mod is installed...".
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

until hastarget {
    print "select target for landing...".
    print "time to apoapsis:" + round(eta:apoapsis).
    print "no target selected".
    wait 0.001.
    clearscreen.
}
set landingpos to target:geoposition.
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
until vAng(heading(compheading(targpos,impactpos),0):forevector,ship:facing:forevector) < 25 {
    print "executing flip manueaver for boostback/correction burn".
    print "current guidance error in degrees:" + round(vAng(heading(compheading(targpos,impactpos),0):forevector,ship:facing:forevector)).
    wait 0.1.
    clearScreen.
}

set steeringManager:maxstoppingtime to 6.
lock throttle to 1.
wait 0.01.

until errorvec:mag < 150 {
    print "trajectory error " + round(errorvec:mag).
    clearScreen.
}

lock throttle to 0.
print "trajectory error " + round(errorvec:mag).
print "boostback complete".
wait 1.
///////////////////////////////////////////////COAST TO ENTRY BURN
clearscreen.
lock maxacc to ship:maxthrust/ship:mass.
lock desiredacc to ship:verticalspeed^2/(2*(alt:radar-agloffset)) + constant:g0.
print "coasting to entry burn altitude. stand-by...".
set steeringManager:maxstoppingtime to 5.
set maxaoa to 5.
lock steering to up:forevector.
when ship:verticalspeed < -1 then {
    lock steering to ship:velocity:surface * -1.
    set steeringManager:maxstoppingtime to 2.
}
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
set steeringManager:maxstoppingtime to 0.05.
lock throttle to 1.
lock targpos to overshootpos.
set maxaoa to 25.
set navMode to "SURFACE".
lock steering to lookDirUp(getsteeringlanding, ship:facing:topvector).
until ship:velocity:surface:mag < entryburnendspeed {
    print "entryburn in progress".
    print "guidance AoA for 'getsteeringgliding': " + round(vAng(ship:velocity:surface * -1, getsteeringgliding)).
    print "error: " + round(errorvec:mag).
    wait 0.05.
    addons:tr:settarget(overshootpos). 
    clearScreen.
}
lock throttle to 0.

///////////////////////////////////////////////ATMOPHERIC GLIDING
set steeringManager:maxstoppingtime to 1.
set maxaoa to 30.
lock targpos to overshootpos.

lock steering to getsteeringgliding.

when alt:radar < 15000 then {
    rcs off.
}
when errorvec:mag < 20 then {
    set maxaoa to 20.
}
until alt:radar < landingburnalt {
    print "landing burn altitude: " + round(landingburnalt).
    print "error: " + round(errorvec:mag).
    wait 0.
    addons:tr:settarget(overshootpos).
    clearScreen. 
}

///////////////////////////////////////////////LANDING BURN
set vspeed to 30.
set maxaoa to 20.
set steeringManager:maxstoppingtime to 1.
lock steering to lookDirUp(ship:velocity:surface * -1, ship:facing:topvector).
lock throttle to 0.3.

wait until vAng(ship:facing:forevector, ship:velocity:surface * -1) < 5.

lock throttle to getlandingthrottle + 0.5*sin(vAng(up:forevector, facing:forevector)).
rcs off.

//lock steering to lookDirUp(getsteeringlanding, ship:facing:topvector).

when alt:radar < geardeployheight then {
    gear on.
}
when ship:velocity:surface:mag < 300 then {
    unlock targpos.
    lock targpos to landingpos.
    addons:tr:settarget(landingpos).
    lock steering to lookDirUp(getsteeringlanding, ship:facing:topvector).
}
when alt:radar < 120 then {
    set vspeed to 3.
}
when ship:velocity:surface:mag < 100 then {
    set steeringManager:maxstoppingtime to 0.1.
    set maxaoa to 10.
}
until ship:verticalspeed > -30 {
    clearScreen.
    print "landing".
    Print "error: " + round(errorvec:mag).
    print "throttle input: " + round(getlandingthrottle).
}

lock throttle to landingspeed(vspeed).
lock steering to lookDirUp((up:forevector * ship:velocity:surface:mag * 10) - (ship:velocity:surface), ship:facing:topvector).



until ship:verticalspeed > -0.5 {
    print "error: " + round(errorvec:mag).
    clearScreen.
}

lock throttle to 0.
unlock all.
rcs off.