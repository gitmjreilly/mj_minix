#!/usr/bin/python

""" Main Computer Simulator Program """

######################################################################
import sys
import signal

from cpu import CPU
from register import Register
from addressspace import AddressSpace
from mem_counter import Mem_Counter
from ram import RAM
from scheduler import Scheduler
from interrupt_controller import Interrupt_Controller
from fifo_serial_port import FifoSerialPort
from time import sleep
######################################################################

######################################################################
# Global Vars
human_time = 0.00
tenth_second_tick = 0
######################################################################



######################################################################
def init_memory_protection() :
    global address_space
    
    print "Initializing memory protection (This takes a while...)"
    # Mark the whole memory space as guarded and
    # then open holes as necessary.
    for memory_addr in range(AddressSpace.MEMORY_SIZE):
    	address_space.write_type(memory_addr, AddressSpace.NO_ACCESS)
    

    
######################################################################



######################################################################
# How to add a memory mapped device
#
# Instantiate device
# Add it to the address space.
# Register any output functions with the interrupt controller if the device
#   generates interrupts
# Register the scheduler add_event method with the device if the device needs
#   to schedule future events
#
#
#   FifoSerialPort - 
#       specify TCP port on which to listen
#       Specify input and output delays - these are clock ticks
#       between bytes 
#       
def construct_computer_system():
    global the_cpu
    global address_space
    global ram
    global console_serial_port
    global interrupt_controller
    global scheduler
    global counter_0
    global serial_1
    global serial_2
    
    console_serial_port = FifoSerialPort(
        listen_port = 5000, 
        input_delay = 1200, 
        output_delay = 10,
        name = "Console")
    
    
    the_cpu = CPU()
    
    address_space = AddressSpace()
    the_ram = RAM()
 
    interrupt_controller = Interrupt_Controller()
    
    counter_0 = Mem_Counter()
    
    serial_1 = FifoSerialPort(
        listen_port = 5600, 
        input_delay = 1200, 
        output_delay = 1200,
        name = "Disk Controller")
    
    serial_2 = FifoSerialPort(
        listen_port = 6000, 
        input_delay = 1200, 
        output_delay = 1200,
        name = "Terminal Controller")
    
  
    

    # Please note address spaces can overlap. They are searched in FIFO order
    address_space.add_device(0xF000, 0xF00F, console_serial_port)
    address_space.add_device(0xF010, 0xF01F, interrupt_controller)
    address_space.add_device(0xF090, 0xF09F, serial_1)
    address_space.add_device(0xF030, 0xF03F, serial_2)
    address_space.add_device(0xF060, 0xF06F, counter_0)

    address_space.add_device(0x1F000, 0x1F00F, console_serial_port)
    address_space.add_device(0x2F000, 0x2F00F, console_serial_port)
    address_space.add_device(0x3F000, 0x3F00F, console_serial_port)
    address_space.add_device(0x4F000, 0x4F00F, console_serial_port)
    
    # Make sure to keep RAM at end of address space because 
    # address space is searched (for devices) in insertion order
    address_space.add_device(0, 1024 * 1024 * 8, the_ram)
    
    
    the_cpu.set_memory_methods(
        address_space.read, 
        address_space.write, 
        address_space.code_read, 
        address_space.write_type)

    # "Connect" the counter's "Zero" output to interrupt source 1 as is done in the VHDL
    interrupt_controller.register_interrupt_source_function(
        counter_0.get_counter_is_zero, 
        1)

    # Connect the disk uart "rx half full" line to interrupt source 4 as in VHDL
    interrupt_controller.register_interrupt_source_function(
        serial_1.get_rx_half_full, 
        4)
        
    # Connect the ptc uart "rx quarter full" line to interrupt source 5
    interrupt_controller.register_interrupt_source_function(
        serial_2.get_rx_quarter_full, 
        5)
        
    # interrupt_controller.register_interrupt_source_function(
        # serial_3.get_input_data_available, 
        # 2)
    
    
    scheduler = Scheduler()

    #
    # The serial port needs to schedule future events.  The scheduling 
    # function is scheduler.add_event() - signature below
    #     add_event(self, event_method, scheduled_time, name_of_event = "")
    console_serial_port.register_scheduler_function(scheduler.add_event)
    

    #
    # The "high speed" fifo serial port needs to schedule future events.  The scheduling 
    # function is scheduler.add_event() - signature below
    #     add_event(self, event_method, scheduled_time, name_of_event = "")
    serial_1.register_scheduler_function(scheduler.add_event)
 
    serial_2.register_scheduler_function(scheduler.add_event)

    # serial_3.register_scheduler_function(scheduler.add_event)
    
    #
    # The timer/counter needs to schedule future events (ie. the ticks)
    counter_0.register_scheduler_function(scheduler.add_event)

