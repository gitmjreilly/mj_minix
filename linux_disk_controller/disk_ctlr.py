#!/usr/bin/python
""" TCP based disk controller """

import os
import sys
import serial
import socket
from time import sleep

# Constants
SECTOR_SIZE = 512
HOST_PORT = 5600
HOST_INTERRUPT_PORT = 5601

   
class Host_Channel(object):

    def __init__(self, description, dst_host, dst_port):
        print "Initializing a host channel [%s] " % description
        print "  Will attempt to connect to the simulator [%s %d]" % (dst_host, dst_port)
        print "  Description [%s]" % (description)
        print "  Please NOTE commands from host are expected to end in LF only (ctl J)"
        client_socket = socket.create_connection((dst_host, dst_port), 1)
        if (client_socket is None):
            print "Could not make connection; exiting."
            sys.exit(1)
        print "  Connection made!"
        
        self.description = description
        self.socket = client_socket
        self.socket.setblocking(1)
        self.active_line = ""
        
    def get_cmd(self):
        s = ""
        while (True) :            
            data = self.socket.recv(1)
            if (data == "\n"):
                return(s)

            s += data
       
    def get_raw_data_from_host(self, num_bytes_to_receive):
        poller = select.poll()
        poller.register(self.socket, select.POLLIN)
        timeout_in_ms = 20
        data = ""
        while (True):        
            result_list = poller.poll(timeout_in_ms)
        
            # Check to see if data was received on the socket.
            # Checks to see if poller timed out.
            # If so, just go back and wait for more.
            if (len(result_list) != 0) :
                data += self.socket.recv(num_bytes_to_receive)
                if (len(data) == num_bytes_to_receive):
                    return(data)
  
    def send_to_host(self, s):
        num_sent = 0
        while (True):
            num_sent += self.socket.send(s)
            if (num_sent == len(s)) :
                break  
        print "Info - sent data [%d bytes] from disk controller to host" % len(s)
  

  
   
class Serial_Host_Channel(object):

    def __init__(self, description, serial_device, baudrate):
        print "Initializing a serial device [%s] rate [%d] " % (serial_device, baudrate)
        print "  Description [%s]" % (description)
        print "  Please NOTE commands from host are expected to end in LF only (ctl J)"
        
        self.serial_port = serial.Serial(port = serial_device, baudrate = baudrate)
        self.description = description
        
        
    def get_cmd(self):
        s = ""
        while (True) :            
            data = self.serial_port.read()
            if (data == "\n"):
                return(s)

            s += data
  
  
    def get_raw_data_from_host(self, num_bytes_to_receive):
        data = self.serial_port.read(num_bytes_to_receive)
        return(data)
  
  
    def send_to_host(self, s):
        num_sent = self.serial_port.write(s)
        print "Info - sent data [%d bytes] from disk controller to host" % len(s)
  

  
  
