""" Serial Port Class - uses sockets as proxy """

import socket
import select
from time import sleep
import signal


class SerialPort(object):

    # At 12Mhz, and 10,000 chars / sec
    # (12 * 10^6) / 10^4 = 12 * 10^2 = 1200
    DELAY = 1200
    WRITE_DELAY = 9
    
    def __init__(self, name = ""):
        print "Simulated Serial port is being initialized..."
        self.name = name
        self.__serial_input_buffer__ = [0] * 512
        self.__serial_output_buffer__ = [0] * 512
        
        # Memory map
        # 0 - data in AND out
        # 1 - status bits (15 .. 0)
        #       bit 0 = tx ready
        #       bit 1 = rx ready
        #
        self.__memory_map__  = [0] * 16
        self.__memory_map__[1] = 0x0001

        # TODO Make listen port global to module
        listen_port = 5000
        
        s = socket.socket()
        s.bind((str(socket.INADDR_ANY), listen_port))
        s.listen(1)

        print "   Connect with your TCP serial console to port %d" % listen_port
        
        (client_socket, address) = s.accept()
        print "   Connection has been received from address %s" % str(address)
        fd = client_socket.fileno()
        print "   socket fd is %d " % fd
        self.__poller__ = select.poll()
        self.__poller__.register(fd, select.POLLIN)

        self.__socket__ = client_socket
        

    def write(self, address, value):
        address &= 0x000F
        self.__serial_output_buffer__[0] = value
        self.__scheduler_function__(self._scheduled_serial_write, SerialPort.WRITE_DELAY, self.name + "serial write")
        # By calling this method we have "begun" a serial transmission
        # Therefore the transmitter ready bit must be cleard
        self.__memory_map__[1] &= 0xFFFE
        
    def read(self, address):
        address &= 0x000F
        if (address == 0):
            value = self.__serial_input_buffer__[address]
            # If we just read the data register we 
            # must clear the status register bit which indicated
            # there was data to be read
            self.__memory_map__[1] &= 0xFFFD
        elif (address == 1):
            value = self.__memory_map__[1]
            
        return(value)
        
    def _scheduled_serial_write(self):
        value = self.__serial_output_buffer__[0]
        num_sent = self.__socket__.send(chr(value))
        self.__memory_map__[1] |= 0x0001
        
    def __get_serial_input__(self):
        self.__scheduler_function__(self.__get_serial_input__, SerialPort.DELAY, self.name + " poll_serial_input") 

        old_handler = signal.getsignal(signal.SIGINT) 
        signal.signal(signal.SIGINT, signal.SIG_IGN)

        timeout_in_ms = 0
        result_list = self.__poller__.poll(timeout_in_ms)

        signal.signal(signal.SIGINT, old_handler)
        signal.siginterrupt(signal.SIGINT, False)
        
        if (len(result_list) == 0) : 
            return
            
        value = self.__socket__.recv(1)
        value = ord(value)
        self.__serial_input_buffer__[0] = value
        self.__memory_map__[1] |= 0x0002
    
        

    def register_scheduler_function(self, function):
        """ Register an external function which THIS class
        can use to schedule future events
        """
        self.__scheduler_function__ = function
        # Kick start scheduler of serial input
        # We are doing this here because, only here, do we know
        # the scheduler function exists.
        self.__scheduler_function__(self.__get_serial_input__, SerialPort.DELAY, self.name + " poll serial input")         

        
        
# Main test harness
#
def sf(function_to_schedule, delta_time):
    scheduled_events[time + delta_time] = function_to_schedule
    

    
# Main test function
def main():
    global scheduled_events
    scheduled_events = dict()
    global time
    
    scheduled_events = dict()
    print "Testing SerialPort..."
    test_device = SerialPort()
    time = -1
    test_device.register_scheduler_function(sf)
    
    output_string = list("michael jamet")
    
    while (time < 10000) :
        sleep(.01)
        time = time + 1

        if ( (time % 500 == 0) or (scheduled_events.has_key(time)) ) :
            print "\nTime Stamp %d" % time
            
        if (scheduled_events.has_key(time)) :
            # print "Doing event at time : %d " % time
            scheduled_events[time]()
        

        if (time % 100 == 13) :
            status = test_device.read(1)
            test_val = status & 0x0001
            if (test_val) :
                test_device.write(0, output_string.pop(0))
        
        if (time % 50 == 0) :
            status = test_device.read(1)
            test_val = status & 0x0002
            # print "DEBUG test_val after read is %x" % test_val
            if (test_val) :
                print "DEBUG a char has been recvd by serial port! We will read it."
                val = test_device.read(0)
                print"   DEBUG val was %s" % val
            
        
        # if (time == 600):
            # print "Doing serial write at time : %d " % time
            # test_device.write(0, "A")

        # if (time == 2200):
            # print "Doing serial write at time : %d " % time
            # test_device.write(0, "D")
    
        # if (time == 3000):
            # print "Doing serial write at time : %d " % time
            # test_device.write(0, "M")
    
            
    
    
if (__name__ == "__main__"):
    main()
        
