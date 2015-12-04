""" Serial Port Class - uses sockets as proxy """

import socket
import select
from time import sleep
import signal

#
# Constants for default serial delays
# Can be overridden.
#
# If Clock = 10Mhz, 868, corresponds to 11,520 CPS (~115Kbs)
#   (10 * 10^6) / 11520 = 868
#
INPUT_DELAY  = 868
OUTPUT_DELAY = 868

class FifoSerialPort(object):



    def __init__(self, 
        input_fifo_size = 1024, 
        output_fifo_size = 1024, 
        listen_port = 5001,
        input_delay = INPUT_DELAY,
        output_delay = OUTPUT_DELAY,
        debug_flag  = False,
        name = ""):
        
        print "Simulated uart_w_fifo port [%s] is being initialized..." % name
        self.name = name
        self._input_fifo_size = input_fifo_size
        self._output_fifo_size = output_fifo_size
        self._serial_input_fifo = [0] * input_fifo_size
        self._serial_output_fifo = [0] * output_fifo_size
        self._input_producer = 0
        self._input_consumer = 0
        self._output_producer = 0
        self._output_consumer = 0

        # These delays define the simulated bit rate of this "serial port"
        self._input_delay = input_delay
        self._output_delay = output_delay
        
         #
        # self._memory_map  = [0] * 16
        # self._memory_map[1] = 0x0001

        s = socket.socket()
        s.bind((str(socket.INADDR_ANY), listen_port))
        s.listen(1)

        print "   Connect with your TCP serial 'device' %s to port %d" % (name, listen_port)
        
        (client_socket, address) = s.accept()
        print "   Connection has been received from address %s" % str(address)
        fd = client_socket.fileno()
        print "   socket fd is %d " % fd
        self._poller = select.poll()
        self._poller.register(fd, select.POLLIN)

        self._socket = client_socket
        
        self._debug_flag = debug_flag
        self._num_bytes_in_tx_fifo = 0
        self._num_bytes_in_rx_fifo = 0
        
    def reset(self):
        self._input_producer = 0
        self._input_consumer = 0
        self._output_producer = 0
        self._output_consumer = 0
        
        self._num_bytes_in_tx_fifo = 0
        self._num_bytes_in_rx_fifo = 0
        
    
    
        

    def set_input_delay(self, input_delay):
        self._input_delay = input_delay
        
    def set_output_delay(self, output_delay):
        self._output_delay = output_delay
        
    def write(self, address, value):
        # We assume the write is ONLY to the data register
        # so we don't explicitly check the address
        
        # We only capture lower 4 bits of address because this is what h/w does
        # Same reason for the value
        address &= 0x000F
        value &= 0x00FF

        # As a debugging aid to the simulator USER, Warn when the user program tries 
        # to add to an already full output fifo
        if (self._num_bytes_in_tx_fifo == self._output_fifo_size):
            print "DEBUG WARNING serial output fifo is already full before write [%s]" % self.name


        # Add char to output fifo and adjust pointer
        if (self._num_bytes_in_tx_fifo < self._output_fifo_size) :
            self._num_bytes_in_tx_fifo = self._num_bytes_in_tx_fifo + 1
            
        if (self._debug_flag):
            print "in write output_fifo has <%d> chars now" % (self._num_bytes_in_tx_fifo)

        self._serial_output_fifo[self._output_producer] = value
        self._output_producer = (self._output_producer + 1) % self._output_fifo_size

        # We only schedule a "serial" write if the output fifo was empty
        # prior to this call to write a new byte.
        if (self._num_bytes_in_tx_fifo == 1):
            self._scheduler_function(self._scheduled_serial_write, self._output_delay, self.name + "serial write")


        
    def read(self, address):
        address &= 0x000F
        value = 0
        if (address == 0):
            # Check to see if the input fifo is actually empty.
            # If so, it probably means the program running within the 
            # simulator has a bug.
            if (self._num_bytes_in_rx_fifo == 0):
                print "DEBUG WARNING reading from empty serial fifo %s " % self.name
            
            # Read the next byte from the input fifo and advance 
            # the consumer pointer.
            value = self._serial_input_fifo[self._input_consumer]
            self._input_consumer = (self._input_consumer + 1) % self._input_fifo_size
            
            if (self._num_bytes_in_rx_fifo > 0):
                self._num_bytes_in_rx_fifo = self._num_bytes_in_rx_fifo - 1
                
            if (self._debug_flag):
                print "in read input_fifo has <%d> chars now" % (self._num_bytes_in_rx_fifo)
            
                            
        elif (address == 1):
            # status word
            if (self._num_bytes_in_rx_fifo > 0) :
                value |= 0x0002
            # if (self._num_bytes_in_tx_fifo == 0) :
            if (self._num_bytes_in_tx_fifo < self._output_fifo_size) :
                value |= 0x0001

        elif (address == 2):
            if (self._num_bytes_in_tx_fifo == 0) :
                value = 0x0001
                
        elif (address == 3):
            if (self._num_bytes_in_tx_fifo <= (self._output_fifo_size / 2)) :
                value = 0x0001
                
        elif (address == 4):
            if (self._num_bytes_in_tx_fifo <= (self._output_fifo_size / 4)) :
                value = 0x0001
                
        elif (address == 5):
            if (self._num_bytes_in_tx_fifo == self._output_fifo_size ) :
                value = 0x0001
                
        elif (address == 6):
            if (self._num_bytes_in_rx_fifo == 0) :
                value = 0x0001
                
        elif (address == 7):
            if (self._num_bytes_in_rx_fifo >= (self._input_fifo_size / 2) ) :
                value = 0x0001
                
        elif (address == 8):
            if (self._num_bytes_in_rx_fifo >= (self._input_fifo_size / 4) ) :
                value = 0x0001
                
        elif (address == 9):
            if (self._num_bytes_in_rx_fifo == self._input_fifo_size ) :
                value = 0x0001
                
        elif (address == 0xE):
            value = self._num_bytes_in_rx_fifo 
                
        elif (address == 0xF):
            value = self._num_bytes_in_tx_fifo 
                
        
        
        
        return(value)




        
    def _scheduled_serial_write(self):
        # Start by sending the oldest char in the output fifo
        value = self._serial_output_fifo[self._output_consumer]
        num_sent = self._socket.send(chr(value))
        if (self._num_bytes_in_tx_fifo > 0) :
            self._num_bytes_in_tx_fifo = self._num_bytes_in_tx_fifo - 1
        if (self._debug_flag):
            print "in _scheduled_serial_write output_fifo has <%d> chars now" % (self._num_bytes_in_tx_fifo)


        
        # Update the output fifo to show that we've "consumed" a byte
        self._output_consumer = (self._output_consumer + 1) % self._output_fifo_size

        # Is there anything else in the output fifo?  If so, we should schedule
        # another serial write

        
        if (self._num_bytes_in_tx_fifo > 0):
            self._scheduler_function(self._scheduled_serial_write, self._output_delay, self.name + "serial write")
        
    # This function is meant to be used by an interrupt controller
    # interrupt_num is passed for debugging of interrupt controller.  
    # Not used here.         
    def get_input_data_available(self, interrupt_num = 0):
        if (self._input_empty != 1):
            return(1)
        else:
            return(0)


    # This function is meant to be used by an interrupt controller
    # interrupt_num is passed for debugging of interrupt controller.  
    # Not used here.        
    def get_rx_half_full(self, interrupt_num = 0):
        if (self._num_bytes_in_rx_fifo >= self._input_fifo_size / 2):
            return(1)
        else:
            return(0)


    # This function is meant to be used by an interrupt controller
    # interrupt_num is passed for debugging of interrupt controller.  
    # Not used here.        
    def get_rx_quarter_full(self, interrupt_num = 0):
        if (self._num_bytes_in_rx_fifo >= self._input_fifo_size / 4):
            return(1)
        else:
            return(0)




            
    def _get_serial_input(self):
        # Here we poll for "serial" input
        # We must only poll every self._input_delay; 
        # Receiving data more often than every DELAY would mean 
        # the serial port was able to receive at too high a rate.
        # We know chars can arrive no more often than every self._input_delay 
        # on the real h/w.
        # The first scheduled call was done when the scheduler_function was 
        # first assigned.
        #
        self._scheduler_function(self._get_serial_input, self._input_delay, self.name + " poll_serial_input") 

        # This is a bit of signal madness.
        # The simulator uses SIGINT to stop the "cpu" from running
        # In some cases, the whole simulator crashes because 
        # of an interrupt system call and it always seems to happen here.
        # This is an attempt to work around the problem.
        old_handler = signal.getsignal(signal.SIGINT) 
        signal.signal(signal.SIGINT, signal.SIG_IGN)

        timeout_in_ms = 0
        result_list = self._poller.poll(timeout_in_ms)

        signal.signal(signal.SIGINT, old_handler)
        signal.siginterrupt(signal.SIGINT, False)
        
        if (len(result_list) == 0) : 
            return

        # If we've gotten this far, we know a new "serial" byte has arrived.
        
        # If the input fifo was already full, this is probably a problem 
        # for the program running on the simulator.
        # As a courtesy, we warn the simulator user.
        if (self._num_bytes_in_rx_fifo == self._input_fifo_size):
            print "DEBUG Warning a new serial char has arrived but rx fifo is already full. %s "  % self.name
        
        # Let's retrieve our new char and add it to the input fifo
        # and update our status bit to show fifo is not empty.
        value = self._socket.recv(1)
        value = ord(value)
        self._serial_input_fifo[self._input_producer] = value
        self._input_producer = (self._input_producer + 1) % self._input_fifo_size

        
        if (self._num_bytes_in_rx_fifo < self._input_fifo_size):
            self._num_bytes_in_rx_fifo = self._num_bytes_in_rx_fifo + 1
        if (self._debug_flag):
            print "in _get_serial_input input_fifo has <%d> chars now" % (self._num_bytes_in_rx_fifo)
        
        

    
        
    def register_scheduler_function(self, function):
        """ Register an external function which THIS class
        can use to schedule future events
        """
        self._scheduler_function = function
        # Kick start scheduler of serial input
        # We are doing this here because, only here, do we know
        # the scheduler function exists.
        self._scheduler_function(self._get_serial_input, self._input_delay, self.name + " poll serial input")         


    def set_debug_flag(self, f):
        self._debug_flag = f
        
        
