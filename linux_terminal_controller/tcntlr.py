#!/usr/bin/python
""" TCP based terminal server """

import sys
import socket
import select
import serial
from time import sleep

# Constants?
NUM_TERMINALS = 8
BASE_TCP_PORT = 7000
TERMINAL_INPUT = 1
WRITE_ACK = 2
  
   
class Sim_Serial_Port(object):

    def __init__(self, listen_port_num, description = ""):
        print "Initializing sim serial port on tcp port %d" % listen_port_num
        self.listen_port_num = listen_port_num
        self.listen_socket = socket.socket()
        self.listen_socket.bind((str(socket.INADDR_ANY) , listen_port_num))
        self.listen_socket.listen(1)
        self.client_socket = None
        self.description = description
        self.is_open = False
        self.received_data = list()

    def periodic_service(self):
        poller_timeout_ms = 5

        poller = select.poll()
        if (self.is_open):
            poller.register(self.client_socket, select.POLLIN)
        else:
            poller.register(self.listen_socket, select.POLLIN)

        result_list = poller.poll(poller_timeout_ms)
        
        # Checks to see if poller timed out.
        # If so, just go back and wait for more.
        if (len(result_list) == 0) :
            return

        # We are only polling for one event so
        # if we've gotten this far, we've either received data OR
        # gotten a connection request to be accepted.
        # We don't even need to look at the result list.
        if (self.is_open):
            print "DEBUG Got event on open socket. It is either data or close req"
            data = self.client_socket.recv(4096)
            if (len(data) == 0):
                print "Read 0 data - Assumed to be a close from remote side"
                print "Will close and stop listening to this socket"
                self.client_socket.close()
                self.is_open = False
                self.received_data = list()
            else:
                print "DEBUG got data from [%s] adding to buffered data" % data
                print "DEBUG appending all of it to self's received data"
                # Append (all at once) the just received data to our previously "received_data"
                self.received_data.extend(list(data))
                
                # Echo all the data back to the end-user terminal
                s = "".join(self.received_data)
                print "DEBUG new data list is [%s]" % s
                # Echo the data we just got - no cooked processing
                print "DEBUG     Echoing <%s>" % (data)
                tmp = ""
                for ch in data:
                    tmp += ch
                    if (ord(ch) == 13) :
                        tmp += chr(10)
                    
                self.client_socket.send(tmp)
        else: # Port is not open so an event means we have recvd a connection request.
            print "DEBUG Port was NOT open so we assume we got connection request"
            (self.client_socket, address) = self.listen_socket.accept()
            print "  DEBUG Accepted connection request."
            self.is_open = True
        
    def get_data(self, num_bytes):
        # This method should only be called when we KNOW num_bytes_are available
        # while (True):
            # if (len(self.received_data) >= num_bytes):
                # break
            # self.periodic_service
            
        print "DEBUG in get_data trying to return %d bytes" % num_bytes
        print "DEBUG there are %d bytes in buffer" % len(self.received_data)
        s = "".join(self.received_data[0:num_bytes])
        self.received_data = self.received_data[num_bytes:]
        return(s)
        
    def get_buffer_size(self):
        return(len(self.received_data))
        
    def transmit_to_terminal(self, data):
        if (self.is_open):
            num_bytes_sent = self.client_socket.send(data)
            # print "DEBUG Sent %d bytes to terminal" % num_bytes_sent
        else:
            print "Warning terminal is not open; transmission discarded"
            
class CMD_Channel(object):

    def __init__(self, description, dst_host, dst_port):
        print "Initializing a command channel [%s] "
        print "  Will attempt to connect to the simulator [%s %d]" % (dst_host, dst_port)
        print "  Please NOTE commands are expected to end in LF only (ctl J)"
        client_socket = socket.create_connection((dst_host, dst_port), 1)
        if (client_socket is None):
            print "Could not make connection; exiting."
            sys.exit(1)
        print "  Connection made!"
        
        self.description = description
        self.socket = client_socket
        self.active_line = ""
        
    def get_cmd(self):
        #
        # Gather up chars to form a command line
        # If we've gathered up enough to form a line, we 
        # return it.
        # We buffer chars in active_line until we see EOL
        # 
        poller = select.poll()
        poller.register(self.socket, select.POLLIN)
        timeout_in_ms = 20
        
        while (True) :
            result_list = poller.poll(timeout_in_ms)

            if (len(result_list) == 0):
                return("")
            
            data = self.socket.recv(1)
            self.active_line += data
                
            if (self.active_line.endswith("\n")):
                s = self.active_line.rstrip()
                self.active_line = ""
                return(s)

            
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
        # TODO make sure ALL of s is sent.
        num_sent = self.socket.send(s)
        if (num_sent != len(s)) :
            print "WARNING did not send all of string to host [%s]" % s
  
 

 
            
