#
# Michael's MIC - 1 Microassembler
#
# $Header: I:/MIC1-Microassembler/RCS/mic1-asm.pl 1.8 2006/04/08 22:40:12 Administrator Exp Administrator $
#
# $Revision: 1.8 $
#
# $Locker: Administrator $
#
# $Log: mic1-asm.pl $
# Revision 1.8  2006/04/08 22:40:12  Administrator
# First attempt at adding carry to assembler as BIT 36 in control word.
#
# Revision 1.7  2006/03/31 11:45:48  Administrator
# Added ALU constant for A_XOR_B.
#
# Revision 1.6  2006/03/25 20:20:54  Administrator
# Interim Checkin.  Found bug with conditional jump destinations.  Mem
# Allocation table was not being set.  I also modified IncLC to not pre inc LC
# before checking if mem is allocated.  This fixes conditional problem but it
# may create others.
#
# Revision 1.5  2006/03/23 11:02:27  Administrator
# Added aliases for :
# 	psp is sp
# 	ptos is tos
# 	rsp is lv
# 	rtos is cpp
# 	tmp1 is opc
#
# Revision 1.4  2006/03/23 10:43:47  Administrator
# Long overdue checkin.
# 	Corrected typo in JMP Names.
# 	Renamed some sub's
# 	Added check for case when next address assignment
# 		is attempted after an explicit jump was assembled.
# 	Changed ALU constants to match h/w
# 	Changed MAX_LC to actual val, 511.
#
# Revision 1.3  2006/02/20 23:20:00  Administrator
# Added VHDL output.
# Added cmd line args for input, output and log.
#
# Revision 1.2  2006/02/19 22:34:47  Administrator
# Fixed 3 bugs:
# 	Instruction after "UPPER" had no next address.
# 	JMPN next address was wrong.
# 	CONDLOW and CONDHIGH - 1st instr after these psuedo ops had
# 		no next address.
#
# Revision 1.1  2006/02/19 19:02:18  Administrator
# Initial revision
#
#

#
use strict;

###############################################################################
#
# External Modules:
#
use Getopt::Long;
###############################################################################



###############################################################################
#
# Global Constants
#
my $MAX_LC = 511;

my $START_STATE = 1;
my $SAW_INSTRUCTION_STATE = 2;
my $SAW_OPCODE_STATE = 3;
my $SAW_CONDHIGH_STATE = 4;
my $SAW_CONDLOW_STATE = 5;
my $SAW_UPPER_STATE = 6;
my $SAW_PREALLOCATED_OPCODE_STATE = 7;

my @StateNames;
	$StateNames[1] = "Start";
	$StateNames[2] = "Instruction";
	$StateNames[3] = "Opcode";
	$StateNames[4] = "CondHigh";
	$StateNames[5] = "CondLow";
	$StateNames[6] = "Upper";
	$StateNames[7] = "Preallocated";

my %ALUCommands;
	$ALUCommands{'A'} = 0;
	$ALUCommands{'B'} = 1;
	$ALUCommands{'NOT_A'} = 2;
	$ALUCommands{'NOT_B'} = 3;

	$ALUCommands{'ADD'} = 4;
	$ALUCommands{'ADD_PLUS_1'} = 4;
	$ALUCommands{'INCA'} = 6;
	$ALUCommands{'INCB'} = 7;

	$ALUCommands{'B_MINUS_A'} = 8;
	$ALUCommands{'DECB'} = 9;
	$ALUCommands{'MINUS_A'} = 10;
	$ALUCommands{'A_AND_B'} = 11;

	$ALUCommands{'A_OR_B'} = 12;
	$ALUCommands{'ZERO'} = 13;
	$ALUCommands{'ONE'} = 14;
	$ALUCommands{'MINUS_1'} = 15;

	$ALUCommands{'DECA'} = 16;

	$ALUCommands{'A_XOR_B'} = 17;
	$ALUCommands{'A_MINUS_B'} = 18;
	$ALUCommands{'A_MUL_B'} = 19;
	$ALUCommands{'SRL_A'} = 20;
	$ALUCommands{'S_LESS'} = 21;

my %ShifterCommands;
	$ShifterCommands{'SLL8'} = 1;
	$ShifterCommands{'SRA1'} = 2;
	$ShifterCommands{'SLL1'} = 3;
	
	

###############################################################################


###############################################################################
#
# Global Variables
#
my	$InstructionList;
my %SymbolTable;
my $LowerLC = 0;
my $UpperLC = ($MAX_LC + 1) / 2;
my $PreallocatedLC;