# Main test harness
#
def sf(function_to_schedule, delta_time, name):
    scheduled_events[time + delta_time] = function_to_schedule
    

    
# Main test function
def main():
    global scheduled_events
    scheduled_events = dict()
    global time
    
    scheduled_events = dict()
    print "Testing  Fifo FifoSerialPort..."
    test_device = FifoSerialPort(input_fifo_size = 3, listen_port = 5002)
    time = -1
    test_device.register_scheduler_function(sf)
    
    output_string = list("Hello World! Now is the time for all good men!")
    output_string = list("M")

    while (True) :
        sleep(.01)
    
        time = time + 1

        if ( (time % 500 == 0)  ) :
            print "\nTime Stamp %d" % time
                    
        
        status = test_device.read(1)

        if (len(output_string) > 0):
            if (status & FifoSerialPort.OUT_FULL_MASK == 0):
                print "  output fifo is NOT full so we'll write..."
                ch = output_string.pop(0)
                print "   writing [%s]" %ch
                val = ord(ch)
                test_device.write(0, val)
         
        
        if (scheduled_events.has_key(time)) :
            print "   Doing event at time : %d " % time
            scheduled_events[time]()
        
      
        if (time % 1000 == 0):
            if (status & FifoSerialPort.IN_EMPTY_MASK == 0):
                ch = chr(test_device.read(0))
                print "Received [%s]at time %d  " % (ch, time)

   
            
    
    
if (__name__ == "__main__"):
    main()
        

