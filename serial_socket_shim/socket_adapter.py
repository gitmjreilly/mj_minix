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
def side_a_to_side_b():

    while (True):
        s = side_a_socket.recv(1)
        side_b_socket.send(s)
#####################################################################

    
#####################################################################
def side_b_to_side_a():

    while (True):
        s = side_b_socket.recv(1)
        side_a_socket.send(s)
#####################################################################


#####################################################################
def do_connection(host_port_string):
    l = host_port_string.split(':')

    if (len(l) == 1):
        port_num = int(l[0])
        
        print "Passively listening on port <%s>.  Connect to it now." % (port_num)
        listen_socket = socket.socket()
        listen_socket.bind((str(socket.INADDR_ANY) , port_num))
        listen_socket.listen(1)
        (my_socket, address) = listen_socket.accept()     
        print "Passive tcp connection has been received!"
        return(my_socket)
        
    if (len(l) == 2):
        hostname = l[0]
        port_num = int(l[1])
        
        print "Actively connecting to <%s> <%d>." % (hostname, port_num)
        my_socket = socket.socket()
        my_socket.connect((hostname, port_num))
        print "Active tcp connection has been made!"
        return(my_socket)
        
        
#####################################################################
   

#####################################################################
#   
# Main Program is Here
#    
def main():
    global side_a_socket
    global side_b_socket
    
    program_name = sys.argv[0]
        
    if (len(sys.argv) != 3) :
        print "USAGE - %s  side_a   side_b"  % (program_name)
        print "   side should look like host:port or port"
        print "   host:port results in active connection"
        print "   port results in passive (listening) connection"
        sys.exit(1)
    
    side_a = sys.argv[1]
    side_b = sys.argv[2]
    
    side_a_socket = do_connection(side_a)
    side_b_socket = do_connection(side_b)

    side_a_to_side_b_thread = threading.Thread(target = side_a_to_side_b)
    side_a_to_side_b_thread.start()
    
    side_b_to_side_a_thread = threading.Thread(target = side_b_to_side_a)
    side_b_to_side_a_thread.start()

    
    print "Main program has gone to sleep forever!"
    
    time.sleep(FOREVER_TIME)
#####################################################################
    
    
    
    
    
    
if (__name__ == "__main__"):
    main()
        

