//Author: sushiboi
//this is a boot file to run the hop program HOP.ks.

until hastarget and alt:radar > 1000{
    print "select target for landing...".
    print "time to the apoapsis:" + round(eta:apoapsis).
    print "no target selected".
    wait 0.001.
    clearscreen.
}


switch to 0.
run SOL_Guidance.ks.