######################################################################


######################################################################
# Load an object file into the addressSpace.
# The format is expected to be the same as that used in the ROM
# loader i.e. ascii hex strings (organized as hex words - 4 digits each)
#    word 1 - word count excluding 2 word header
#    word 2 - starting address
#    words 2-n data words, loaded starting at 0x0403
#    
def load_object_file() :
    global the_cpu

    obj_file_name = raw_input("Enter name of object file to load>");
    try:
        f = open(obj_file_name) 
    except:
        print "Could not open %s" % obj_file_name
        return
        
        
    s = f.read(4)
    length = int(s, 16)
    
    s = f.read(4)
    start_addr = int(s, 16)
    
    print("length is %04X start addr is %04X\n" % (length, start_addr))

    memory_addr = 0x0403
    while (True) :
        if (length == 0) :
            print "Finished loading file."
            the_cpu.set_pc(start_addr)
            f.close()
            return
            
        s = f.read(4)
        data_word = int(s, 16)
            
        address_space.write(memory_addr, data_word)
        memory_addr = memory_addr + 1
        length = length - 1
######################################################################


######################################################################
def memory_dump() :
    start_addr = raw_input("Enter starting addr (in hex)>");
    start_addr = int(start_addr.upper(), 16)

    size = 16

    i = 1
    while (i <= size) :
        (value, type)= address_space.super_read(start_addr)
        print "   %04X: %04X %04d" % (start_addr, value, type)
        start_addr = start_addr + 1
        i = i + 1

######################################################################
  

######################################################################
def memory_write() :
    memory_addr = raw_input("Enter addr (in hex) to write>");
    memory_addr = int(memory_addr.upper(), 16)

    val = raw_input("Enter 16 bit val (in hex) to write>");
    val = int(val.upper(), 16)
 
    address_space.write(memory_addr, val)

######################################################################
    

######################################################################
def run_simulator(single_step_mode):
    global time
    global scheduler
    global is_keyboard_interrupt
    global break_point_list
    global interrupt_controller
    global tenth_second_tick
    global human_time

    # We are trying to simulate the fact that instructions
    # require multiple clock cycles.  For now we are assuming
    # every instruction requires 8 cycles.  This is a conservative
    # estimate.  Every instruction except those involving syscalls or
    # interrupts use less.
    NUM_CYCLES_PER_INSTRUCTION = 8
    
    while (True) :
       
        time = time + 1
        tenth_second_tick = tenth_second_tick + 1
        scheduler.set_time(time)

        scheduler.do_scheduled_events(time) 
        
        
        if ( (tenth_second_tick == 1000000) ) :
            tenth_second_tick = 0
            human_time = human_time + .1
            print "\nTime Stamp (in secs) %02f" % human_time
            
        # Cheap way to "schedule" instructions on every n-th cycle.
        if (time % NUM_CYCLES_PER_INSTRUCTION != 0):
            continue
            

        if (is_keyboard_interrupt) :
            print "\n\nGot kbd int.  Breaking at clock tick : %d" % time
            print "  Time (in secs) is : %02f" % human_time
            is_keyboard_interrupt = 0
            return

            # Have the interrupt controller check all of its sources
        interrupt_controller.poll_interrupt_sources() 
        global_interrupt = interrupt_controller.get_output()

        
        # If we got this far, it's time to step the cpu.    
            
        
        the_cpu.set_interrupt_input(global_interrupt)
        status = the_cpu.step()
        if (status != 0) :
            print "Got non zero return from cpu.step()- stopping simulator"
            return
            
        if (address_space.is_fatal_memory_error):
            print "Had fatal memory access error.  Stopping simulator"
            address_space.is_fatal_memory_error = False
            return
            
        if (single_step_mode):
            return

        if (break_point_list.has_key(the_cpu.PC.value)) :
            print "Encountered bkpt at %04x" % the_cpu.PC.value
            return

