//Author: sushiboi
//main.ks is a boot file that will run this program on start
//designed for booster propulsive landing on !KERBIN! only
//all heights are in meters unless stated otherwise
//all speed, velocities and acceleration are in meters per second (squared) unless stated otherwise

///////////////////////////////////////////////initialization....
set agloffset to 25.
set entryburnendalt to 40000. 
set entryburnendspeed to 600.
set maxaoa to 30.
set geardeployheight to 90.
set targpos to 0.
set landingpos to 0.
set freezePosError to 0.
lock maxacc to ship:maxthrust/ship:mass.
lock desiredacc to ship:verticalspeed^2/(2*(alt:radar-agloffset)) + constant:g0.

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

lock impactpos to addons:tr:impactpos.
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

function poserrorvec {
    local v1 to ship:position-targpos:position.
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
    local vec is up:forevector*100 - vxcl(ship:up:forevector, ship:velocity:surface).
    if vAng(vec, up:forevector) > maxaoa {
        set vec to up:forevector:normalized - tan(maxaoa)*vxcl(ship:up:forevector, ship:velocity:surface):normalized.
    }
    return vec.
}


function getsteeringgliding {
    // local vec is vCrs(ship:velocity:surface, vector1) + rotated_errorvec*error_multiple.
    // if vAng(vec, vCrs(ship:velocity:surface, vector1)) > maxaoa {
    //     set vec to vCrs(ship:velocity:surface, vector1):normalized - tan(maxaoa)*rotated_errorvec:normalized.
    // }
    local pivot is vCrs(ship:up:forevector, -freezePosError):normalized.
    local neutral is vCrs(pivot, -ship:velocity:surface).
    //local normalized_axis is -poserrorvec:normalized.
    local mirror is errorvec * cos(180) 
                + vcrs(-freezePosError:normalized, errorvec) * sin(180) 
                + -freezePosError:normalized * vdot(-freezePosError:normalized, errorvec) * (1 - cos(180)).

    local deltaAngle is vAng(neutral, -freezePosError).

    local transformed is VECTOREXCLUDE(neutral, (mirror * cos(90+deltaAngle) 
                + vcrs(-pivot, mirror) * sin(90+deltaAngle) 
                + -pivot * vdot(-pivot, mirror) * (1 - cos(90+deltaAngle)))):normalized.

    //local ErrorMitigation is PIDLOOP(0, 0, 1, 1, 3, 0.0).
    // ErrorMitigation:SETPOINT to 0.
    //local Correction is ErrorMitigation:update(time:seconds, errorvec:mag).

    local final is neutral + transformed * (errorvec:mag).

    if vAng(final, neutral) > maxaoa {
        set final to neutral:normalized + tan(maxaoa)*transformed.
    }
    
    //local mirror is vxcl(-errorvec + 0 + (-poserrorvec:normalized) * vdot(-poserrorvec:normalized, errorvec) * 2, -poserrorvec:normalized).
    return final. 
}

// function getsteeringglidingRoll {
//     local vec is vxcl(poserrorvec, vxcl(ship:up:forevector, -ship:velocity:surface - errorvec)).
//     if vAng(vec, -ship:velocity:surface) > maxaoa {
//         set vec to -ship:velocity:surface:normalized + tan(maxaoa)*errorvec:normalized.
//     }
//     return vec.
// }

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
    return (500 + landingDisplacement)*1.
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
set landingpos to target:geoposition.//latlng(-0.0972043516185744, -74.5576786324102). //target:geoposition.
set targpos to landingpos.
addons:tr:settarget(landingpos).
lock impactpos to addons:tr:impactpos.
clearscreen.

print "target coordinates recorded, target has been set on TRAJECTORIES mod".
wait 0.5.
print "target selected, initialization complete, stand-by for landing program activation...".
wait 0.5.

//engines
for pt in SHIP:parts {
    if pt:name:startswith("SEP.23.RAPTOR2.SL.RC") {
		if vdot(ship:facing:topvector, pt:position) > 0 {
			set eng1 to pt.
		} else {
			if vdot(ship:facing:starvector, pt:position) > 0 {
				set eng2 to pt.
			} else {
				set eng3 to pt.
			}
		}
	}
}
//eng1   X
//     O   O

//eng2   O
//     O   X

//eng3   O
//     X   O
// //fuel tanks

///////////////////////////////////////////////initialization complete!

///////////////////////////////////////////////Launch
rcs on.

