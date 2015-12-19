#!/usr/bin/python

import sys
import socket
import serial
import threading
import time


#####################################################################
# Constants
FOREVER_TIME = 1000000
#####################################################################
  
    
#####################################################################
def serial_to_socket():

    while (True):
        s = my_serial_port.read(1)
        # print "serial_to_socket: <%s>" % (s)
        my_socket.send(s)
#####################################################################

    

#####################################################################
def socket_to_serial():
    count = 0

    while (True):
        s = my_socket.recv(1)
        if (s == "") : 
            continue
        # print "socket_to_serial: count <%6d> <%s> <%d>" % (count, s, ord(s))
        count = count + 1
        num_bytes_written = my_serial_port.write(s)
        if (num_bytes_written != 1):
            print "WARNING socket_to_serial num_bytes_written is <%d>" % (num_bytes_written)
        # my_serial_port.flush()
#####################################################################

   

#####################################################################
#   
# Main Program is Here
#    
def main():
    global my_serial_port
    global my_socket
    
    program_name = sys.argv[0]
        
    if (len(sys.argv) != 4) :
        print "USAGE - %s  serial_device   baud_rate   tcp_listen_port" % (program_name)
        sys.exit(1)
     
    (serial_port_name, baud_rate, tcp_port) = sys.argv[1:]
    tcp_port = int(tcp_port)

    print "Opening serial port <%s> with blocking i/o" % (serial_port_name)
    my_serial_port = serial.Serial(port = serial_port_name, baudrate = baud_rate, timeout = None)
    
    # Clear out the serial port in case there's any thing trapped in it!
    print "Clearing serial buffer..."
    my_serial_port.read( my_serial_port.inWaiting() )

    print "Listening on port <%s>..." % (tcp_port)
    listen_socket = socket.socket()
    listen_socket.bind((str(socket.INADDR_ANY) , tcp_port))
    listen_socket.listen(1)
    (my_socket, address) = listen_socket.accept()
        
    print "TCP Connection made!"
    



    print "Starting socket_to_serial thread..."
    socket_to_serial_thread = threading.Thread(target = socket_to_serial)
    socket_to_serial_thread.start()


    print "Starting serial_to_socket thread..."
    serial_to_socket_thread = threading.Thread(target = serial_to_socket)
    serial_to_socket_thread.start()

    print "Main program has gone to sleep forever!"
    
    time.sleep(FOREVER_TIME)
#####################################################################
    
    
    
    
    
    
if (__name__ == "__main__"):
    main()
        

