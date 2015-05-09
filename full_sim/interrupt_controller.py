""" Interrupt Controller Class  """

import socket
import select
from time import sleep

def dummy_func(interrupt_num):
    return(0)


class Interrupt_Controller(object):
    # Memory map (0 - 2)
    # 0 - status address - Read only - set by interrupts
    # 1 - mask address - R/W
    # 2 - clear address - write 1 then 0 to clear an interrupt
       
    STATUS_ADDRESS = 0x0000
    MASK_ADDRESS = 0x0001
    CLEAR_ADDRESS = 0x0002

    NUM_INTERRUPT_SOURCES = 3
    
    def __init__(self, name = ""):
        print "Simulated Interrupt Controller is being initialized..."
        self.name = name
        self.__status__ = 0x0000
        self.__mask__ = 0x0000
        self.__clear__ = 0x0000
        self.__interrupt_callback_functions__ = dict()
        # self.interrupt_is_active = Interrupt_Controller.NUM_INTERRUPT_SOURCES * [False]
        # for i in range(Interrupt_Controller.NUM_INTERRUPT_SOURCES):
            # self.__interrupt_callback_functions__[i] = dummy_func
        self.output_is_blocked = False
  
    def __str__(self):
        s = ""
        s += "Int Ctrlr stat [%04X]  msk [%04X]  clr [%04X] Sim Blocked? [%s]\n" % \
            (self.__status__, self.__mask__, self.__clear__, self.output_is_blocked)
        return(s)

    def write(self, address, value):
        address &= 0x0003
        #
        if (address == Interrupt_Controller.MASK_ADDRESS):
            self.__mask__ = value
        elif (address == Interrupt_Controller.CLEAR_ADDRESS):
            self.__clear__ = value
        else:
            pass
        
        # status is normally set by external interrupt
        # interrupts are cleared by writing a one to the clear 
        # register.  
        self.__status__ = self.__status__ & ~self.__clear__
        
    def read(self, address):
        address &= 0x0003
        if (address == Interrupt_Controller.STATUS_ADDRESS):
            value = self.__status__
        elif (address == Interrupt_Controller.MASK_ADDRESS):
            value = self.__mask__
        elif (address == Interrupt_Controller.CLEAR_ADDRESS):
            value = self.__clear__
            
        return(value)
        
  
        

    def register_interrupt_source_function(self, function, interrupt_num):
        """ Register an external function which THIS class
        can use to find out if an interrupt has occurred (numbered 15 .. 0)
        """
        interrupt_num &= 0x000F
        # self.interrupt_is_active[interrupt_num] = True
        self.__interrupt_callback_functions__[interrupt_num] = function


    def get_output(self):
        if (self.__status__ == 0):
            return(0)
        else:
            if (self.output_is_blocked):
                return(0)
            else:
                return(1)

            
    def poll_interrupt_sources(self):
        # Set bit only - clear is done with clear reg.
        bit_position = 0
        for (interrupt_num, callback_func) in (self.__interrupt_callback_functions__.items()):
            # raw_interrupt_value = 0
            raw_interrupt_value = self.__interrupt_callback_functions__[interrupt_num](interrupt_num)
                      
            # Given the raw interrupt statue (0 or 1) we only care if
            # the statue is 1.  When it's 0, the old value is unchanged.
            if (raw_interrupt_value == 0): 
                continue
                
            # If we got this far, we know we have an interrupt.
            # Now we need to check if the interrupt is enabled
            # by looking at the correct bit in the mask register
            mask = (1 << interrupt_num) & self.__mask__
            if (mask == 0): 
                continue

                
            self.__status__ |= mask

    def sim_block_interrupt(self, output_is_blocked):
        self.output_is_blocked = output_is_blocked
 
        
# Main test harness
#

def test_func(interrupt_num):
    print "\nEntered test func for int %d" % interrupt_num
    selection = raw_input("  Enter int val (0 | 1)  >");
    if (selection == "0"):
        return(0)
    else:
        return(1)

    
# Main test function
def main():
    interrupt_controller = Interrupt_Controller()
    
    for interrupt_num in range(Interrupt_Controller.NUM_INTERRUPT_SOURCES):
        interrupt_controller.register_interrupt_source_function(test_func, interrupt_num)
        
    
    while (True):
        print "a - read all regs"
        print "m - write mask"
        print "c - write clear"
        print "p - poll sources"
        print "z - exit"
        selection = raw_input("Selection (case sensitive) >");
  
        if (selection == "a"):
            for address in range(3):
                val = interrupt_controller.read(address)
                print "  addr %02X val %04X" % (address, val)
            continue
        if (selection == "c"):
            selection = raw_input("16 bit hex mask >");
            clear = int(selection, 16)
            interrupt_controller.write(2, clear)
            continue
        if (selection == "m"):
            selection = raw_input("16 bit hex mask >");
            mask = int(selection, 16)
            interrupt_controller.write(1, mask)
            continue
        if (selection == "p"):
            interrupt_controller.poll_interrupt_sources()
            continue
        if (selection == "z"):
            break
            
            
        
if (__name__ == "__main__"):
    main()
        