my $State = $START_STATE;

my $PreviousLC;

#
# Used to preserve State across calls to ProcessLine
#
my $CondLowLC;
my $CondHighLC;


my $LineNum;

#
# IntermediateAssembly is an array indexed by assembled memory 
# locations.  Value is a ref to a hash with settings for all control word 
# fields. e.g. $IntermediateAssembly[0]->{'LOAD_SP'} = 1;
#
my @IntermediateAssembly;

my @MemoryAllocationTable;
###############################################################################


###############################################################################
sub Usage {
	printf("$0 -srcfile SrcFile -objfile ObjFile -logfile LogFile ..\n");
	printf("  -opcodemapfile OpcodeMapFile -symboltablefile OutputSymbolFile \n");
}
###############################################################################


###############################################################################
#
# sub trim
# Trim Leading and trailing spaces and return the result in the passed in arg.
#
sub trim {
	my $string = $_[0];

	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	$_[0] = $string;
}
###############################################################################


###############################################################################
#
# sub Error
#
sub Error {
	my $string = $_[0];

	printf(LOGFILE "ERROR $string\n");
}
###############################################################################


###############################################################################
#
#			IncLC($UpperLC);
#
sub IncLC {
my $LC = $_[0];

	printf(LOGFILE "incing LC:$LC...\n");
#	$LC++;
   while ($LC < $MAX_LC) {
   	if ($MemoryAllocationTable[$LC] == 0) { last; }
   	$LC++;
   }
   
   if ($LC == $MAX_LC) {
   	Error("Tried to inc LC, but ran out of space.");
   }
   printf(LOGFILE "  Incd LC is $LC\n");
   $_[0] = $LC;		   
}
###############################################################################


