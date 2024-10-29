//Author: sushiboi
//this is a boot file to run the hop program HOP.ks.

////////////////////////////////////////////////////GET FUEL AMOUNT
// LOCAL Oamount IS 0.
// LOCAL Ocapacity IS 0.
// FOR x IN SHIP:partsdubbed("SEP.23.SHIP.BODY") {
// 	FOR res IN x:RESOURCES {
// 		IF res:NAME = "LqdMethane" {
// 			SET Oamount TO Oamount + res:AMOUNT.
// 			SET Ocapacity TO Ocapacity + res:CAPACITY.
// 		}
// 	}
// }
//set prop_amount to SHIP:PARTSNAMED("SEP.23.SHIP.BODY")[0]:RESOURCES:find("Oxidizer"):AMOUNT. //LqdMethane   PARTSTAGGED
//print(Oamount).


////////////////////////////////////////////////////VENT PROP, STARSHIP
LIST ENGINES IN myVariable.
FOR eng IN myVariable {
    //print "An engine exists with ISP = " + eng:name.
	if eng:name:contains("SEP.23.SHIP.BODY")
		global fuelVents is eng.
}.
print("Venting prop in 5 seconds For 10 seconds").
wait 5.
fuelVents:activate().
wait 10.
fuelVents:shutdown().
print("Venting ended").

////////////////////////////////////////////////////TRANSFER PROP BODY TO HEADER, STARSHIP
// global MAIN_Oamount is 0.
// global MAIN_Ocapacity is 0.
// global MAIN_CH4amount is 0.
// global MAIN_CH4capacity is 0.
// global HEADER_Oamount is 0.
// global HEADER_Ocapacity is 0.
// global HEADER_CH4amount is 0.
// global HEADER_CH4capacity is 0.

// FOR x IN SHIP:partsdubbed("SEP.23.SHIP.BODY") {
// 	FOR res IN x:RESOURCES {
// 		IF res:NAME = "LqdMethane" {
// 			SET MAIN_CH4amount TO MAIN_CH4amount + res:AMOUNT.
// 			SET MAIN_CH4capacity TO MAIN_CH4capacity + res:CAPACITY.
// 		}
// 		IF res:NAME = "Oxidizer" {
// 			SET MAIN_Oamount TO MAIN_Oamount + res:AMOUNT.
// 			SET MAIN_Ocapacity TO MAIN_Ocapacity + res:CAPACITY.
// 		}
// 	}
// }

// FOR x IN SHIP:partsdubbed("SEP.23.SHIP.HEADER") {
// 	FOR res IN x:RESOURCES {
// 		IF res:NAME = "LqdMethane" {
// 			SET HEADER_CH4amount TO HEADER_CH4amount + res:AMOUNT.
// 			SET HEADER_CH4capacity TO HEADER_CH4capacity + res:CAPACITY.
// 		}
// 		IF res:NAME = "Oxidizer" {
// 			SET HEADER_Oamount TO HEADER_Oamount + res:AMOUNT.
// 			SET HEADER_Ocapacity TO HEADER_Ocapacity + res:CAPACITY.
// 		}
// 	}
// }

// set TRANSFER_MainTank_TO_HeaderTank_O2 TO TRANSFERALL("OXIDIZER", SHIP:partsdubbed("SEP.23.SHIP.BODY"), SHIP:partsdubbed("SEP.23.SHIP.HEADER")).
// set TRANSFER_MainTank_TO_HeaderTank_CH4 TO TRANSFERALL("LqdMethane", SHIP:partsdubbed("SEP.23.SHIP.BODY"), SHIP:partsdubbed("SEP.23.SHIP.HEADER")).

// SET TRANSFER_MainTank_TO_HeaderTank_O2:ACTIVE to TRUE.
// SET TRANSFER_MainTank_TO_HeaderTank_CH4:ACTIVE to TRUE.

// until HEADER_CH4amount = HEADER_CH4capacity {
// 	print("LOX TRANSFER STATUS: " + TRANSFER_MainTank_TO_HeaderTank_O2:status).
// 	print("LF TRANSFER STATUS: " + TRANSFER_MainTank_TO_HeaderTank_CH4:status).
// 	WAIT 0.01.
// 	clearScreen.
// }

// SET TRANSFER_MainTank_TO_HeaderTank_O2:ACTIVE to false.
// SET TRANSFER_MainTank_TO_HeaderTank_CH4:ACTIVE to false.
