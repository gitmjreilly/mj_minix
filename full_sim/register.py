
class Register(object):

    def __init__(self):
        """ Initialize with the value """
        self.value = 0

    def __str__(self):
        return(str(self.value))
        
    def read(self):
        return(self.value)
        
    def write(self, value):
        self.value = value & 0xFFFF
        
    def inc(self):
        self.value = (self.value + 1) & 0xFFFF;


    def dec(self):
        self.value = (self.value - 1) & 0xFFFF;

class Register_With_History(object):
    NUM_HISTORY_ENTRIES = 1000

    def __init__(self):
        """ Initialize with the value """
        self.value = 0
        self.history = Register_With_History.NUM_HISTORY_ENTRIES * [0]
        # _head is a pointer at the last entry NOT the next free spot
        # There is no TAIL; this is a circular buffer
        self._head = 0

    def __str__(self):
        return(str(self.value))
        
    def read(self):
        return(self.value)
        
    def read_previous(self):
        # head is the free spot
        p = self._head
        s = ""
        for num_entries in xrange(10):
            p = p - 1
            if (p < 0):
               p = Register_With_History.NUM_HISTORY_ENTRIES - 1
            s += "%04X " % (self.history[p]) + " "
        return(s)
        
    def write(self, value):
        self.history[self._head] = self.value
        self._head = self._head + 1
        if (self._head == Register_With_History.NUM_HISTORY_ENTRIES):
            self._head = 0
        self.value = value & 0xFFFF
        
    def inc(self):
        self.write((self.value + 1) & 0xFFFF)


    def dec(self):
        self.write((self.value - 1) & 0xFFFF)
        
print " Just imported register. "        