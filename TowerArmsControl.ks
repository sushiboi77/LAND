global commandRecieved is false.

until commandRecieved {
    if not ship:messages:empty {
        print("Message Recieved at: " + missionTime).
        // wait 1.
        // clearScreen.
        local dataPacket is ship:MESSAGES:POP.  //stores the whole data packet in a variable
        local decodedMessage is dataPacket:CONTENT. //stores the message contents in decodedMessage
        //print decodedMessage.
        if decodedMessage = "CLOSE" {
            toggle ag2.
            set commandRecieved to true.
        } else {
            clearScreen.
            print "invalid message".
            wait 3.
        }
    } else {
        print("waiting for messages: " + ship:messages).
        print(missionTime).
        wait 0.01.
        clearScreen. 
    }
}