// when ship:verticalspeed > 10 then {
// set ervec to vecdraw(ship:position, vxcl(up:forevector, errorvec):normalized, black, "errorVector", 50, true, 0.01, true, true).
// set ervec:startupdater to {return ship:position.}.
// set ervec:vecupdater to {return vxcl(up:forevector, errorvec):normalized*2.}.
// }

clearScreen.
unlock all.

set maxaoa to 10.
//set TWR to 1.6.
//set v1a to v(ship:position:x,ship:position:y,0) - v(target:position:x,target:position:y,0).


eng1:shutdown.
eng2:shutdown.
eng3:shutdown.

//lock throttle to (constant:g0*ship:mass*0.9)/ship:maxthrust.

//eng1:activate.
//wait 0.5.
// eng2:activate.
// wait 0.5.
// eng3:activate.

// lock throttle to (constant:g0*ship:mass*twr)/ship:maxthrust.
// print "Lift-Off!".

//wait until verticalSpeed > 5.
clearScreen.
unlock impactpos.
lock impactpos to addons:tr:impactpos.

set freezeOrientation to ship:velocity:surface.

lock steering to freezeOrientation.
lock throttle to 0.

// lock throttle to (constant:g0*ship:mass*twr)/ship:maxthrust.
// lock steering to lookDirUp(up:forevector + tan(10)*(ship:position-target:position):normalized, v1a).

// until orbit:apoapsis > 5000{
// print "time to apoapsis:" + round(eta:apoapsis).
// clearScreen.
// }
// eng2:shutdown.

// until orbit:apoapsis > 10000{
// print "time to apoapsis:" + round(eta:apoapsis).
// clearScreen.
// }
// eng3:shutdown.

// set twr to 0.5.

//lock steering to lookDirUp(getsteeringlanding2, ship:facing:topvector).

if errorvec:mag > 500 {
    eng1:activate.
    lock steering to heading(compheading(targpos,impactpos),0).
    lock throttle to 1.
    until errorvec:mag < 500 {
        print "trajectory error " + round(errorvec:mag).
        wait 0.05.
        clearScreen.
        }
    eng1:shutdown.

}

lock steering to freezeOrientation.
lock throttle to 0.

until ship:verticalspeed < -2 {
print "Waiting for drop in altitude".
clearScreen.
}


///////////////////////////////////////////////ATMOPHERIC GLIDING
set steeringManager:maxstoppingtime to 1.
set SteeringManager:ROLLCONTROLANGLERANGE to 30.
set maxaoa to 40.
set targpos to landingpos.
//set error_multiple to 12.
set freezePosError to poserrorvec.
set defaultPts to steeringManager:PITCHTS.
set defaultYts to steeringManager:YAWTS.
set defaultRts to steeringManager:ROLLTS.
set SteeringManager:PITCHTS to round(defaultPts/0.5).
set SteeringManager:YAWTS to round(defaultYts/0.5).
set SteeringManager:ROLLTS to round(defaultRts/7).
lock throttle to 0.
lock maxacc to ship:maxthrust/ship:mass.
lock desiredacc to ship:verticalspeed^2/(2*(alt:radar-agloffset)) + constant:g0.
lock impactpos to addons:tr:impactpos.

rcs on.
AG1 on.

eng1:shutdown.
eng2:activate.
eng3:activate.

// set draw_velocity to vecdraw(ship:position, vCrs(vCrs(ship:up:forevector, -poserrorvec):normalized, -ship:velocity:surface):normalized, red, "Error", 50, true, 0.01, true, true).
// set draw_velocity:startupdater to {return ship:position.}.
// set draw_velocity:vecupdater to {return vCrs(vCrs(ship:up:forevector, -poserrorvec):normalized, -ship:velocity:surface):normalized*2.}.

lock steering to lookDirUp(getsteeringgliding, ship:up:forevector).//-ship:velocity:surface getsteeringglidingRoll

when errorvec:mag < 250 then {
    set maxaoa to 30.
}

when errorvec:mag < 100 and alt:radar < 7000 then {
    set maxaoa to 25.
}

when errorvec:mag < 50 and alt:radar < 7000 then {
    set maxaoa to 20.
}

when alt:radar < 23000 and vAng(ship:facing:forevector, getsteeringgliding) < 5 and ship:angularvel:mag < 0.05 then {
    rcs off.
}

// when vAng(ship:facing:forevector, getsteeringgliding) < 5 and ship:angularvel:mag < 0.05 then { //angular vel is in radians
//     rcs off.
// }

until alt:radar < landingburnalt + 200 and alt:radar < 3000 {
    print "landing burn altitude: " + round(landingburnalt).
    print "error: " + round(errorvec:mag).
    wait 0.1.
    addons:tr:settarget(landingpos).
    clearScreen.
}