#####################################################################


######################################################################
def initMemoryProtection() :
    # Mark the whole memory space as guarded and
    # then open holes as necessary.
    print "Protecting mem. Any loaded progs will lose their protection settings"
    
    for  memoryAddr in xrange (0, 0x60000) :
    	address_space.write_type(memoryAddr, AddressSpace.NO_ACCESS);
    
    # Mark top 4K (of a few of the bottom few banks) as  data to handle 
    # initial stacks and memory mapped peripherals
    for bank_num in range(5):
        seg = bank_num * 0x10000
        for memory_addr in range(seg + 0xF000, seg + 0x10000):
            address_space.write_type(memory_addr, AddressSpace.DATA_RW)
            
    # Make sure to mark interrupt and syscall vectors as code
    for  memoryAddr  in xrange(0xFD00, 0xFD04) :
    	address_space.write_type(memoryAddr, AddressSpace.CODE_RO);

######################################################################
   
   
#####################################################################
def load_pats_loader() :

    print("Loading Pat's loader...");

    # printf("Enter the name of Pats loader>");
    # chomp(my objFileName =  <STDIN>);
    # if (! -r objFileName) :
    # 	printf("Could not open objFileName!\n");
    # 	return;
    # 
    obj_file_name =  "loader_from_zero.txt";
    f = open(obj_file_name)
    line_buffer = f.readlines()

    memory_addr = 0x0000;
    for l in line_buffer :
        data_word = int(l, 16)

        address_space.write_type(memory_addr, AddressSpace.DATA_RW)
        address_space.write(memory_addr, data_word);
        address_space.write_type(memory_addr, AddressSpace.CODE_RO)
        memory_addr = memory_addr + 1
######################################################################

   
#####################################################################
def catch_sigint(signum, frame) :
    global is_keyboard_interrupt
    is_keyboard_interrupt = 1
        
    signal.signal(signal.SIGINT, catch_sigint)
    signal.siginterrupt(signal.SIGINT, False)
######################################################################
 


######################################################################
# Load an object file into the addressSpace.
# The format should be the special simulator format
# The format is BINARY
# Each word comes as 2 bytes MSB first
#    word 1     :  Words 1 and 2 are a MAGIC identifier 0000 0002
#    word 2  
#    word 3     : size of program in words
#    word 4     : loading address
#    word 5     : starting address
#    words 6-n  : 3 * size in bytes (as shown below)
#       byte - type (guard, data, code)
#       byte - MSB of data val
#       byte - LSB of data val
#
def loadObjectFile2() :
    global the_cpu
    
    
    obj_file_name = raw_input("Enter the name of the SIMulator object file to load >")

    try:
        f = open(obj_file_name)
    except:
        print "Could not open the sim object file.  Returning..."
        return
        
    s = raw_input("Enter the proc num (same as in kernel) >")
    seg_val = int(s, 16) * 0x10000
    
   
    word1 = 256 * ord(f.read(1)) + ord(f.read(1))
    word2 = 256 * ord(f.read(1)) + ord(f.read(1))
    print "DEBUG word 1 is %04X word 2 is %04X" % (word1, word2)
    if ((word1 != 0) or (word2 != 2)) :
        print("ERROR did not see magic number in loaded object file!\n")
        f.close()
        return

    print("Saw magic number in loaded file.  Continuing...")
    
    length = 256 * ord(f.read(1)) + ord(f.read(1))

    loadAddr = 256 * ord(f.read(1)) + ord(f.read(1))

    startAddr = 256 * ord(f.read(1)) + ord(f.read(1))

    print("length is %04X load addr is %04X start addr is %04X" % ( length, loadAddr, startAddr))


    for memoryAddr in range(loadAddr + seg_val, (loadAddr + length + seg_val)) :
        type = ord(f.read(1))   
        dataWord = 256 * ord(f.read(1)) + ord(f.read(1))
        
        address_space.write_type(memoryAddr, AddressSpace.DATA_RW)
        address_space.write(memoryAddr, dataWord)
        address_space.write_type(memoryAddr, type)


    if (seg_val == 0):
        print ("Seg val is 0 so we will set PC")
        print("Setting PC to %04X" % startAddr)
        the_cpu.set_pc(startAddr)
        the_cpu.CS.write(0)
        the_cpu.ES.write(0)
        the_cpu.DS.write(0)

    f.close()
