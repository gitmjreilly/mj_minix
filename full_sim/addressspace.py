class AddressSpace(object):

    # Formally define the amount of memory we support
    MEMORY_SIZE = 16 * 1024 * 1024

    # We support 3 access categories for all 
    # memory in the simulator.
    # (The actual h/w supports NONE of this.
    # We can detect all memory access violations here (in this class)
    # since all memory i/o goes through.
    CODE_RO = 0
    DATA_RW = 1
    NO_ACCESS = 2

    def __init__(self):
        print "Initializing AddressSpace"
        self.device_list = []
        self.type_buffer = [AddressSpace.NO_ACCESS] * AddressSpace.MEMORY_SIZE
        self.is_fatal_memory_error = False
        self.is_memory_protection_on = False

    def __str__(self):
        return("No string representation")
        

    def add_device(self, base_address, max_address, device):
        device_description  = dict()
        device_description["base_address"] = base_address
        device_description["max_address"] =  max_address
        device_description["device"] = device
        self.device_list.append(device_description)
        
    def super_read(self, absolute_address):
        device_is_found = 0
        for memory_mapped_device in self.device_list:
            base_address = memory_mapped_device['base_address']
            max_address = memory_mapped_device['max_address']
            if ( (absolute_address >= base_address) and (absolute_address <= max_address) ) :
                relative_address = absolute_address - base_address
                return(memory_mapped_device['device'].read(relative_address), self.type_buffer[absolute_address])
        
        print("Fatal Error: no device mapped to address %x" % absolute_address)
        # exit(1)    

        
  
    def read(self, absolute_address):
        if (self.is_memory_protection_on) :
            if (self.type_buffer[absolute_address] != AddressSpace.DATA_RW):
                print "FATAL Error!  Tried to read from addr %08X but type is NOT DATA_RW." % \
                    absolute_address
                self.is_fatal_memory_error = True
                return(0)

        device_is_found = 0
        for memory_mapped_device in self.device_list:
            base_address = memory_mapped_device['base_address']
            max_address = memory_mapped_device['max_address']
            if ( (absolute_address >= base_address) and (absolute_address <= max_address) ) :
                relative_address = absolute_address - base_address
                return(memory_mapped_device['device'].read(relative_address))
        
        print("Fatal Error: no device mapped to address %x" % absolute_address)
        # exit(1)    

        
    def code_read(self, absolute_address):
        if (self.is_memory_protection_on) :
            if (self.type_buffer[absolute_address] != AddressSpace.CODE_RO):
                print "FATAL Error!  Tried to read CODE from addr %08X but type is NOT CODE_RO." % \
                    absolute_address
                self.is_fatal_memory_error = True
                return(0)

        device_is_found = 0
        for memory_mapped_device in self.device_list:
            base_address = memory_mapped_device['base_address']
            max_address = memory_mapped_device['max_address']
            if ( (absolute_address >= base_address) and (absolute_address <= max_address) ) :
                relative_address = absolute_address - base_address
                return(memory_mapped_device['device'].read(relative_address))
        
        print("Fatal Error: no device mapped to address %x" % absolute_address)
        # exit(1)    

        
    def write(self, absolute_address, value):    
        if (self.is_memory_protection_on) :
            if (self.type_buffer[absolute_address] != AddressSpace.DATA_RW):
                print "FATAL Error!  Tried to write to addr %08X but type is not data." % \
                    absolute_address
                self.is_fatal_memory_error = True
                return(0)

        device_is_found = 0
        for memory_mapped_device in self.device_list:
            base_address = memory_mapped_device['base_address']
            max_address = memory_mapped_device['max_address']
            if ( (absolute_address >= base_address) and (absolute_address <= max_address) ) :
                relative_address = absolute_address - base_address
                memory_mapped_device['device'].write(relative_address, value)
                return
        
        print("Fatal Error: no device mapped to address %x" % absolute_address)
        # exit(1)    
        
    def write_type(self, absolute_address, value):    
        self.type_buffer[absolute_address] = value
        
    def set_memory_protection_flag(self, state):
        self.is_memory_protection_on = state
        
class TestMemMappedDevice(object):

    def __init__(self):
        self.__mem__ = [0] * 50
        
    def __str__(self):
        return("no string rep for this class")
        
    def read(self, address):
        print("Reading from address %x" % address)
        return(self.__mem__[address])
        
    def write(self, address, value):
        self.__mem__[address] = value
        print("writing val %x to addr %x" % (value, address) )
        
  
#
# Main test function
def main():
    print "testing AddressSpace..."
    test_device = TestMemMappedDevice()
    A = AddressSpace()
    A.add_device(100, 149, test_device)
    A.write(101, 17)
    print(str(A.read(101)))
    
if (__name__ == "__main__"):
    main()