###############################################################################
#
#
#
sub LoadOpcodeMap {
	printf(LOGFILE "Entered LoadOpcodeMap\n");
	while (chomp(my $Line = <OPCODEMAPFILE>)) {
		if ($Line =~ /^\s*#|^\s*$/) { next; }
		my @Stuff = split(' ', $Line);
		my $OpcodeName = $Stuff[0];
		my $OpcodeVal = $Stuff[1];
		printf(LOGFILE "in LoadOpcodeMap adding $OpcodeName to symtable\n");
		AddToSymbolTable($OpcodeName, $OpcodeVal);	
		$MemoryAllocationTable[$OpcodeVal] = 1;
	}	
	printf(LOGFILE "Leaving LoadOpcodeMap\n");
}
###############################################################################



###############################################################################
sub ParseLine {
my $OriginalLine = $_[0];
my $LineNum = $_[1];

my $ParsedLine;

	$ParsedLine->{'OriginalLine'} = $OriginalLine;
	$ParsedLine->{'LineNum'} = $LineNum;

	$ParsedLine->{'Instructions'} = \();

	$ParsedLine->{'IsOpcode'}   = 0;
	$ParsedLine->{'IsUpper'}    = 0;
	$ParsedLine->{'IsInstruction'}    = 0;
	$ParsedLine->{'IsCondHigh'} = 0;
	$ParsedLine->{'IsCondLow'}  = 0;
	$ParsedLine->{'IsComment'}  = 0;

	if ($OriginalLine =~ /^\s*$|^\s*#/) {
		$ParsedLine->{'IsComment'} = 1;
		return($ParsedLine);
	}

	my @InstructionList;

	#
	# Remove Comments
	#
	my @Stuff;
	@Stuff = split('#', $OriginalLine);
	$OriginalLine = $Stuff[0];


	#
	# At this point, the only thing left should be ';' delimited Instructions
	# If the instruction field is a psuedo op:
	#		 (OPCODE, CONDHIGH, CONDLOW, UPPER)
	# there should NOT be additional instructions on the line.
	#
	@Stuff = split(';', $OriginalLine);
	my $PsuedoOpCount = 0;
	foreach my $InstructionString (@Stuff) {

		(my $Instruction, my $Arg) = split(' ', $InstructionString, 2); 

		if ($Instruction eq "OPCODE") {
			$PsuedoOpCount++;
			$ParsedLine->{'IsOpcode'} = 1;
		}
		elsif ($Instruction eq "UPPER") {
			$PsuedoOpCount++;
			$ParsedLine->{'IsUpper'} = 1;
		}
		elsif ($Instruction eq "CONDHIGH") {
			$PsuedoOpCount++;
			$ParsedLine->{'IsCondHigh'} = 1;
		}
		elsif ($Instruction eq "CONDLOW") {
			$PsuedoOpCount++;
			$ParsedLine->{'IsCondLow'} = 1;
		}
		else {
			$ParsedLine->{'IsInstruction'} = 1;
		}

		my %Record;
		$Record{'Instruction'} = $Instruction;
		$Record{'Arg'} = $Arg;

		push(@InstructionList, \%Record);
	}

	$ParsedLine->{'Instructions'} = \@InstructionList;

	if	( 	($PsuedoOpCount > 1) || 
			($ParsedLine->{'IsInstruction'} && $PsuedoOpCount == 1) ) {
			Error("Too many psuedo ops on line");
	}

	return($ParsedLine);
}
###############################################################################


###############################################################################
sub GetMatchedPairOfAddresses {

   my $LowerLC = 255;
   
   while (1) {
   	if	(	($MemoryAllocationTable[$LowerLC] == 0) &&
   			($MemoryAllocationTable[$LowerLC + 256] == 0)) {
   			my @Stuff;
   			$Stuff[0] = $LowerLC;
   			$Stuff[1] = $LowerLC + 256;
   			return(\@Stuff);
   	}
   	$LowerLC--;
   }
	Error("Could not get a matched pair of addresses.");
	exit (1);
   
}
###############################################################################


###############################################################################
#
#			AddToSymbolTable($Symbol, $Value);
#
sub AddToSymbolTable {
my $Symbol = $_[0];
my $Value = $_[1];

	if (defined($SymbolTable{$Symbol})) {
		Error("Line $LineNum Symbol $Symbol already in Symbol Table");
	}

	$SymbolTable{$Symbol} = $Value;
}
###############################################################################


###############################################################################
#
# AssembleControlWord($ParsedLine, $LC);
#
# Only call if we know this is an instruction line!
# One instruction line consists of one or more micro instructions and will 
# fill exactly one control store location, $LC.
#
#
sub AssembleControlWord {
my $ParsedLine = $_[0];
my $LC = $_[1];

	my $ControlWord;

	printf(LOGFILE "    Assembling Control Word:\n");
	printf(LOGFILE "       [$ParsedLine->{'OriginalLine'}] LC : [$LC]\n");

	$MemoryAllocationTable[$LC] = 1;

	foreach my $InstructionRecord (@{$ParsedLine->{'Instructions'}}) {
		my $Instruction = $InstructionRecord->{'Instruction'};
		my $Arg         = $InstructionRecord->{'Arg'};

   	#
   	# Process instructions which enable register output onto
		# the b bus.
   	#
   	if	($Instruction eq "ena_pc")		{ $ControlWord->{'B'} = 1; }
   	elsif ($Instruction eq "ena_mbr")	{ $ControlWord->{'B'} = 2; }
   	elsif ($Instruction eq "ena_es")	{ $ControlWord->{'B'} = 3; }

		# Parameter stack pointer regs
   	elsif ($Instruction eq "ena_sp")		{ $ControlWord->{'B'} = 4; }
   	elsif ($Instruction eq "ena_psp")	{ $ControlWord->{'B'} = 4; }

   	elsif ($Instruction eq "ena_lv")		{ $ControlWord->{'B'} = 5; }
   	elsif ($Instruction eq "ena_cpp")	{ $ControlWord->{'B'} = 6; }
   	elsif ($Instruction eq "ena_rsp")	{ $ControlWord->{'B'} = 5; }
   	elsif ($Instruction eq "ena_rtos")	{ $ControlWord->{'B'} = 6; }

   	elsif ($Instruction eq "ena_tos")	{ $ControlWord->{'B'} = 7; }
   	elsif ($Instruction eq "ena_ptos")	{ $ControlWord->{'B'} = 7; }

   	elsif	($Instruction eq "ena_cs")		{ $ControlWord->{'B'} = 8; }

   	elsif	($Instruction eq "ena_mdr")	{ $ControlWord->{'B'} = 9; }

   	elsif ($Instruction eq "ena_intctl"){ $ControlWord->{'B'} = 10; }

   	elsif ($Instruction eq "ena_ds"){ $ControlWord->{'B'} = 11; }

   	#
   	# Process Memory Control instructions
   	#
   	elsif ($Instruction eq "rd")			{ $ControlWord->{'READ'}  = "1";	}
   	elsif ($Instruction eq "wr")			{ $ControlWord->{'WRITE'} = "1";	}
   	elsif ($Instruction eq "fetch")		{ $ControlWord->{'FETCH'} = "1";	}
   
   	#
   	# Process instructions which load values from C Bus
   	#
   	elsif ($Instruction eq "load_h")		{ $ControlWord->{'LOAD_H'}   = "1"; }
   	elsif ($Instruction eq "load_opc")	{ $ControlWord->{'LOAD_OPC'} = "1"; }
   	elsif ($Instruction eq "load_tmp1")	{ $ControlWord->{'LOAD_OPC'} = "1"; }
   	elsif ($Instruction eq "load_intctl_low")	{ $ControlWord->{'LOAD_OPC'} = "1"; }

   	elsif ($Instruction eq "load_lv")	{ $ControlWord->{'LOAD_LV'}  = "1"; }
   	elsif ($Instruction eq "load_rsp")	{ $ControlWord->{'LOAD_LV'}  = "1"; }
   	elsif ($Instruction eq "load_cpp")	{ $ControlWord->{'LOAD_CPP'} = "1"; }
   	elsif ($Instruction eq "load_rtos")	{ $ControlWord->{'LOAD_CPP'} = "1"; }

   	elsif ($Instruction eq "load_sp")	{ $ControlWord->{'LOAD_SP'}  = "1"; }
   	elsif ($Instruction eq "load_psp")	{ $ControlWord->{'LOAD_SP'}  = "1"; }
   	elsif ($Instruction eq "load_tos")	{ $ControlWord->{'LOAD_TOS'} = "1"; }
   	elsif ($Instruction eq "load_ptos")	{ $ControlWord->{'LOAD_TOS'} = "1"; }


   	elsif ($Instruction eq "load_pc")	{ $ControlWord->{'LOAD_PC'}  = "1"; }
   	elsif ($Instruction eq "load_mdr")	{ $ControlWord->{'LOAD_MDR'} = "1"; }
   	elsif ($Instruction eq "load_mar")	{ $ControlWord->{'LOAD_MAR'} = "1"; }

   	elsif ($Instruction eq "load_es")	{ $ControlWord->{'LOAD_ES'} = "1"; }
   	elsif ($Instruction eq "load_cs")	{ $ControlWord->{'LOAD_CS'} = "1"; }
   	elsif ($Instruction eq "load_ds")	{ $ControlWord->{'LOAD_DS'} = "1"; }
   
		#
		# Memory access instructions
		#
   	elsif ($Instruction eq "write")	{ $ControlWord->{'WRITE'} = "1"; }
   	elsif ($Instruction eq "read")	{ $ControlWord->{'READ'}  = "1"; }
   	elsif ($Instruction eq "fetch")	{ $ControlWord->{'FETCH'} = "1"; }
   	elsif ($Instruction eq "use_es")	{ $ControlWord->{'USE_ES'} = "1"; }

		#
		# Process goto instructions (i.e. those which set "JAM" bits)
		#
		elsif ($Instruction eq "goto") {
			if (! defined($SymbolTable{$Arg})) {
				Error("[$Arg] not in SymbolTable $ParsedLine->{'OriginalLine'} $ParsedLine->{'LineNum'}");
			}
			$ControlWord->{'NEXT_ADDRESS'} = $SymbolTable{$Arg};
		}

		elsif ($Instruction eq "gotombr") {
			$ControlWord->{'JMPC'} = 1;
			$ControlWord->{'NEXT_ADDRESS'} = 0;
		}

		elsif (	($Instruction eq "jmpz") ||
					($Instruction eq "jmpn") ||
					($Instruction eq "jmpy")	) {

			printf(LOGFILE "Found conditional jmp [ $Instruction]\n");

			if ($Instruction eq "jmpz") { $ControlWord->{'JMPZ'} = 1; };
			if ($Instruction eq "jmpn") { $ControlWord->{'JMPN'} = 1; };
			if ($Instruction eq "jmpy") { $ControlWord->{'JMPY'} = 1; };

			#
			# Get the 2 symbols representing branch locations.
			# The 1st (true) one is an upper.  The 2nd (false) one is a lower.
			#
			my @Stuff = split(' ', $Arg);
			my $HighSymbol = $Stuff[0];
			my $LowSymbol  = $Stuff[1];

			#
			# Get a pair of addresses to be used for the symbols above.
			# They must be separated by 256 in the lower and upper halves of
			# the control store.
			#
			my $PairedAddresses = GetMatchedPairOfAddresses();
			my $LowerAddress = $PairedAddresses->[0];
			my $UpperAddress = $PairedAddresses->[1];
			#
			# These addresses are now allocated so no other instructions use their space
			#
			printf(LOGFILE "Marking (as allocated) addresses $LowerAddress $UpperAddress");
			# Note that the locations reserved for the JMP 
			# addresses are allocated as a result of the jmpX instructions
			# so only CONDHIGH and CONDLOW instructions are placed there.
			#
			$MemoryAllocationTable[$LowerAddress]   = 1;
			$MemoryAllocationTable[$UpperAddress] = 1;

			$ControlWord->{'NEXT_ADDRESS'} = $LowerAddress;
			printf(LOGFILE "ControlWord Nextaddress is $ControlWord->{'NEXT_ADDRESS'}\n");

			AddToSymbolTable($HighSymbol, $UpperAddress);
			AddToSymbolTable($LowSymbol,  $LowerAddress);
		}

   	#
   	# Process ALU instruction
   	#
   	elsif ($Instruction eq "setalu") {
   		if (! defined($ALUCommands{$Arg})) {
   			Error("ERROR Unknown ALU Command [$Arg].  Exiting.\n");
   		}
   		$ControlWord->{'ALU'} = $ALUCommands{$Arg}
   	}

   	#
   	# Process shifter instruction
   	#
   	elsif ($Instruction eq "setshifter") {
   		if (! defined($ShifterCommands{$Arg})) {
   			Error("ERROR Unknown Shifter Command [$Arg].  Exiting.\n");
   			exit(1);
   		}
   		$ControlWord->{'SHIFTER'} = $ShifterCommands{$Arg}
   	}

		#
		# "micronop" is a Jamet created micro op used to create
		# an instruction which does nothing.
		#
		elsif ($Instruction eq "micronop") {
		}


		else {
			Error("Unknown instr [$Instruction] on line $ParsedLine->{'LineNum'}.");
		}
   	
	}  

	$ControlWord->{'OriginalLine'} = $ParsedLine->{'OriginalLine'};
	$IntermediateAssembly[$LC] = $ControlWord;

}
###############################################################################


###############################################################################
#
# Handle Line.  This sub handles the transition from one FSM state to the next.
#
sub ProcessLine {
	my $ParsedLine = $_[0];

	if ($ParsedLine->{'IsComment'}) { return; }

	printf(LOGFILE " ======================================================\n");
	printf(LOGFILE " Processing [$ParsedLine->{'OriginalLine'}]\n");
	printf(LOGFILE " Processing Line Num [$ParsedLine->{'LineNum'}]\n");
	printf(LOGFILE "   State is $StateNames[$State]\n");

	if ($State == $START_STATE) {
		if ($ParsedLine->{'IsUpper'}) {
			my $Label = $ParsedLine->{'Instructions'}->[0]->{'Arg'};
			AddToSymbolTable($Label, $UpperLC);
			$State = $SAW_UPPER_STATE;
		}
		elsif ($ParsedLine->{'IsOpcode'}) {
			my $Label = $ParsedLine->{'Instructions'}->[0]->{'Arg'};
			
			#
			# Check to see if this opcode has already been defined.  If so
			# we assume it is a preallocated opcode and NOT a duplicate definition
			# (though it's possible!).
			#	
			printf(LOGFILE " saw an opcode\n");
			if (defined($SymbolTable{$Label})) { 
				$State = $SAW_PREALLOCATED_OPCODE_STATE;	
				$PreallocatedLC = $SymbolTable{$Label};
				printf(LOGFILE "Saw preallocated symbol $Label.  Its LC is $PreallocatedLC\n");
			}
			else {
				AddToSymbolTable($Label, $LowerLC);
				$State = $SAW_OPCODE_STATE;
			}
		}
		else {
			Error("Expected \"OPCODE\" or \"UPPER\".  Got [$ParsedLine->{'OriginalLine'}]");
		}
	}

	elsif ($State == $SAW_UPPER_STATE) {
		if ($ParsedLine->{'IsInstruction'}) {
			AssembleControlWord($ParsedLine, $UpperLC);
			$PreviousLC = $UpperLC;
			printf(LOGFILE "Setting PreviousLC to $PreviousLC for use by the next instruction\n");
			IncLC($UpperLC);
			printf(LOGFILE "UpperLC has been incd to $UpperLC\n");
			$State = $SAW_INSTRUCTION_STATE;
		}
		else {
			Error("Expected an instr after UPPER opcode.  Got [$ParsedLine->{'OriginalLine'}]");
		}
	}

	elsif ($State == $SAW_OPCODE_STATE) {
		if ($ParsedLine->{'IsInstruction'}) {
			AssembleControlWord($ParsedLine, $LowerLC);
			$PreviousLC = $LowerLC;
			printf(LOGFILE "Setting PreviousLC to LowerLC: $LowerLC\n");
			IncLC($LowerLC);
			printf(LOGFILE "LowerLC after Inc is $LowerLC\n");
			$State = $SAW_INSTRUCTION_STATE;
		}
		else {
			Error("Expected an instr after OPCODE.  Got [$ParsedLine->{'OriginalLine'}]");
		}
	}

	elsif ($State == $SAW_PREALLOCATED_OPCODE_STATE) {
		if ($ParsedLine->{'IsInstruction'}) {
			AssembleControlWord($ParsedLine, $PreallocatedLC);
			$PreviousLC = $PreallocatedLC;
			printf(LOGFILE "Setting PreviousLC to PreallocatdLC: $PreallocatedLC\n");
			$State = $SAW_INSTRUCTION_STATE;
		}
		else {
			Error("Expected an instr after OPCODE.  Got [$ParsedLine->{'OriginalLine'}]");
		}
	}

	elsif ($State == $SAW_INSTRUCTION_STATE) {
		if ($ParsedLine->{'IsInstruction'}) {


			# 
			# Fill in the NEXT_ADDRESS field for the previous instruction
			# ONLY if the JMPZ, JMPN are not set.
			#
			if (	$IntermediateAssembly[$PreviousLC]->{'JMPZ'} || 
					$IntermediateAssembly[$PreviousLC]->{'JMPN'}	||
					$IntermediateAssembly[$PreviousLC]->{'JMPC'}	||
					$IntermediateAssembly[$PreviousLC]->{'JMPY'}	||
					$IntermediateAssembly[$PreviousLC]->{'NEXT_ADDRESS'} != 0) {
				Error("Instruction Found after an explicit JUMP at LC $PreviousLC.  This is probably a mistake!");
				Error("Current Line Num is $ParsedLine->{'LineNum'}");
				Error("Current LC is $UpperLC; Prev LC is $PreviousLC");
				Error("  Current instruction is $ParsedLine->{'OriginalLine'}");
				Error("  Prev instruction is $IntermediateAssembly[$PreviousLC]->{'OriginalLine'}");
				return;
			}

						
			printf(LOGFILE "     Patching ins at [$PreviousLC] with a goto $UpperLC (should be this instructions LC\n");
			$IntermediateAssembly[$PreviousLC]->{'NEXT_ADDRESS'} = $UpperLC;

			$PreviousLC = $UpperLC;
			printf(LOGFILE "Setting PreviousLC to $UpperLC\n");

			AssembleControlWord($ParsedLine, $UpperLC);
			IncLC($UpperLC);

			# IncLC($UpperLC);
			$State = $SAW_INSTRUCTION_STATE;
		}
		elsif ($ParsedLine->{'IsOpcode'}) {
			my $Label = $ParsedLine->{'Instructions'}->[0]->{'Arg'};
		
			#
			# Check to see if this opcode has already been defined.  If so
			# we assume it is a preallocated opcode and NOT a duplicate definition
			# (though it's possible!).
			#	
			printf(LOGFILE "Saw an opcode\n");
			if (defined($SymbolTable{$Label})) { 
				printf(LOGFILE "Saw preallocated symbol $Label\n");
				$State = $SAW_PREALLOCATED_OPCODE_STATE;	
				$PreallocatedLC = $SymbolTable{$Label};
			}
			else {
				printf(LOGFILE "Lower LC is $LowerLC\n");
				AddToSymbolTable($Label, $LowerLC);
				$State = $SAW_OPCODE_STATE;
			}
			
			}
		elsif ($ParsedLine->{'IsCondHigh'}) {
			my $Arg = $ParsedLine->{'Instructions'}->[0]->{'Arg'};
			if (! defined($SymbolTable{$Arg}) ) {
				Error("Could not find Cond High in Sym Table for [$Arg].\n");
			}
			$CondHighLC = $SymbolTable{$Arg};
			$State = $SAW_CONDHIGH_STATE;
		}
		elsif ($ParsedLine->{'IsUpper'}) {
			my $Label = $ParsedLine->{'Instructions'}->[0]->{'Arg'};
			AddToSymbolTable($Label, $UpperLC);
			$State = $SAW_UPPER_STATE;
		}
		elsif ($ParsedLine->{'IsCondLow'}) {
			my $Arg = $ParsedLine->{'Instructions'}->[0]->{'Arg'};
			if (! defined($SymbolTable{$Arg}) ) {
				Error("Could not find Cond Low in Sym Table [$Arg].\n");
			}
			$CondLowLC = $SymbolTable{$Arg};
			$State = $SAW_CONDLOW_STATE;
		}
		else {
			Error("Got [$ParsedLine->{'OriginalLine'}]");
		}
	}

	elsif ($State == $SAW_CONDHIGH_STATE) {
		if ($ParsedLine->{'IsInstruction'}) {
			AssembleControlWord($ParsedLine, $CondHighLC);
			$PreviousLC = $CondHighLC;
			printf(LOGFILE "Setting PreviousLC to $CondHighLC\n");
			$State = $SAW_INSTRUCTION_STATE;
		}
		else {
			Error("Expected an instr after CONDHIGH.  Got [$ParsedLine->{'OriginalLine'}]");
		}
	}

	elsif ($State == $SAW_CONDLOW_STATE) {
		if ($ParsedLine->{'IsInstruction'}) {
			AssembleControlWord($ParsedLine, $CondLowLC);
			$PreviousLC = $CondLowLC;
			printf(LOGFILE "Setting PreviousLC to $CondLowLC\n");
			$State = $SAW_INSTRUCTION_STATE;
		}
		else {
			Error("Expected an instr after CONDLOW.  Got [$ParsedLine->{'OriginalLine'}]");
		}
	}

	else {
		Error("Unknown internal state in FSM.\n");
	}

	printf(LOGFILE "   New State is $StateNames[$State]\n");

}
###############################################################################

###############################################################################
sub DecToBin {
	my $DecimalValue = $_[0];
	my $Width = $_[1];

	my $OriginalDecimalValue = $DecimalValue;	

	my $BinStr;
	for my $i (1..$Width) {
		my $NextBit = $DecimalValue % 2;

		$DecimalValue >>= 1;
		$BinStr = $NextBit . $BinStr;
	}

	return($BinStr);

}
###############################################################################


###############################################################################
# sub ControlWordToBitPattern($ControlWord)
#
# May 31, 2009 - Added ena's for ES, CS and DS
#		Added load_es, load_cs, load_ds
#		Added use_es (for addressing relative to es)
#
# April 8th, 2006 - Added bit to control store to allow for "Jump Carry aka JMPY"
#		This was not part of Tanenbaum's original design.
#		I've added it to the left which will make it bit 36 (the 37th bit).  
#		I hope, by doing it this way, I won't have to rewire the CPU.
#
# Build up control word from left to right.
#
# Control Word Pattern is :
#		JMPY ES CS DS USE_ES
#		  1   1  1  1  1
#		NEXT_ADDRESS JMPC JMPN JMPZ SLL8 SRA1 ALU H OPC TOS CPP LV SP PC MDR MAR
#			9           1   1     1    1    1   6  1  1   1   1   1  1  1   1   1
#
#		WRITE READ FETCH B
#		   1    1    1   4
#
sub ControlWordToBitPattern {

	my $ControlWord = $_[0];
	my $BitPattern;

	$BitPattern = "";

	if ($ControlWord->{'USE_ES'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};

	#
	# Later C Bus Load Signals
	#
	if ($ControlWord->{'LOAD_DS'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'LOAD_CS'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'LOAD_ES'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};

	#
	# JMPY Control signal
	#
	if ($ControlWord->{'JMPY'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};


	# NEXT ADDRESS
	#
	$BitPattern .= DecToBin($ControlWord->{'NEXT_ADDRESS'}, 9);

	#
	# JAM signals (excluding JMPY which was not part of Tanenbaum design
	#		See above for details.)
	#
	if ($ControlWord->{'JMPC'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'JMPN'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'JMPZ'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};

	# Shifter Signals
	#
	my $ShifterBitPattern = DecToBin($ControlWord->{'SHIFTER'}, 2);
	$BitPattern .= $ShifterBitPattern;

	# ALU Signals
	#
	my $ALUBitPattern = DecToBin($ControlWord->{'ALU'}, 6);
	$BitPattern .= $ALUBitPattern;

	# C Bus Load Signals
	#
	if ($ControlWord->{'LOAD_H'})   { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'LOAD_OPC'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'LOAD_TOS'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'LOAD_CPP'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'LOAD_LV'})  { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'LOAD_SP'})  { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'LOAD_PC'})  { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'LOAD_MDR'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'LOAD_MAR'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};

	#		WRITE READ FETCH
	#
	if ($ControlWord->{'WRITE'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'READ'})  { $BitPattern .= "1";} else { $BitPattern .= "0";};
	if ($ControlWord->{'FETCH'}) { $BitPattern .= "1";} else { $BitPattern .= "0";};

#	$BitPattern .= " ";

	# B Bus enable signals
	#
	my $BBusBitPattern = DecToBin($ControlWord->{'B'}, 4);

	$BitPattern .= $BBusBitPattern;


	return($BitPattern);
}
###############################################################################


###############################################################################
sub CreateControlStoreVHDL {


printf(OBJFILE "library IEEE;\n");
printf(OBJFILE "use IEEE.STD_LOGIC_1164.ALL;\n");
printf(OBJFILE "use IEEE.STD_LOGIC_ARITH.ALL;\n");
printf(OBJFILE "use IEEE.STD_LOGIC_UNSIGNED.ALL;\n");

printf(OBJFILE "entity ControlStore is\n");
printf(OBJFILE "    Port ( input : in std_logic_vector(8 downto 0);\n");
printf(OBJFILE "           output : out std_logic_vector(40 downto 0));\n");
printf(OBJFILE "end ControlStore;\n");

printf(OBJFILE "\n");
printf(OBJFILE "\n");

printf(OBJFILE "architecture Behavioral of ControlStore is\n");
printf(OBJFILE "\n");
printf(OBJFILE "begin\n");


printf(OBJFILE "output <= \n");

	#
	#
	for my $LC (0..$MAX_LC) {
		my $ControlWord = $IntermediateAssembly[$LC];

		my $AddressBitPattern  = DecToBin($LC, 9);

		my $ROMBitPattern = ControlWordToBitPattern($ControlWord);

		printf(OBJFILE 
			"\"$ROMBitPattern\" when (input = \"$AddressBitPattern\") else\n");

		printf(OBJFILE "    -- %3d %s\n", $LC, $ControlWord->{'OriginalLine'});
		foreach my $Key (sort(keys(%{$ControlWord}))) {
			printf(OBJFILE "        -- [$Key] [$ControlWord->{$Key}] \n");
		}
		printf(OBJFILE "\n");		
	}
	my $RomBitPattern = DecToBin(0, 41);
	printf(OBJFILE "\"$RomBitPattern\";\n");

	printf(OBJFILE "\n");		

	printf(OBJFILE "end Behavioral;\n");


	printf(OBJFILE "-- ==== Symbol Table ====\n");
	for my $Symbol (sort(keys(%SymbolTable))) {
		printf(OBJFILE "  -- [$Symbol] [$SymbolTable{$Symbol}]\n");
		printf(SYMBOLTABLEFILE "$Symbol $SymbolTable{$Symbol}\n");
	}
	
}


###############################################################################


###############################################################################
#
# Main Program
#
{
	my $SrcFileName;
	my $ObjFileName;
	my $LogFileName;
	my $OpcodeMapFileName;
	my $SymbolTableFileName;

   $| = 1;
   
	GetOptions(	
					"srcfile=s"		=> \$SrcFileName,
					"objfile=s"		=> \$ObjFileName,
					"opcodemapfile=s" => \$OpcodeMapFileName,
					"symboltablefile=s" => \$SymbolTableFileName,
					"logfile=s"		=> \$LogFileName);

	if (! defined($SrcFileName) ) {
		printf(STDERR "ERROR: No source file specified.\n");
		Usage();
		exit(1);
	}

	if (! defined($ObjFileName) ) {
		printf(STDERR "ERROR: No object file specified.\n");
		Usage();
		exit(1);
	}

	if (! defined($LogFileName) ) {
		printf(STDERR "ERROR: No log file specified.\n");
		Usage();
		exit(1);
	}

	if (! defined($OpcodeMapFileName) ) {
		printf(STDERR "ERROR: No opcode file specified.\n");
		Usage();
		exit(1);
	}

	if (! defined($SymbolTableFileName) ) {
		printf(STDERR "ERROR: No symboltable file specified.\n");
		Usage();
		exit(1);
	}

	open(SRCFILE, "<$SrcFileName") || die("Could not open $SrcFileName\n");
	open(LOGFILE, ">$LogFileName") || die("Could not open $LogFileName\n");
	open(OBJFILE, ">$ObjFileName") || die("Could not open $ObjFileName\n");
	open(OPCODEMAPFILE, "<$OpcodeMapFileName") || die("Could not open $OpcodeMapFileName\n");
	open(SYMBOLTABLEFILE, ">$SymbolTableFileName") || die("Could not open $SymbolTableFileName\n");
   
	LoadOpcodeMap();
	
   #
   my $Line;
   $LineNum = 0;
   while (chomp(my $Line = <SRCFILE>)) {
   	$LineNum++;
   	my $ParsedLine = ParseLine($Line, $LineNum);
   	ProcessLine($ParsedLine);
   } 


	CreateControlStoreVHDL;


}

###############################################
		
