import QpixTxRxTester
def issueTrigger():
    while True:
        resp = input("press enter to send trigger? ")
        if resp == "q":
            break
        t.sendTrg()
        resp = input("trigger sent.. continue with test? q to exit ")
        if resp == "q":
            break
t = QpixTxRxTester.QpixTxRxTester()
# perform test, send 64 bits provided in arg, and check it against received word
t.doTest(0xa,0xa) # first arg - MSB 32 bits, second arg - LSB 32 bits
issueTrigger()
