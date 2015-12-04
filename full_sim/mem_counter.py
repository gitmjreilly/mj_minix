
from time import sleep

# inc = 8 matches h/w and results in interrupt every 43ms
# If clock is running at 12MHz, an increment of 8 results in 43ms rollover
SCHEDULED_INCREMENT = 8


class Mem_Counter(object):


    def __init__(self, name = "Mem based counter"):
        print "Simulated Memory Mapped Counter is being initialized..."
        self.name = name
        self._value = 0x0000
        self._scheduler_function = None
        self._counter_is_zero = False
        self._increment = SCHEDULED_INCREMENT

    def __str__(self):
        s = ""
        s += "Counter value(hex): %04X increment is %d\n" % (self._value, self._increment)
        return(s)
        
        
        # Memory map
        # 0 - read only - 16 bit counter value

    def write(self, address, value):
        print "WARNING tried to write to RO Mem_Counter"
        pass
        
    def read(self, address):
        return(self._value)
        
    def _scheduled_increment(self):
        self._value = self._value + 1
        self._value &= 0xFFFF
        if (self._value == 0):
            self._counter_is_zero = True
        else:
            self._counter_is_zero = False
            
        self._scheduler_function(self._scheduled_increment, self._increment, self.name)         

    # This function is meant to be used by an interrupt controller
    # interrupt_num is passed for debugging of interrupt controller.  
    # Not used here.        
    def get_counter_is_zero(self, interrupt_num = 0):
        if (self._counter_is_zero == True):
            return(1)
        else:
            return(0)

    def register_scheduler_function(self, function):
        """ Register an external function which THIS class
        can use to schedule future events
        """
        self._scheduler_function = function
        # Kick start scheduler of future ticks
        # We are doing this here because, only here, do we know
        # the scheduler function exists.
        # The scheduler function takes a func, a delta time and a name
        self._scheduler_function(self._scheduled_increment, self._increment, self.name)         

    def set_increment(self, inc):
        self._increment = inc
        
# Main test harness
#
# Simple function for testing of future scheduled events
def sf(function_to_schedule, delta_time, name):
    scheduled_events[time + delta_time] = function_to_schedule
    

    
# Main test function
def main():
    global scheduled_events
    scheduled_events = dict()
    global time
    
    print "Testing Memory Mapped Counter..."
    test_device = Mem_Counter()
    time = -1
    test_device.register_scheduler_function(sf)
    
    while (time < 1000) :
        sleep(.01)
        time = time + 1

        if ( (time % 500 == 0) or (scheduled_events.has_key(time)) ) :
            print "\nTime Stamp %d" % time
            
        if (scheduled_events.has_key(time)) :
            scheduled_events[time]()
            print ("  Counter val is %d" % test_device.read(0))
            
    
    
if (__name__ == "__main__"):
    main()
        
