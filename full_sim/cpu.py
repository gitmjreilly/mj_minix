""" Jamet's CPU Class """

from register import Register, Register_With_History




######################################################################
def is16BitPositive(val) :

	if (val > 65535) :
		print "FATAL Error saw > 16 bit val in is16BitPositive!"
		sys.exit(1)
	

	if (val <= 32767) :
		return(1)
	else :
		return(0)
######################################################################

def special_write(self, value):
    self.value = value & 0xFFFF
    print "*** SPECIAL_WRITE ***"
    
class CPU(object):

    AND_OPC = 27
    BRANCH_OPC = 4
    BRANCH_FALSE_OPC = 12
    CS_FETCH_OPC = 43
    DI_OPC = 37
    DS_FETCH_OPC = 42
    DO_LIT_OPC = 2
    DROP_OPC = 7
    DUP_OPC = 19
    EI_OPC = 35
    EQUAL_OPC = 31
    ES_FETCH_OPC = 41
    FETCH_OPC = 9
    FROM_R_OPC = 14
    HALT_OPC = 3
    JSR_OPC = 10
    JSR_INT_OPC = 33
    K_SP_STORE_OPC = 47
    LESS_OPC = 5
    LONG_FETCH_OPC = 44
    LONG_STORE_OPC = 45
    # For use on simulator only.
    LONG_TYPE_STORE_OPC = 53
    L_VAR_OPC = 51
    MUL_OPC = 30
    NEG_OPC = 26
    NOP_OPC = 1
    OR_OPC = 28
    OVER_OPC = 22
    PLUS_OPC = 24
    PLUS_PLUS_OPC = 6
    POPF_OPC = 49
    PUSHF_OPC = 48
    R_FETCH_OPC = 18
    RET_OPC = 11
    RETI_OPC = 34
    RP_FETCH_OPC = 16
    RP_STORE_OPC = 17
    S_LESS_OPC = 50
    SLL_OPC = 15
    SP_FETCH_OPC = 20
    SP_STORE_OPC = 23
    SRA_OPC = 36
    SRL_OPC = 38
    STORE_OPC = 8
    STORE2_OPC = 52
    SUB_OPC = 25
    SWAP_OPC = 21
    SYSCALL_OPC = 46
    TO_DS_OPC = 40
    TO_ES_OPC = 39
    TO_R_OPC = 13
    UM_PLUS_OPC = 32
    XOR_OPC = 29

    def special_write(self, value):
        print "*** SPECIAL_WRITE ***"
        print "    CS:PC %4X:%4XX    old value : %4X new value : %4X" % (self.CS.value, self.PC.value,  self.INT_CTL_LOW.value, value)
        self.INT_CTL_LOW.value = value & 0xFFFF
    

    def __init__(self):
        """ Initialize with the base_type """
        self.PC = Register_With_History()
        
        self.DS = Register()
        self.CS = Register()
        self.ES = Register()
        
        self.PTOS = Register()
        self.RTOS = Register()

        self.PSP = Register()
        self.PSP.write(0xFF00)
        
        self.RSP = Register()
        self.RSP.write(0xFE00)

        self.INT_CTL_LOW = Register()
        self.INT_CTL_LOW.write = self.special_write

        self._interrupt_pin = 0
        
        self._address_history = 100 * [0x0000]
        
        self._break_point_list = dict()
        self._prev_break_point_address = 0x00000

        
        # set_opcodes()
        print "CPU has been initialized..."

    def set_memory_methods(self, 
        mem_read_method, 
        mem_write_method, 
        code_read_method, 
        mem_write_type):
        
        self.mem_read  = mem_read_method
        self.mem_write = mem_write_method
        self.code_read = code_read_method
        self.mem_write_type = mem_write_type
        
    def __str__(self):
        tmp =  "  No self here.\n"
        tmp = "CPU State : \n"
        tmp += "PC   : %04X  \n" % (self.PC.read() )
        tmp += "PTOS : %04X  RTOS: %04X\n" % (self.PTOS.read(), self.RTOS.read())
        tmp += "CS   : %04X  DS  : %04X ES   : %04X \n" % (self.CS.read(), self.DS.read(), self.ES.read())
        tmp += "PSP  : %04X  RSP : %04X \n" % (self.PSP.read(), self.RSP.read())
        tmp += "INT_CTL_LOW   : %04X \n" %self.INT_CTL_LOW.read()
        tmp += "Interrupt State : %d\n" % self._interrupt_pin
        return(tmp)
  
    def set_pc(self, val):
        self.PC.write(val)
       
    def set_break_point(self) :

        def cmp(a, b):
            if (a < b):
                return(-1)
            elif (a > b):
                return(1)
            else:
                return(0)
        
        
        s = raw_input("Enter PC (in hex) for breakpoint>")
        try:
            absolute_address = int(s.upper(), 16)    
        except:
            return
        
        self._break_point_list[absolute_address] = 1
        
        self._break_point_list.keys().sort(cmp)
 

    def clear_break_point(self) :
        
        PC = raw_input("Enter PC (in hex) for breakpoint>")
        try:
            PC = int(PC.upper(), 16)    
        except:
            return
        
        absolute_address  = PC

        if (self._break_point_list.has_key(absolute_address) ) :
            del(self._break_point_list[absolute_address])
        

    def show_break_points(self) :       
        for break_point in (self._break_point_list.keys()) :
            print "   %04X" % break_point

    def show_address_history(self):
        print "Address history : "
        for absolute_address in (self._address_history):
            print "  %08X" % (absolute_address)
        
    def step(self):
        absolute_address = (self.CS.read() << 4) + self.PC.read()     

        if ((self._interrupt_pin == 1) and ((self.INT_CTL_LOW.read() & 0x0001) == 1)):
            # We have NOT incremented the PC.  JSR_INT assumes it points at the 
            # instruction to execute when RETI is executed.
            status = self._do_instruction(CPU.JSR_INT_OPC)
        else:
            if (self._break_point_list.has_key(absolute_address) ) :
                if (self._prev_break_point_address != absolute_address):                
                    print "CPU encountered breakpoint at %08X" % (absolute_address)
                    self._prev_break_point_address = absolute_address
                    return(1)


            # This is the only place where we actually run an instruction.
            # So this is where the address history can be captured AND
            # it is the only place where we should act on break points
            self._address_history.append(absolute_address)
            self._address_history.pop(0)
        
            # Notice we use "code_read" here.  In this way, the simulator
            # can confirm that only code is being executed
            opcode = self.code_read(absolute_address)
            
            # Please note; all of the instructions assume the PC is pointing
            # at the location AFTER the current opcode
            self.PC.inc()
            status = self._do_instruction(opcode)
        return(status)
        
        
    def _do_instruction(self, opcode):
        # PC is assumed to point at the mem location after
        # the location where this opcode is stored.


        AND_OPC = 27
        BRANCH_OPC = 4
        BRANCH_FALSE_OPC = 12
        CS_FETCH_OPC = 43
        DI_OPC = 37
        DS_FETCH_OPC = 42
        DO_LIT_OPC = 2
        DROP_OPC = 7
        DUP_OPC = 19
        EI_OPC = 35
        EQUAL_OPC = 31
        ES_FETCH_OPC = 41
        FETCH_OPC = 9
        FROM_R_OPC = 14
        HALT_OPC = 3
        JSR_OPC = 10
        JSR_INT_OPC = 33
        K_SP_STORE_OPC = 47
        LESS_OPC = 5
        LONG_FETCH_OPC = 44
        LONG_STORE_OPC = 45
        # For use on simulator only.
        LONG_TYPE_STORE_OPC = 53
        L_VAR_OPC = 51
        MUL_OPC = 30
        NEG_OPC = 26
        NOP_OPC = 1
        OR_OPC = 28
        OVER_OPC = 22
        PLUS_OPC = 24
        PLUS_PLUS_OPC = 6
        POPF_OPC = 49
        PUSHF_OPC = 48
        R_FETCH_OPC = 18
        RET_OPC = 11
        RETI_OPC = 34
        RP_FETCH_OPC = 16
        RP_STORE_OPC = 17
        S_LESS_OPC = 50
        SLL_OPC = 15
        SP_FETCH_OPC = 20
        SP_STORE_OPC = 23
        SRA_OPC = 36
        SRL_OPC = 38
        STORE_OPC = 8
        STORE2_OPC = 52
        SUB_OPC = 25
        SWAP_OPC = 21
        SYSCALL_OPC = 46
        TO_DS_OPC = 40
        TO_ES_OPC = 39
        TO_R_OPC = 13
        UM_PLUS_OPC = 32
        XOR_OPC = 29

        # print "DEBUG PC is %x" % self.PC.read()
    
        scaledCS = self.CS.read() << 4
        scaledDS = self.DS.read() << 4
        scaledES = self.ES.read() << 4
        
        # This is the return status for this method
        # default is 0 which means OK
        return_status = 0

        if (opcode == AND_OPC):
            self.PSP.dec()
            self.PTOS.write(self.PTOS.read() & self.mem_read(scaledDS + self.PSP.read()))
            return(return_status)
        

        if (opcode == BRANCH_OPC):
            self.PC.write(self.code_read(self.PC.read() + scaledCS))
            return(return_status)
        

        if (opcode == BRANCH_FALSE_OPC):
            if (self.PTOS.read() == 0):
                # Consume the boolean and update PTOS
                self.PSP.dec()
                literal = self.mem_read(scaledDS + self.PSP.read())
                self.PTOS.write(literal)
                self.PC.write(self.code_read(self.PC.read() + scaledCS))
                return(return_status)
            
            else:
                self.PSP.dec()
                literal = self.mem_read(scaledDS + self.PSP.read())
                self.PTOS.write(literal)
                self.PC.inc()
                return(return_status)
            
        

        if (opcode == CS_FETCH_OPC):
            self.mem_write(scaledDS + self.PSP.read(), self.PTOS.read())
            self.PSP.inc()
            self.PTOS.write(self.CS.read())
            return(return_status)
        

        if (opcode == DI_OPC):
            self.INT_CTL_LOW.write(self.INT_CTL_LOW.read() & 0xFFFE)
            return(return_status)
        

        if (opcode == DO_LIT_OPC):
            # Write the self.PTOS To location where self.PSP points
            self.mem_write(scaledDS + self.PSP.read(), self.PTOS.read())
            self.PSP.inc()
            literal = self.code_read(scaledCS + self.PC.read())
            self.PTOS.write(literal)
            self.PC.inc()
            return(return_status)
        

        if (opcode == DROP_OPC):
            self.PSP.dec()
            literal = self.mem_read(scaledDS + self.PSP.read())
            self.PTOS.write(literal)
            return(return_status)
        

        if (opcode == DS_FETCH_OPC):
            self.mem_write(scaledDS + self.PSP.read(), self.PTOS.read())
            self.PSP.inc()
            self.PTOS.write(self.DS.read())
            return(return_status)
        

        if (opcode == DUP_OPC):
            self.mem_write(scaledDS + self.PSP.read(), self.PTOS.read())
            self.PSP.inc()
            return(return_status)
        

        if (opcode == EI_OPC):
            self.INT_CTL_LOW.write(self.INT_CTL_LOW.read() | 0x0001)
            return(return_status)
        


        if (opcode == EQUAL_OPC):
            self.PSP.dec()
            if (self.PTOS.read() == self.mem_read(self.PSP.read() + scaledDS)):
                self.PTOS.write(0xFFFF)
            
            else:
                self.PTOS.write(0x0000)
            
            return(return_status)
        

        if (opcode == ES_FETCH_OPC):
            self.mem_write(scaledDS + self.PSP.read(), self.PTOS.read())
            self.PSP.inc()
            self.PTOS.write(self.ES.read())
            return(return_status)
        

        if (opcode == FETCH_OPC):
            self.PTOS.write(self.mem_read(scaledDS + self.PTOS.read()))
            return(return_status)
        

        if (opcode == FROM_R_OPC):
            self.mem_write(self.PSP.read() + scaledDS , self.PTOS.read())
            self.PSP.inc()
            self.PTOS.write(self.RTOS.read())
            self.RSP.dec()
            self.RTOS.write(self.mem_read(self.RSP.read() + scaledDS))
            return(return_status)
        
        if (opcode == HALT_OPC):
            print "Saw halt instruction"
            return_status = 1
            return(return_status)

        
        if (opcode == JSR_OPC):
            self.mem_write(self.RSP.read() + scaledDS , self.RTOS.read())
            self.RSP.inc()
            self.RTOS.write(self.PC.read() + 1)
            self.PC.write(self.code_read(self.PC.read() + scaledCS))
            return(return_status)
        


        if (opcode == JSR_INT_OPC):
            H = self.RSP.read()

            self.mem_write(self.RSP.read() + scaledDS , self.DS.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , self.CS.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , self.ES.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , self.PSP.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , self.PTOS.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , self.PC.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , self.INT_CTL_LOW.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , H)

            self.RSP.inc()
            self.INT_CTL_LOW.write(self.INT_CTL_LOW.read() & 0xFFFE)

            self.PC.write(0xFD00)
            self.CS.write(0x0000)
            return(return_status)
          
        
        if (opcode == K_SP_STORE_OPC):
            self.DS.write(0x0000)
            self.PSP.write(self.PTOS.read())
            return(return_status)
        

        if (opcode == L_VAR_OPC):
            self.mem_write(scaledDS + self.PSP.read(), self.PTOS.read())
            self.PSP.inc()

            literal = self.code_read(scaledDS + self.PC.read())
            self.PTOS.write(literal + self.RTOS.read())
            self.PC.inc()

            return(return_status)
        

        if (opcode == LESS_OPC):
            # usage a b LESS
            self.PSP.dec()
            self.PTOS.read()
            a = self.mem_read(self.PSP.read() + scaledDS) 
            b = self.PTOS.read()


            self.PTOS.write(0)
            if ((is16BitPositive(a) and (is16BitPositive(b)))):
                if (a < b): 
                    self.PTOS.write(0xFFFF) 
                
                return(return_status) 
            
                
            if ((not is16BitPositive(a) and (is16BitPositive(b)))):
                self.PTOS.write(0xFFFF) 
                return(return_status) 
            
                
            if ((is16BitPositive(a) and (not is16BitPositive(b)))):
                return(return_status) 
            
                
            if ((not is16BitPositive(a) and (not is16BitPositive(b)))):
                if (a < b): self.PTOS.write(0xFFFF)  
                return(return_status)
                 
        

        if (opcode == LONG_FETCH_OPC):
            self.PTOS.write(self.mem_read(scaledES + self.PTOS.read()))
            return(return_status)
        

        if (opcode == LONG_STORE_OPC):
            self.PSP.dec()
            literal = self.mem_read(scaledDS + self.PSP.read())
            self.mem_write(self.PTOS.read() + scaledES , literal)
            self.PSP.dec()
            self.PTOS.write( self.mem_read(self.PSP.read() + scaledDS) )
            return(return_status)
        
            
        if (opcode == LONG_TYPE_STORE_OPC):
            self.PSP.dec()
            type = self.mem_read(scaledDS + self.PSP.read())
            address = self.PTOS.read()
            self.mem_write_type(address + scaledES , type)
            self.PSP.dec()
            self.PTOS.write(self.mem_read(self.PSP.read() + scaledDS) )
            return(return_status)
        
            
        if (opcode == MUL_OPC):
            self.PSP.dec()
            self.PTOS.write(self.PTOS.read() * self.mem_read(scaledDS + self.PSP.read()))
            return(return_status)
        

        if (opcode == NEG_OPC):
            if (is16BitPositive(self.PTOS.read())):
                self.PTOS.write(0x0000)
            
            else:
                self.PTOS.write(0xFFFF)
            
            return(return_status)
        

        if (opcode == NOP_OPC):
            return(return_status)
        

        if (opcode == OR_OPC):
            self.PSP.dec()
            self.PTOS.write(self.PTOS.read() | self.mem_read(scaledDS + self.PSP.read()))
            return(return_status)
        

        if (opcode == OVER_OPC):
            self.mem_write(self.PSP.read() + scaledDS , self.PTOS.read())
            self.PTOS.write( self.mem_read((self.PSP.read() - 1 + scaledDS))  )
            self.PSP.inc()
            return(return_status)
        

        if (opcode == PLUS_OPC):
            self.PSP.dec()
            self.PTOS.write(self.PTOS.read() + self.mem_read(scaledDS + self.PSP.read()))
            return(return_status)
        

        if (opcode == PLUS_PLUS_OPC):
            literal = self.mem_read(scaledDS + self.PTOS.read()) + 1
            self.mem_write(self.PTOS.read() + scaledDS , literal)
            self.PSP.dec()
            return(return_status)
        

        if (opcode == POPF_OPC):
            self.INT_CTL_LOW.write(self.PTOS.read())
            self.PSP.dec()

            self.PTOS.write(self.mem_read(scaledDS + self.PSP.read()))
            self.PSP.dec()
            return(return_status)
        

        if (opcode == PUSHF_OPC):
            # Write the self.PTOS To location where self.PSP points
            self.mem_write(scaledDS + self.PSP.read(), self.PTOS.read())
            self.PSP.inc()

            self.PTOS.write(self.INT_CTL_LOW.read())

            return(return_status)
        

        if (opcode == R_FETCH_OPC):
            self.mem_write(self.PSP.read() + scaledDS, self.PTOS.read() )
            self.PSP.inc()
            self.PTOS.write(self.RTOS.read())
            return(return_status)
        

        if (opcode == RET_OPC):
            self.PC.write(self.RTOS.read())
            self.RSP.dec()
            self.RTOS.write( self.mem_read(self.RSP.read() + scaledDS) )
            return(return_status)
        

        if (opcode == RETI_OPC):
            self.RSP.dec()

            H = self.mem_read( self.RSP.read() + scaledDS) 

            self.RSP.dec()
            self.INT_CTL_LOW.write(self.mem_read(self.RSP.read() + scaledDS))

            self.RSP.dec()
            self.PC.write(self.mem_read(self.RSP.read() + scaledDS))

            self.RSP.dec()
            self.PTOS.write(self.mem_read(self.RSP.read() + scaledDS))

            self.RSP.dec()
            self.PSP.write(self.mem_read(self.RSP.read() + scaledDS))

            self.RSP.dec()
            self.ES.write(self.mem_read(self.RSP.read() + scaledDS))

            self.RSP.dec()
            self.CS.write(self.mem_read(self.RSP.read() + scaledDS))

            self.RSP.dec()
            self.DS.write(self.mem_read(self.RSP.read() + scaledDS))

            self.RSP.write(H)

            return(return_status)
        

        if (opcode == RP_FETCH_OPC):
            self.mem_write(self.PSP.read() + scaledDS , self.PTOS.read())
            self.PTOS.write(self.RTOS.read())
            self.PSP.inc()
            return(return_status)
        

        if (opcode == RP_STORE_OPC):
            self.RSP.write(self.PTOS.read())
            self.PSP.dec()
            self.PTOS.write( self.mem_read( self.PSP.read() + scaledDS) )
            return(return_status)
        

        if (opcode == S_LESS_OPC):
            # usage a b S_LESS
            self.PSP.dec()
            self.PTOS.read()
            a = self.mem_read(self.PSP.read() + scaledDS) 
            b = self.PTOS.read()


            # OK with signed vals
            self.PTOS.write(0)
            if ((is16BitPositive(a) and (is16BitPositive(b)))):
                if (a < b): 
                    self.PTOS.write(0xFFFF) 
                
                return(return_status) 
            
                
            # This code was returning 0; seems wrong given this combination
            if ((not is16BitPositive(a) and (is16BitPositive(b)))):
                self.PTOS.write(0x0000) 
                self.PTOS.write(0xFFFF) 
                return(return_status) 
            
                
            if ((is16BitPositive(a) and (not is16BitPositive(b)))):
                return(return_status) 
            
                
            if ((not is16BitPositive(a) and (not is16BitPositive(b)))):
                if (a < b): self.PTOS.write(0xFFFF)  
                return(return_status)
            

            printf("FATAL Error in S_LESS a is %X b is %X\n", a, b)
            exit(1)
                
        
        if (opcode == SLL_OPC):
            self.PTOS.write((self.PTOS.read() << 1) & 0xFFFF)
            return(return_status)
        

        if (opcode == SP_FETCH_OPC):
            self.mem_write(self.PSP.read() + scaledDS , self.PTOS.read())
            self.PTOS.write(self.PSP.read())
            self.PSP.inc()
            return(return_status)
        

        if (opcode == SP_STORE_OPC):
            self.PSP.write(self.PTOS.read())
            return(return_status)
        

        if (opcode == SRA_OPC):
            signBit = self.PTOS.read() & 0x8000
            self.PTOS.write((self.PTOS.read() >> 1) | signBit)
            return(return_status)
        

        if (opcode == SRL_OPC):
            self.PTOS.write((self.PTOS.read() >> 1))
            return(return_status)
        

        if (opcode == STORE_OPC):
            self.PSP.dec()
            literal = self.mem_read(scaledDS + self.PSP.read())
            self.mem_write(self.PTOS.read() + scaledDS , literal)
            self.PSP.dec()
            self.PTOS.write( self.mem_read(self.PSP.read() + scaledDS) )
            return(return_status)
        
            
        if (opcode == STORE2_OPC):
            self.PSP.dec()

            val = self.PTOS.read()
            # This addr is only the 16 bit offset !!!
            # which is why we have to add the DS offset
            addr = self.mem_read(scaledDS + self.PSP.read())
            addr += scaledDS

            self.mem_write(addr , val)
            self.PSP.dec()

            self.PTOS.write( self.mem_read(self.PSP.read() + scaledDS) )
            return(return_status)
        
            
        if (opcode == SUB_OPC):
            self.PSP.dec()
            self.PTOS.write(self.mem_read(scaledDS + self.PSP.read()) - self.PTOS.read())
            return(return_status)
        

        if (opcode == SWAP_OPC):
            literal = self.PTOS.read()
            self.PTOS.write( self.mem_read(self.PSP.read() - 1 + scaledDS) )
            addr = (self.PSP.read() - 1) + scaledDS
            self.mem_write(addr, literal)
            return(return_status)
        

        if (opcode == SYSCALL_OPC):
            H = self.RSP.read()

            self.mem_write(self.RSP.read() + scaledDS , self.DS.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , self.CS.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , self.ES.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , self.PSP.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , self.PTOS.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , self.PC.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , self.INT_CTL_LOW.read())

            self.RSP.inc()
            self.mem_write(self.RSP.read() + scaledDS , H)

            self.RSP.inc()
            self.INT_CTL_LOW.write(self.INT_CTL_LOW.read() & 0xFFFE)

            self.PC.write(0xFD02)
            self.CS.write(0x0000)
            return(return_status)
        

        if (opcode == TO_DS_OPC):
            self.DS.write(self.PTOS.read())
            self.PSP.dec()
            self.PTOS.write(self.mem_read(scaledDS + self.PSP.read()) - self.PTOS.read())
            return(return_status)
        

        if (opcode == TO_ES_OPC):
            self.ES.write(self.PTOS.read())
            self.PSP.dec()
            self.PTOS.write(self.mem_read(scaledDS + self.PSP.read()) - self.PTOS.read())
            return(return_status)
        

        if (opcode == TO_R_OPC):
            self.mem_write(self.RSP.read() + scaledDS , self.RTOS.read())
            self.RSP.inc()
            self.RTOS.write(self.PTOS.read())
            self.PSP.dec()
            self.PTOS.write( self.mem_read(self.PSP.read() + scaledDS) )
            return(return_status)
        

        if (opcode == UM_PLUS_OPC):
            literal = self.PTOS.read() + self.mem_read(self.PSP.read() -1 + scaledDS) 
            self.PTOS.write((literal & 0x10000) >> 16)
            self.mem_write(self.PSP.read() - 1 + scaledDS, literal & 0xFFFF)
            return(return_status)
        

        if (opcode == XOR_OPC):
            self.PSP.dec()
            self.PTOS.write(self.mem_read(scaledDS + self.PSP.read()) ^ self.PTOS.read())
            return(return_status)
        

        print "FATAL Error - unknown opc %X at addr %X\n" % (opcode, self.PC.read() - 1)

    def set_interrupt_input(self, interrupt_input):
        self._interrupt_pin = interrupt_input
        
  