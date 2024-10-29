//Author: sushiboi
//test.ks is a boot file that will run this program on start
//designed for booster propulsive landing on !KERBIN! only
//all heights are in meters unless stated otherwise
//all speed, velocities and acceleration are in meters per second (squared) unless stated otherwise

///////////////////////////////////////////////initialization....
set agloffset to 60.
set entryburnendalt to 35000. 
set entryburnendspeed to 500.
set maxaoa to 30.
set geardeployheight to 90.
set targpos to 0.
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
    local aoacorrect to 1/tan(maxaoa).
    local vec to ((ship:velocity:surface * -1)/(ship:velocity:surface:mag))*(errorvec:mag * aoacorrect) - errorvec.
    if vAng(-1 * ship:velocity:surface, errorvec - -1 * ship:velocity:surface) > maxaoa {
        return vec.
    }
    else {
        return errorvec - -1 * ship:velocity:surface.
    }
}

function getsteeringgliding {
    local aoacorrect to 1/tan(maxaoa).
    local vec to ((ship:velocity:surface * -1)/(ship:velocity:surface:mag))*(errorvec:mag * aoacorrect) + errorvec.
    if vAng(-1 * ship:velocity:surface, errorvec + -1 * ship:velocity:surface) > maxaoa {
        return vec.
    }
    else {
        return errorvec + -1 * ship:velocity:surface.
    }
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
    return (ship:verticalSpeed^2)/(2*(maxacc-constant:g0)) + (agloffset - ship:verticalSpeed).
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

lock targpos to target:geoposition.
addons:tr:settarget(targpos).
lock impactpos to addons:tr:impactpos.
clearscreen.

print "target coordinates recorded, target has been set on TRAJECTORIES mod".
wait 0.5.
print "target selected, initialization complete, stand-by for landing program activation...".
wait 0.5.

///////////////////////////////////////////////initialization complete!

///////////////////////////////////////////////BOOSTBACK
set steeringManager:maxstoppingtime to 1.
lock steering to heading(compheading(targpos,impactpos),0).
set navMode to "SURFACE".
until vAng(heading(compheading(targpos,impactpos),0):forevector,ship:facing:forevector) < 10 {
    print "executing flip manueaver for boostback/correction burn".
    print "current guidance error in degrees:" + round(vAng(heading(compheading(targpos,impactpos),0):forevector,ship:facing:forevector)).
    wait 0.1.
    clearScreen.
}

lock throttle to 1.
wait 0.01.

until errorvec:mag < 500 {
    print "trajectory error " + round(errorvec:mag).
    clearScreen.
}

lock throttle to 0.
print "trajectory error " + round(errorvec:mag).
print "boostback complete".
wait 2.
///////////////////////////////////////////////COAST TO ATMOSPHERE
clearscreen.
lock maxacc to ship:maxthrust/ship:mass.
lock desiredacc to ship:verticalspeed^2/(2*(alt:radar-agloffset)) + constant:g0.
print "coasting to entry burn altitude. stand-by...".
set steeringManager:maxstoppingtime to 0.5.
set maxaoa to 7.
lock steering to up:forevector.
when ship:verticalspeed < -100 then {
    lock steering to getsteeringgliding.
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
set steeringManager:maxstoppingtime to 1.
lock throttle to 1.
set maxaoa to 10.
lock steering to getsteeringlanding.
until ship:velocity:surface:mag < entryburnendspeed {
    print "entryburn in progress".
    print "guidance AoA for 'getsteeringgliding': " + round(vAng(ship:velocity:surface * -1, getsteeringgliding)).
    print "error: " + round(errorvec:mag).
    wait 0.05.
    clearScreen.
}
lock throttle to 0.

///////////////////////////////////////////////ATMOPHERIC GLIDING
set maxaoa to 30.
when errorvec:mag < 50 then {
    set maxaoa to 5.
}
lock steering to getsteeringgliding.
when alt:radar < 18000 then {
    rcs off.
}
until alt:radar < landingburnalt {
    clearScreen.
    print "landing burn altitude: " + round(landingburnalt).
    print "error: " + round(errorvec:mag).
}

///////////////////////////////////////////////LANDING BURN
set maxaoa to 10.
set steeringManager:maxstoppingtime to 2.
lock throttle to getlandingthrottle.
lock steering to lookDirUp(getsteeringlanding, ship:facing:topvector).
rcs on.
when alt:radar < geardeployheight then {
    gear on.
}
until ship:verticalspeed > -30 {
    clearScreen.
    print "landing".
    Print "error: " + round(errorvec:mag).
    print "throttle input: " + round(getlandingthrottle).
}

lock throttle to landingspeed(2).
lock steering to lookDirUp(heading((90-ship:groundspeed*1), compheading(ship:geoposition, impactpos)):forevector, ship:facing:topvector).

until ship:verticalspeed > -0.5 {
    print "error: " + round(errorvec:mag).
    clearScreen.
}

lock throttle to 0.
unlock all.
rcs off.