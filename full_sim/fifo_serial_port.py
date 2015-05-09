""" Serial Port Class - uses sockets as proxy """

import socket
import select
from time import sleep
import signal

#
# Constants for default serial delays
# Can be overridden.
#
# If Clock = 12 Mhz, 1200, corresponds to 10,000 CPS (~115Kbs)
#   (12 * 10^6) / 10^4 = 12 * 10^2 = 1200
#
INPUT_DELAY  = 1200
OUTPUT_DELAY = 1200

class FifoSerialPort(object):

    
    IN_EMPTY_MASK  = 0x0001
    IN_FULL_MASK   = 0x0002
    OUT_EMPTY_MASK = 0x0004
    OUT_FULL_MASK  = 0x0008 

    def __init__(self, 
        input_buffer_size = 64, 
        output_buffer_size = 64, 
        listen_port = 5001,
        input_delay = INPUT_DELAY,
        output_delay = OUTPUT_DELAY,
        debug_flag  = False,
        name = ""):
        
        print "Simulated FIFOSerial port [%s]is being initialized..." % name
        self.name = name
        self._input_buffer_size = input_buffer_size
        self._output_buffer_size = output_buffer_size
        self._serial_input_buffer = [0] * input_buffer_size
        self._serial_output_buffer = [0] * output_buffer_size
        self._input_producer = 0
        self._input_consumer = 0
        self._output_producer = 0
        self._output_consumer = 0
        # The input and output fifo's start empty, NOT full
        self._input_empty = 1
        self._input_full = 0
        self._output_empty = 1
        self._output_full = 0
        self._input_delay = input_delay
        self._output_delay = output_delay
        
        # Memory map
        # 0 - data in AND out
        # 1 - status bits (15 .. 0)
        #     
        # IN_EMPTY_MASK  = 0x0001 (bit 0)
        # IN_FULL_MASK   = 0x0002 (bit 1)
        # OUT_EMPTY_MASK = 0x0004 (bit 2)
        # OUT_FULL_MASK  = 0x0008 (bit 3)
        #
        self._memory_map  = [0] * 16
        self._memory_map[1] = 0x0001

        s = socket.socket()
        s.bind((str(socket.INADDR_ANY), listen_port))
        s.listen(1)

        print "   Connect with your TCP serial 'device' to port %d" % listen_port
        
        (client_socket, address) = s.accept()
        print "   Connection has been received from address %s" % str(address)
        fd = client_socket.fileno()
        print "   socket fd is %d " % fd
        self._poller = select.poll()
        self._poller.register(fd, select.POLLIN)

        self._socket = client_socket
        
        self._debug_flag = debug_flag
        self._num_chars_in_output_buffer = 0
        self._num_chars_in_input_buffer = 0
        

    def set_input_delay(self, input_delay):
        self._input_delay = input_delay
        
    def set_output_delay(self, output_delay):
        self._output_delay = output_delay
        
    def write(self, address, value):
        # We assume the write is ONLY to the data register
        # so we don't explicitly check the address
        
        address &= 0x000F
        value &= 0x00FF

        # As a debugging aid to the simulator USER, note when we try to add to an 
        # already full output buffer
        if (self._output_full == 1):
            print "DEBUG WARNING serial output fifo is already full before write [%s]" % self.name


        # Add char to output buffer and adjust pointer
        # and full/empty status bits
        self._num_chars_in_output_buffer = self._num_chars_in_output_buffer + 1
        if (self._debug_flag):
            print "in write output_buffer has <%d> chars now" % (self._num_chars_in_output_buffer)

        self._serial_output_buffer[self._output_producer] = value
        self._output_producer = (self._output_producer + 1) % self._output_buffer_size

        # We only schedule a "serial" write if the output fifo was empty
        # prior to this call to write a new byte.
        if (self._output_empty):
            self._scheduler_function(self._scheduled_serial_write, self._output_delay, self.name + "serial write")

        # As a result of this call to write a new byte 
        # we know now the output fifo is not empty.
        # In fact, the  output buffer may be full.
        self._output_empty = 0    
        if (self._output_producer == self._output_consumer):
            self._output_full = 1
     
        self._memory_map[1] &= 0xFFFE
        
    def read(self, address):
        address &= 0x000F
        if (address == 0):
            # If we're reading from the fifo it CANNOT be full
            # Update the status bit to reflect this.
            # Please note _input_full might have already been false.
            self._input_full = 0
            
            # Check to see if the input fifo is actually empty.
            # If so, it probably means the program running within the 
            # simulator has a bug.
            if (self._input_empty == 1):
                print "DEBUG WARNING reading from empty serial fifo %s " % self.name
            
            # Read the next byte from the input buffer and advance 
            # the consumer pointer.
            value = self._serial_input_buffer[self._input_consumer]
            self._input_consumer = (self._input_consumer + 1) % self._input_buffer_size
            
            
            self._num_chars_in_input_buffer = self._num_chars_in_input_buffer - 1
            if (self._debug_flag):
                print "in read input_buffer has <%d> chars now" % (self._num_chars_in_input_buffer)
            
            # Now that we've read a byte from the buffer, the buffer 
            # may be empty.  Update empty status bit if necessary
            if (self._input_producer == self._input_consumer):
                self._input_empty = 1
                
            
            # If we just read the data register we 
            # must clear the status register bit which indicated
            # there was data to be read
            self._memory_map[1] &= 0xFFFD
        elif (address == 1):
            value = 0
            if (self._input_empty):
                value |= FifoSerialPort.IN_EMPTY_MASK
            if (self._input_full):
                value |= FifoSerialPort.IN_FULL_MASK

            if (self._output_empty):
                value |= FifoSerialPort.OUT_EMPTY_MASK
            if (self._output_full):
                value |= FifoSerialPort.OUT_FULL_MASK

                
        return(value)
        
    def _scheduled_serial_write(self):
        # Start by sending the oldest char in the output fifo
        value = self._serial_output_buffer[self._output_consumer]
        num_sent = self._socket.send(chr(value))
        self._num_chars_in_output_buffer = self._num_chars_in_output_buffer - 1
        if (self._debug_flag):
            print "in _scheduled_serial_write output_buffer has <%d> chars now" % (self._num_chars_in_output_buffer)


        # TODO Update 
        self._memory_map[1] |= 0x0001
        
        # Update the output fifo to show that we've "consumed" a byte
        # Note the output buffer CANT be full now that we've transmitted a char
        self._output_consumer = (self._output_consumer + 1) % self._output_buffer_size
        self._output_full = 0

        # Is there anything else in the output buffer?  If so, we should schedule
        # another serial write
        if (self._output_producer == self._output_consumer):
            self._output_empty = 1
        
        if (self._output_empty != 1):
            self._scheduler_function(self._scheduled_serial_write, self._output_delay, self.name + "serial write")
        
    # This function is meant to be used by an interrupt controller
    # interrupt_num is passed for debugging of interrupt controller.  
    # Not used here.         
    def get_input_data_available(self, interrupt_num = 0):
        if (self._input_empty != 1):
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
        if (self._input_full == 1):
            print "DEBUG Warning a new serial fifo char has arrived but input fifo is already full. %s "  % self.name
        
        # Let's retrieve our new char and add it to the input fifo
        # and update our status bit to show buffer is not empty.
        value = self._socket.recv(1)
        value = ord(value)
        self._serial_input_buffer[self._input_producer] = value
        self._input_producer = (self._input_producer + 1) % self._input_buffer_size
        self._input_empty = 0

        
        self._num_chars_in_input_buffer = self._num_chars_in_input_buffer + 1
        if (self._debug_flag):
            print "in _get_serial_input input_buffer has <%d> chars now" % (self._num_chars_in_input_buffer)
        
        
        if (self._input_producer == self._input_consumer):
            self._input_full = 1
     
      
        self._memory_map[1] |= 0x0002
    
        
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
    test_device = FifoSerialPort(input_buffer_size = 3, listen_port = 5002)
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
        

