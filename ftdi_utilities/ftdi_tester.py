#!/usr/bin/python
import os
import sys
import serial
import re


def UARTBlast(SerialDevice):

    SerialPort = serial.Serial(port = SerialDevice, baudrate = 300)
    for i in range(60):
        SerialPort.write("M")



#   
# Main Program is Here
#
def main():

    print "Building ttyUSB list..."
    ActualDeviceList = list()
    for ShortName in os.listdir("/dev"):
        if (re.match("^ttyUSB", ShortName)):
            print "  Found %s" % (ShortName)
            ActualDeviceList.append("/dev/" + ShortName)
    
   
    
    # ActualDeviceList = ["/dev/ttyUSB0", "/dev/ttyUSB1", "/dev/ttyUSB2" ]
 
 
    while (True):
        NameMap = dict()
        
        for ActualDevice in ActualDeviceList:
            print "Driving <%s>.  Look for lit LED." % (ActualDevice)
            UARTBlast(ActualDevice)
            
            while (True):
                print "Which was it (C)onsole (D)isk or (T)erm ?"
                Ans = raw_input().upper()
                if (Ans == "C" or Ans == "D" or Ans == "T") :
                    break
             
            if (Ans == "C") :
                LogicalName = "console_uart"
            elif (Ans == "D") :
                LogicalName = "disk_uart"
            elif (Ans == "T") :
                LogicalName = "term_uart"
                
            NameMap[LogicalName] = ActualDevice
            
        print "Blasting all devices to check config; should light from left to right"
        
        UARTBlast(NameMap["console_uart"]);
        UARTBlast(NameMap["disk_uart"]);
        UARTBlast(NameMap["term_uart"]);
    
        print "Did LED's blink from left to right in cons, disk, term order ?"
        Ans = raw_input().upper()
        if (Ans == "Y") :
            break
    
    print "Creating sym links in $HOME"
    for (LogicalName, ActualName) in NameMap.items():
        print "logical <%s> actual <%s>" % (LogicalName, ActualName)
        FullLogicalName = os.getenv("HOME") + "/" + LogicalName
        try:
            os.unlink(FullLogicalName)
        except:
            pass
        os.symlink(ActualName, FullLogicalName)
    
    
    
if (__name__ == "__main__"):
    main()
        