def do_cmd(cmd_from_host):
    global transmission_status
    global disk_file
    global host_channel
    global host_interrupt_channel
    global my_file
    global file_is_open
	
    
    print "\n\nDEBUG - Got command from host [%s] - Acting on it..." % cmd_from_host
        
    if (cmd_from_host.startswith("r")):
        # Read a sector from the disk file
        #
        # String is of form rXXXX\n
        # XXXX is the 4 hex digit SECTOR address
        print ""
        l = list(cmd_from_host)
        sector_num =   int( "".join(l[1:5]), 16)
        absolute_position = sector_num << 9
        print "Seeking to %08X" % (absolute_position)
        s = disk_file.seek(absolute_position)
        print "DEBUG seek returned <%s>" % (str(s))
        data = disk_file.read(SECTOR_SIZE)
        print "DEBUG Sending data to host; size of data is <%08X>" % (len(data))
        host_channel.send_to_host(data)

        print "DEBUG finished sending to host"
       
    if (cmd_from_host.startswith("w")):
        # Write a sector to the disk file
        #
        # String is of form wXXXX\n
        # XXXX is the 4 hex digit SECTOR address
        l = list(cmd_from_host)
        sector_num =   int( "".join(l[1:5]), 16)
        absolute_position = sector_num << 9
        print "Seeking to %08X" % (absolute_position)
        s = disk_file.seek(absolute_position)
        print "Getting raw data from host.."
        data_from_host = host_channel.get_raw_data_from_host(SECTOR_SIZE)
        disk_file.write(data_from_host)
        disk_file.flush()
        print "DEBUG write is done."
       
    if (cmd_from_host.startswith("O")):
        # Open a file on host running this program
        #
        # String is of form OFileName\n
 
        # Check to see if file is open; we only allow one open file at a time.
        if (file_is_open):
            print "  DEBUG ERROR file is already open"
            host_channel.send_to_host(chr(1))
            size_str = 	"%08X" % (0)
            host_channel.send_to_host(size_str)
            print "DEBUG finished sending 9 bytes to host (for already open file)"
            return

        # FileName is the name of the local file
        l = list(cmd_from_host)
        filename =   "".join(l[1:])
        print "Filename is [%s]" % (filename)

        try:
            num_bytes_in_file = os.path.getsize(filename)
        except:
            num_bytes_in_file = 0

        size_str = 	"%08X" % (num_bytes_in_file)

        if (num_bytes_in_file == 0):
            print "  DEBUG file is empty or non existent..."
            host_channel.send_to_host(chr(1))
            host_channel.send_to_host(size_str)
            print "DEBUG finished sending to host about empty file"
            return

        # If we got this far, we know file exists and we can read it
        my_file = open(filename, "r")
        file_is_open = True
        print "  DEBUG file <%s> has been opened; size is <%s>" % (filename, size_str)
        host_channel.send_to_host(chr(0))
        host_channel.send_to_host(size_str)
        print "DEBUG finished sending to host about properly opened file"
        return

    if (cmd_from_host.startswith("R")):
        data = my_file.read(256)
        print "DEBUG Sending  (opened file) data to host" 
        host_channel.send_to_host(data)
        if (len(data) != 256):
            pad = (256 - len(data)) * [chr(0)]
            host_channel.send_to_host("".join(pad))
        print "DEBUG finished sending 256 to host"

    if (cmd_from_host.startswith("C")):
        my_file.close()
        file_is_open = False
        host_channel.send_to_host(chr(0))
        
  
def create_test_file(file_name):
    print "Creating a dummy test file : %s" % file_name
    f = open(file_name, "w+")
    data = 256 * 256 * ['A']
    data = "".join(data)
    f.write(data)
    f.flush()
    f.close()
  
#   
# Main Program is Here
#
def main():
    global host_channel
    global host_interrupt_channel
    global disk_file
    global file_is_open
 
    if (len(sys.argv) != 5) :
        print "USAGE - prog sim host port disk_file"
        print "USAGE - prog real serial_device speed disk_file"
        sys.exit(1)
        
    (program_name, mode, arg1, arg2, disk_file_name) = sys.argv    
    arg2 = int(arg2)
    if (mode == "sim"):
        host_channel = Host_Channel("host channel", arg1, arg2)
    elif (mode == "real"):
        host_channel = Serial_Host_Channel("Serial Host Channel", arg1, arg2)
    else:
        print "ERROR mode must be real or sim"
        sys.exit(1)
        
    try:
       disk_file = open(disk_file_name, 'r+')
    except:
        print "ERROR Could not open disk_file <%s>" % (disk_file_name)
        sys.exit(1)



    file_is_open = False
 
 
 
    print "Waiting for commands from host ..."
    
    while (True):
        cmd_from_cpu = host_channel.get_cmd()
        do_cmd(cmd_from_cpu)
        
    
    
if (__name__ == "__main__"):
    main()
        