######################################################################
 
  
######################################################################
def help_message():
    print "This is the help message..."
    print "h - This help message"
    print "r - run the simulator"
    print "s - STEP the simulator"
    print "R - reset pc to 0"
    print "a - show scheduler"
    print "d - show state"
    print "m - dump memory"
    print "w - write to memory"
    print "b - set break point"
    print "c - clear break point"
    print "B - show break points"
    print "H - show address history"
    print "l - load 403 object file"
    print "L - load sim object file"
    print ""
    print "i - Block interrupt from reaching CPU"
    print "I - Restore normal interrupt behaviour"
    print ""
    print "v - debug disk ctlr serial port"
    print "V = NO debug disk ctlr serial port"
    print "P - Initialize memory protection"
    print "p - Set memory protection state (True or False)"
    print "e - set counter inc divisor (8 = 43ms w/12Mhz clock"
    print "q - quit"

    
######################################################################


######################################################################
def init():
    global is_keyboard_interrupt
    global time
    global break_point_list

    time = -1
    is_keyboard_interrupt = 0
    
    signal.signal(signal.SIGINT, catch_sigint)
    signal.siginterrupt(signal.SIGINT, False)

    construct_computer_system()

    initMemoryProtection()
    
    load_pats_loader()
    
    break_point_list = dict()
    
######################################################################


######################################################################
# 
# Main Program
#
init()

while (True):
    selection = raw_input("Simulator (h for help) >");

    # We clear possible fatal memory errors
    # here in the main user loop b/c it is possible
    # an operation like a mem dump caused one so
    # this would be a false error condition
    address_space.is_fatal_memory_error = False
  
    if (selection == "h"):
        help_message()
        continue

    if (selection == "a"):
        print scheduler
        continue
    
    if (selection == "r"):
        print "Running simulator"
        run_simulator(0)
        continue
        
    if (selection == "s"):
        print "STEP simulator"
        run_simulator(1)
        print the_cpu
        continue
        
    if (selection == "R"):
        the_cpu.PC.write(0)
        the_cpu.RSP.write(0xFE00)
        the_cpu.PSP.write(0xFF00)
        the_cpu.CS.write(0)
        the_cpu.DS.write(0)
        the_cpu.ES.write(0)
        the_cpu.INT_CTL_LOW.write(0)
        console_serial_port.reset()
        serial_1.reset()
        serial_2.reset()
        continue
        
    if (selection == "d"):
        print "Time is %d" % time
        print the_cpu
        print counter_0
        print interrupt_controller
        continue

    if (selection == "m"):
        memory_dump()
        continue
 
    if (selection == "w"):
        memory_write()
        continue
 
    if (selection == "b"):
        the_cpu.set_break_point()
        continue
        
    if (selection == "B"):
        the_cpu.show_break_points()
        continue
        
    if (selection == "c"):
        the_cpu.clear_break_point()
        continue
                
    if (selection == "H"):
        the_cpu.show_address_history()
        continue
        
    if (selection == "l"):
        load_object_file()
        continue
        
    if (selection == "L"):
        loadObjectFile2()
        continue
        
    if (selection == "i"):
        interrupt_controller.sim_block_interrupt(True)
        continue
        
    if (selection == "I"):
        interrupt_controller.sim_block_interrupt(False)
        continue
        
    if (selection == "e"):
        selection = raw_input("Enter counter (in dec) inc (8 = 43ms on 12Mhz sys) >");
        counter_increment = int(selection, 10)
        counter_0.set_increment(counter_increment)
        continue
        
    if (selection == "P"):    
        initMemoryProtection()
        continue
        
    if (selection == "p"):
        f = raw_input("set memory protection flag (y/n)? ");
        if (f.upper() == "Y"):
            print "Setting to true"
            address_space.set_memory_protection_flag(True)
        else:
            print "Setting to false"
            address_space.set_memory_protection_flag(False)
        
    # if (selection == "v"):    
        # serial_2.set_debug_flag(True)
        # continue
           
    # if (selection == "V"):    
        # serial_2.set_debug_flag(False)
        # continue
           
        
    if (selection == "q"):
        sys.exit(0)
        
  