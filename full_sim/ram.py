class RAM(object):

    def __init__(self):
        # Fill Memory with NOPS
        self.__memory__ = (8 * 1024 * 1024) * [1]
        self.__memory__[0] = 2
        self.__memory__[1] = 66
        self.__memory__[2] = 2
        self.__memory__[3] = 0xF000
        self.__memory__[4] = 8
        self.__memory__[5] = 3
        self.__memory__[1500] = 3
        self.name = "RAM"

    def __str__(self):
        return("This is the RAM object")
        
    def read(self, address):
        # print("RAM Reading from address %x" % address)
        val = self.__memory__[address]
        # print("   VAL is %x" % val)
        return(val)
        
    def write(self, address, value):
        value = value & 0xFFFF
        self.__memory__[address] = value
        # print("RAM writing val %x to addr %x" % (value, address) )
               
        
        