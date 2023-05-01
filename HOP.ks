//Author: sushiboi
//test1.ks is a boot file that will run the program on start up.
//designed for booster propulsive landing on !KERBIN! only
set TWR to 1.2.
set countdown to 3.
set hoveralt to 2300.
lock impactpos to addons:tr:impactpos.
lock maxacc to ship:maxthrust/ship:mass.

print "checking if trajectories mod is installed...".
if addons:tr:available {
    print "tracjectories mod is installed, program is allowed to proceed.".
}
else {
    print "trajectories mod is not installed, no go for launch, rebooting...". 
    reboot.
}

/////////////////////////////////////////////////////functions/////////////////////////////////////////////
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


function landingspeed{
    parameter speed.
    return(((constant:g0)-(speed + ship:verticalSpeed))/maxacc).
}
////////////////////////////////////////////////////////////////////////////////////////////////////////

rcs on.
until hasTarget = true { hudtext("target landing pad to continue", 1, 2, 20, green, false). }.
until rcs = true { hudtext("activate RCS to initiate launch countdown", 1, 2, 20, green, false). }.
until countdown = 0 { hudtext("T-" + countdown, 1, 2, 20, red, false). 
set countdown to countdown - 1.
wait 1. }

lock targdir to target:heading.
lock targpos to target:geoposition.
addons:tr:settarget(targpos).

stage.
rcs off.
set navMode to "SURFACE".
lock throttcont to (constant:g0*ship:mass*twr)/ship:maxthrust.
lock steering to heading(0,90).
lock throttle to throttcont.
lock throttle to throttcont.
lock steering to heading(0,90).
when ship:verticalspeed > 50  then { 
    set TWR to 1.
}
until ship:apoapsis > hoveralt {
    print "apogee:" + round(ship:apoapsis) + "m".
    wait 0.
    clearScreen.
}
lock throttle to 0.

until ship:verticalspeed < 0 {
 print "coasting to apoapsis of " + round(ship:apoapsis) + "m".
 print "target heading:" + round(targdir).
 print "target position:" + targpos.
 print "horizontal distance from target: " + round(geodist(ship:geoposition, targpos)).
 wait 0.
 clearScreen.
}

set TWR to 0.9.
lock steervec to up:forevector*(errorvec:mag * 6) - errorvec.
lock throttle to throttcont.
lock steering to lookDirUp((steervec),ship:up:forevector).

until geodist(impactpos, targpos) < 10 {
    print "error to target:" + round(geodist(impactpos, targpos)).
    print "throttle input:" + throttcont.
    print round(errorvec:mag).
    //vecDraw(v(0,0,0),errorvec,red,"",1,true,0.05,true,false).
    //vecDraw(v(0,0,0),steervec,green,"",1,true,0.05,true,false).
    wait 0.
    clearScreen.
}.

lock steervec to up:forevector*(errorvec:mag * 30) - errorvec.
lock throttcont to landingspeed(30).
lock throttle to throttcont.
lock steering to lookDirUp((steervec),ship:up:forevector).

until (ship:position:z - target:position:z) < 90 {
    print "error to target:" + round(geodist(impactpos, targpos)).
    print "throttle input:" + round(throttcont).
    print round(errorvec:mag).
    //vecDraw(v(0,0,0),steervec,green,"",1,true,0.05,true,false).
    wait 0.
    clearScreen.
}

lock steervec to up:forevector*(errorvec:mag * 50) - errorvec.
lock throttcont to landingspeed(1.5).
lock throttle to throttcont.
lock steering to lookDirUp((steervec),ship:up:forevector).
gear on.

until ship:verticalspeed > -0.5. {
    print "error to target:" + round(geodist(impactpos, targpos)).
    print "throttle input:" + throttcont.
    print round(errorvec:mag).
    //vecDraw(v(0,0,0),errorvec,red,"",1,true,0.05,true,false).
    //vecDraw(v(0,0,0),steervec,green,"",1,true,0.05,true,false).
    wait 0.
    clearScreen.
}

lock throttle to 0.
lock steering to up.