class Serial_CMD_Channel(object):



    def __init__(self, description, serial_device, baudrate):
        print "Initializing a serial device [%s] rate [%d] " % (serial_device, baudrate)
        print "  Description [%s]" % (description)
        print "  Please NOTE commands from host are expected to end in LF only (ctl J)"
        
        self.serial_port = serial.Serial(port = serial_device, baudrate = baudrate)
        self.description = description
        self.active_line = ""
        num_in_buffer = self.serial_port.inWaiting()
        print "Emptying serial input buffer of %d bytes." % (num_in_buffer)
        self.serial_port.read(num_in_buffer)

        
    def get_cmd(self):
        #
        # Gather up chars to form a command line
        # If we've gathered up enough to form a line, we 
        # return it.
        # We buffer chars in active_line until we see EOL
        # 
             
        while (True) :
            if (self.serial_port.inWaiting() == 0):
                return("")
        
            self.active_line += self.serial_port.read()
                            
            if (self.active_line.endswith("\n")):
                s = self.active_line.rstrip()
                self.active_line = ""
                return(s)

            
    def get_raw_data_from_host(self, num_bytes_to_receive):
        data = self.serial_port.read(num_bytes_to_receive)
        return(data)
        
        
    def send_to_host(self, s):
        num_sent = self.serial_port.write(s)
        if (num_sent != len(s)) :
            print "WARNING did not send all of string to host [%s]" % s
 
 
 
 
def do_cmd(cmd_from_host):
    global transmission_status
    
    if (cmd_from_host.startswith("t")):
        # String is of form tPPYY
        # PP is the port num in hex
        # YY is the amount of data to transmit
        # Raw data comes after command line
        l = list(cmd_from_host)
        serial_port_num =   int( "".join(l[1:3]), 16)
        num_bytes_to_send = int( "".join(l[3:5]), 16)
        # Get the data from the host and transmit it to the correct terminal
        data = cmd_channel.get_raw_data_from_host(num_bytes_to_send)
        print "Sending (cmd %s) data [%d bytes] from host to terminal %d" % (cmd_from_host, num_bytes_to_send, serial_port_num)
        print "   %s" % data
        serial_ports[serial_port_num].transmit_to_terminal(data)

        print "Sending a write ack for serial port : %d to the host" % serial_port_num
        packet = build_packet(serial_port_num, WRITE_ACK, "")        
        cmd_channel.send_to_host(packet)
        print "--------"


    else:
        print "Bad command! <%s> length <%d>" % (cmd_from_host, len(cmd_from_host))
        sys.exit(1)
        
            

def build_packet(terminal_num, packet_type, body = "") : 
    # Packet is a string of form
    #  type, terminal_num, size (3 bytes total)
    #  body (body can be empty for an ACK packet)
    #  padding (for a total of 256 bytes)
    #
    
    # todo change offset to 0
    ascii_offset = 0
    padding = "0" * ((256 - 3 - len(body)))
    # print "DEBUG len of body is %d" % len(body)
    # print "DEBUG len of padding is %d" % len(padding)

    packet = chr(packet_type + ascii_offset) + chr(terminal_num + ascii_offset) + chr(len(body) + ascii_offset)  + body + padding
    # print "\n\nDEBUG packet is [%s]\n [%s]\n [%s]\n [%s]\n [%s]\n " % ( chr(packet_type + ascii_offset), chr(terminal_num + ascii_offset ),  chr(len(body) + ascii_offset) ,  body ,  "".join(padding) )
    # print "\nlen of packet is [%d]\n" % (len(packet))
    return(packet)


#   
# Main Program is Here
# #
    
    
def main():
    global serial_ports
    global cmd_channel
    global transmission_status
    
    
        
    if (len(sys.argv) != 4) :
        print "USAGE - prog sim host port"
        print "USAGE - prog real serial_device speed"
        sys.exit(1)
        
    (program_name, mode, arg1, arg2) = sys.argv    
    arg2 = int(arg2)
    if (mode == "sim"):
        cmd_channel = CMD_Channel("CMD channel", arg1, arg2)
    elif (mode == "real"):
        cmd_channel = Serial_CMD_Channel("Serial CMD Channel", arg1, arg2)
    else:
        print "ERROR mode must be real or sim"
        sys.exit(1)
        
    
    # Transmission status per terminal
    #   0 = no transmission in progress
    #   1 = transmission complete
    transmission_status = [0] * NUM_TERMINALS
    serial_ports = dict()
    for serial_port_num in range(NUM_TERMINALS):
        serial_ports[serial_port_num] = Sim_Serial_Port(BASE_TCP_PORT + serial_port_num, "Serial Port %d" % serial_port_num)
    
    loop_delay_seconds = .1
    loop_delay_seconds = .05
    while (True):
        sleep(loop_delay_seconds)
        
        cmd_from_cpu = cmd_channel.get_cmd()
        if (len(cmd_from_cpu) != 0):
            do_cmd(cmd_from_cpu)
        
        for serial_port_num in range(NUM_TERMINALS):
            # Receive and echo data from terminals...
            serial_ports[serial_port_num].periodic_service()


        # todo fix \r references
        for serial_port_num in range(NUM_TERMINALS):
            # Send as many full lines back to host as possible
            while (True):
                if( serial_ports[serial_port_num].received_data.count("\r") == 0):
                    break
                    
                n = serial_ports[serial_port_num].received_data.index("\r")
                sub_str = "".join(serial_ports[serial_port_num].received_data[0:n+1])
                print "DEBUG FULL sub str is [%s]\n" % sub_str
                
                print "Sending data packet from terminal : %d to host" % (serial_port_num)
                packet = build_packet(serial_port_num, TERMINAL_INPUT, sub_str)
                
                cmd_channel.send_to_host(packet)
                serial_ports[serial_port_num].received_data[:] = serial_ports[serial_port_num].received_data[n+1:]
    
    
    
if (__name__ == "__main__"):
    main()
        