set freezeDirection to getsteeringgliding.

lock steering to freezeDirection.

rcs on.

until alt:radar < landingburnalt*1 and alt:radar < 3000 {
    print "landing burn altitude: " + round(landingburnalt).
    print "error: " + round(errorvec:mag).
    wait 0.1.
    addons:tr:settarget(landingpos).
    clearScreen.
}

set back_vector to poserrorvec.//ship:facing:forevector:normalized * -1. 
unlock steering.

///////////////////////////////////////////////LANDING BURN
set vspeed to 15.
set maxaoa to 30.
set steeringManager:maxstoppingtime to 2.
//lock steering to lookDirUp(ship:velocity:surface * -1, back_vector).
set SteeringManager:PITCHTS to defaultPts.
set SteeringManager:YAWTS to defaultYts.
//set SHIP:CONTROL:pitch to 0.8.
lock throttle to 0.33.

set pivotAxis to -vCrs(ship:up:forevector, vxcl(ship:up:forevector, freezeDirection)):normalized.
set Dir1 to freezeDirection * cos(45) 
        + vcrs(pivotAxis, freezeDirection) * sin(45) 
        + pivotAxis * vdot(pivotAxis, freezeDirection) * (1 - cos(45)).

// set draw_velocity to vecdraw(ship:position, Dir1:normalized, red, "Error", 50, true, 0.01, true, true).
// set draw_velocity:startupdater to {return ship:position.}.
// set draw_velocity:vecupdater to {return Dir1:normalized*2.}.

lock steering to lookDirUp(Dir1, back_vector).

eng2:shutdown.
eng3:shutdown.
eng2:activate.
wait 0.5.
eng3:activate.
wait 0.5.
eng1:activate.

wait until vAng(ship:facing:forevector, Dir1) < 25.

// set freezeYAW to facing:yaw.
// set freezeROLL to facing:roll. 

// until vAng(ship:facing:forevector, ship:velocity:surface * -1) < 15 {
//     set SHIP:CONTROL:roll to sin(facing:roll-freezeROLL).
//     set SHIP:CONTROL:yaw to sin(freezeYAW-facing:yaw).
// }

//wait until vAng(ship:facing:forevector, ship:velocity:surface * -1) < 15.

//set SHIP:CONTROL:NEUTRALIZE to True.
lock steering to lookDirUp(ship:velocity:surface * -1, back_vector).

wait until vAng(ship:facing:forevector, ship:velocity:surface * -1) < 15.

toggle AG1.

lock throttle to getlandingthrottle + 0.5*sin(vAng(up:forevector, facing:forevector)).

set steeringManager:maxstoppingtime to 1.

rcs off.

//lock steering to lookDirUp(getsteeringlanding, ship:facing:topvector).

when landingspeed(vspeed) < 0.66 or getlandingthrottle + 0.5*sin(vAng(up:forevector, facing:forevector)) < 0.66 then {
    eng1:shutdown.
}

when alt:radar < geardeployheight then {
    gear on.
}
when ship:velocity:surface:mag < 40 then {
    unlock targpos.
    lock targpos to landingpos.
    addons:tr:settarget(landingpos).
    lock steering to lookDirUp(getsteeringlanding, ship:facing:topvector).
}
when alt:radar < 70 then {
    set vspeed to 2.
}
when alt:radar < 33 then {
    set vspeed to 0.4.
}
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

lock throttle to landingspeed(vspeed).
lock steering to lookDirUp(getsteeringlanding2, ship:facing:topvector).

// until alt:radar < 38 { ////AGL height for landing pad
//     print "error: " + round(errorvec:mag).
//     wait 0.1.
//     clearScreen.
// }

until alt:radar < 30 {
    set last_error to round(errorvec:mag).
}

lock steering to lookDirUp(getsteeringlanding3, ship:facing:topvector).

until ship:verticalspeed > -0.1 {
    print "error: " + last_error.
    wait 0.01.
    clearScreen.
}

lock throttle to 0.
unlock steering.
eng1:shutdown.
eng2:shutdown.
eng3:shutdown.
print("Main Engines Have Been Shut Down.").

wait 3.

LIST ENGINES IN myVariable.
FOR eng IN myVariable {
    //print "An engine exists with ISP = " + eng:name.
	if eng:name:contains("SEP.23.SHIP.BODY")
        print(eng:name).
		eng:activate().
        //break.
}.



print("End of script. Disengaging in 5 seconds").

wait 5.

lock throttle to 0.
unlock all.
rcs off.
print("Disengaged.").