#!/usr/bin/perl

use strict;

###############################################################################
#
# External Modules:
#
use Getopt::Long;

#
# Use this module to handle tabs properly; It implicitly uses $tabstop.
#
use Text::Tabs;
$tabstop = 3;

use Text::ParseWords;
###############################################################################


###############################################################################
# Constants
my $SRC_LINE_LISTING_WIDTH = 120;
my $CODE_WORD = 0;
my $DATA_WORD = 1;
my $GUARD_WORD = 2;

my $V1_LOAD_ADDRESS  = 0x0403;

my $V3_CODE_LOAD_ADDRESS = 0x1000;
my $V3_DATA_LOAD_ADDRESS = 0x0800;

my $V4_CODE_LOAD_ADDRESS = 0x1000;
###############################################################################


###############################################################################
#
# Global Variabes
#
my $TokenPointer;
my @FileBuffer;
my %SymbolTable;
my $LineNum;
my @TokenList;
my %PsuedoOpInfo;
my $PassNum;
my $LC;
my %InstructionInfo;

my @CodeBuffer;
my @CodeTypeBuffer;
my @DataBuffer;
my @DataTypeBuffer;

my @ValToHex;
my %HexToVal;
my $CodeLoadAddress;
my $DataLoadAddress;

my $GlobalError = 0;
my $ASMMode;

# define the output to be produced
my $OutputFormat;

#
# Placing the filenames here so they can be referenced
# by multiple subs
#
my $SrcFileName;
my $ObjFileName;
my $ErrorFileName;
my $ListFileName;

###############################################################################


###############################################################################
sub Usage {
	printf("$0 -outputformat 1|3|4 -srcfile SrcFile -objfile ObjFile -listfile ListFile [-v4codeaddress n ] -errorfile ErrorFile \n");
}
###############################################################################


###############################################################################
sub Init {

$InstructionInfo{"&"}->{'Value'} = 27;
$InstructionInfo{"AND"}->{'Value'} = 27;
$InstructionInfo{"BRA"}->{'Value'} = 4;
$InstructionInfo{"JMP"}->{'Value'} = 4;
$InstructionInfo{"CS_FETCH"}->{'Value'} = 43;
$InstructionInfo{"DI"}->{'Value'} = 37;
$InstructionInfo{"JMPF"}->{'Value'} = 12;
$InstructionInfo{"PUSH"}->{'Value'} = 2;
$InstructionInfo{"DROP"}->{'Value'} = 7;
$InstructionInfo{"DS_FETCH"}->{'Value'} = 42;
$InstructionInfo{"DUP"}->{'Value'} = 19;
$InstructionInfo{"EI"}->{'Value'} = 35;
$InstructionInfo{"ES_FETCH"}->{'Value'} = 41;
$InstructionInfo{"=="}->{'Value'} = 31;
$InstructionInfo{"FETCH"}->{'Value'} = 9;
$InstructionInfo{"FROM_R"}->{'Value'} = 14;
$InstructionInfo{"HALT"}->{'Value'} = 3;
$InstructionInfo{"JSR"}->{'Value'} = 10;
$InstructionInfo{"JSRINT"}->{'Value'} = 33;
$InstructionInfo{"K_SP_STORE"}->{'Value'} = 47;
$InstructionInfo{"<"}->{'Value'} = 5;
$InstructionInfo{"LONG_FETCH"}->{'Value'} = 44;
$InstructionInfo{"LONG_STORE"}->{'Value'} = 45;
$InstructionInfo{"LONG_TYPE_STORE"}->{'Value'} = 53;
$InstructionInfo{"L_VAR"}->{'Value'} = 51;
$InstructionInfo{"MUL"}->{'Value'} = 30;
$InstructionInfo{'*'}->{'Value'} = 30;
$InstructionInfo{"NEG?"}->{'Value'} = 26;
$InstructionInfo{"NOP"}->{'Value'} = 1;
$InstructionInfo{"OR"}->{'Value'} = 28;
$InstructionInfo{"|"}->{'Value'} = 28;
$InstructionInfo{"OVER"}->{'Value'} = 22;
$InstructionInfo{"+"}->{'Value'} = 24;
$InstructionInfo{"++"}->{'Value'} = 6;
$InstructionInfo{"POPF"}->{'Value'} = 49;
$InstructionInfo{"PUSHF"}->{'Value'} = 48;
$InstructionInfo{"RESET"}->{'Value'} = 0;
$InstructionInfo{"RET"}->{'Value'} = 11;
$InstructionInfo{"RETI"}->{'Value'} = 34;
$InstructionInfo{"RP_FETCH"}->{'Value'} = 16;
$InstructionInfo{"RP_STORE"}->{'Value'} = 17;
$InstructionInfo{"R_FETCH"}->{'Value'} = 18;
$InstructionInfo{"S_LESS"}->{'Value'} = 50;
$InstructionInfo{"SLL"}->{'Value'} = 15;
$InstructionInfo{"SP_FETCH"}->{'Value'} = 20;
$InstructionInfo{"SP_STORE"}->{'Value'} = 23;
$InstructionInfo{"SRA"}->{'Value'} = 36;
$InstructionInfo{"SRL"}->{'Value'} = 38;
$InstructionInfo{"STORE"}->{'Value'} = 8;
$InstructionInfo{"STORE2"}->{'Value'} = 52;
$InstructionInfo{"-"}->{'Value'} = 25;
$InstructionInfo{"SWAP"}->{'Value'} = 21;
$InstructionInfo{"SYSCALL"}->{'Value'} = 46;
$InstructionInfo{"TO_DS"}->{'Value'} = 40;
$InstructionInfo{"TO_ES"}->{'Value'} = 39;
$InstructionInfo{"TO_R"}->{'Value'} = 13;
$InstructionInfo{"UM+"}->{'Value'} = 32;
$InstructionInfo{"XOR"}->{'Value'} = 29;


$PsuedoOpInfo{".DS"} = 1;
$PsuedoOpInfo{".DG"} = 1;
$PsuedoOpInfo{".DW"} = 1;
$PsuedoOpInfo{".ENDDW"} = 1;
$PsuedoOpInfo{".CODE"} = 1;
$PsuedoOpInfo{".DATA"} = 1;
$PsuedoOpInfo{".UDATA"} = 1;


	$ValToHex[0]  = "0";
	$ValToHex[1]  = "1";
	$ValToHex[2]  = "2";
	$ValToHex[3]  = "3";
	$ValToHex[4]  = "4";
	$ValToHex[5]  = "5";
	$ValToHex[6]  = "6";
	$ValToHex[7]  = "7";
	$ValToHex[8]  = "8";
	$ValToHex[9]  = "9";
	$ValToHex[10] = "A";
	$ValToHex[11] = "B";
	$ValToHex[12] = "C";
	$ValToHex[13] = "D";
	$ValToHex[14] = "E";
	$ValToHex[15] = "F";

	$HexToVal{'0'} = 0;
	$HexToVal{'1'} = 1;
	$HexToVal{'2'} = 2;
	$HexToVal{'3'} = 3;
	$HexToVal{'4'} = 4;
	$HexToVal{'5'} = 5;
	$HexToVal{'6'} = 6;
	$HexToVal{'7'} = 7;
	$HexToVal{'8'} = 8;
	$HexToVal{'9'} = 9;
	$HexToVal{'A'} = 10;
	$HexToVal{'B'} = 11;
	$HexToVal{'C'} = 12;
	$HexToVal{'D'} = 13;
	$HexToVal{'E'} = 14;
	$HexToVal{'F'} = 15;

}
###############################################################################


###############################################################################
sub Error {
	my $Msg = $_[0];

	printf(ERRORFILE "ERROR : Line $LineNum $Msg\n");
    $GlobalError = 1;
}
###############################################################################


###############################################################################
sub ReadFile {
	my $FileName = $_[0];

	open (INPUT_FILE, "<$FileName") || die ("Could not open $FileName; exiting...\n");
	#
	# Push an empty first line. We do this because
	# we want linenums to start at 1 not 0, but array starts at zero.
	# 
	push (@FileBuffer, "");
	while (chop(my $Line = <INPUT_FILE>)) {
		$Line =~ s/\s+$//;
		push (@FileBuffer, $Line);
	}
	close(INPUT_FILE);
}
###############################################################################


###############################################################################
sub GetNextToken {
	my $Token = $TokenList[$TokenPointer];
	$TokenPointer++;
	return($Token);
}
###############################################################################


###############################################################################
sub NumToHex {
	my $Num = $_[0];

	my $Str;
	for my $i (1..4) {
		my $NextVal = $Num % 16;
		$Num >>= 4;
		$Str = $ValToHex[$NextVal] . $Str;
	}
	return($Str);
}
###############################################################################


###############################################################################
# Assume Hex str starts with "0x"
sub HexToNum {
	my $Hex = $_[0];
	my $Sum;

	my @Chars = (split(' *', $Hex));
	#
	# remove "0x" from beginning
	#
	shift(@Chars);
	shift(@Chars);
	foreach my $ch (@Chars) {
		$Sum = $Sum * 16 + $HexToVal{$ch};
	}
	return $Sum;

}
###############################################################################


###############################################################################
sub IsInstruction {
	my $Token = $_[0];

	return(defined($InstructionInfo{$Token}));
}
###############################################################################


###############################################################################
sub IsPsuedoOp {
	my $Token = $_[0];

	return(defined($PsuedoOpInfo{$Token}));
}
###############################################################################


###############################################################################
sub IsNumber {
	my $Token = $_[0];

	return ($Token =~ /^[0-9]+$|^-[0-9]+$/);
}
###############################################################################


###############################################################################
sub IsHexNumber {
	my $Token = $_[0];

	return ($Token =~ /^0(x|X).+/);
}
###############################################################################


###############################################################################
sub IsCommentDelimiter {
	my $Token = $_[0];

	return ($Token =~ /^;|^#/);
}
###############################################################################


###############################################################################
sub IsLabel {
	my $Token = $_[0];

	return ($Token =~ /^.*:/);
}
###############################################################################


###############################################################################
sub IsGlobalVariable {
	my $Token = $_[0];

	my @Stuff = split('\'', $Token);
	#
	# Variable may or may not have attributes so we can't just look at the token.
	my $VarName = $Stuff[0];
	if (defined($SymbolTable{$VarName})) {
		return 1
	}

	return 0
}
###############################################################################


###############################################################################
sub AddLabelToSymbolTable {
	my $Label = $_[0];
	my $Address = $_[1];

	if (defined($SymbolTable{$Label})) {
		Error("Label [$Label] already in Symbol Table; dup def on line [$LineNum]\n");
		return;
	}

	$SymbolTable{$Label}->{'Value'} = $Address;
}
###############################################################################


###############################################################################
sub AssembleInstruction {
	my $Token = $_[0];

	if (! defined($InstructionInfo{$Token})) {
		Error("Internal error tried to assemble unknown instr $Token\n");
		return;
	}
	
	if ($PassNum == 1) {
		$LC++;
		if ($Token eq "JSR" || 
		    $Token eq "BRA" || 
		    $Token eq "JMP" || 
		    $Token eq "JMPF" || 
		    $Token eq "L_VAR") { 
			$LC++; 
			$TokenPointer++;	# Skip the label or numeric const associated w/these  instructions
		}
		return;
	}

	#
	# This is Pass 2; assemble the code.
	#
	EmitToObjectAndList($LC, $InstructionInfo{$Token}->{'Value'}, $CODE_WORD);
	$LC++;


	if ($Token eq "JSR" || $Token eq "BRA" || $Token eq "JMP" || $Token eq "JMPF" || $Token eq "L_VAR") {
		$Token = $TokenList[$TokenPointer];
		$TokenPointer++;

		if (defined($SymbolTable{$Token}) ) {
			EmitToObjectAndList($LC, $SymbolTable{$Token}->{'Value'}, $CODE_WORD);
		}
		elsif (IsNumber($Token)) {
			EmitToObjectAndList($LC, $Token, $CODE_WORD);
		}
		elsif (IsHexNumber($Token)) {
			EmitToObjectAndList($LC, HexToNum($Token), $DATA_WORD);
		}
		else {
			Error("Symbol [$Token] not found on line [$LineNum]\n");
		}


		$LC++;		
	}
}
###############################################################################


###############################################################################
sub AssembleNumber {
	my $Token = $_[0];

	#
	# Numbers require 2 words of mem: one for push; one for val
	#

	if ($PassNum == 1) {
		$LC += 2;
		return;
	}

	AssembleInstruction("PUSH");
	EmitToObjectAndList($LC, $Token, $CODE_WORD);
	$LC++;
}
###############################################################################


###############################################################################
# Please note GlobalVariable can also be a code label.
sub AssembleGlobalVariable {
	my $Token = $_[0];
	
	my $VariableName = $Token;

	
	if ($PassNum == 1) {
		$LC += 2 ;
		return;
	}
		
	#
	# If we've gotten this far, we are in the 2nd pass
	#
	if (IsGlobalVariable($VariableName)) {
		AssembleNumber($SymbolTable{$VariableName}->{'Value'});
	}
	else {
		Error("Symbol [$VariableName] is an undefined symbol - found in pass 2");
	}

}
###############################################################################


###########################################################################
sub ProcessLabel {
	my $Token = $_[0];

	# Remove the ':'
	chop($Token);

	if ($PassNum == 2) { return; }

	AddLabelToSymbolTable($Token, $LC);
}
###############################################################################


###############################################################################
sub ProcessPsuedoOp {
	my $Token = $_[0];



	if ($Token eq ".DG") {
		if ($PassNum == 1) {
			$LC += 1;
			return;
		}
		EmitToObjectAndList($LC, 0, $GUARD_WORD);
		$LC++;
		return;
	}

	if ($Token eq ".DS") {
		my $StorageSize = $TokenList[$TokenPointer];
		$TokenPointer++;
		if ($PassNum == 1) {
			$LC += $StorageSize;
			return;
		}

		for my $i (1..$StorageSize) {
			EmitToObjectAndList($LC, 0, $DATA_WORD);
			$LC++;
		}
		return;
	}

	if ($Token eq ".DW") {

		while (1) {
			my $NextToken = $TokenList[$TokenPointer];
			$TokenPointer++;

			if ($NextToken eq ".ENDDW") { last; }

			if ($PassNum == 2) {
				if (IsHexNumber($NextToken)) {
					EmitToObjectAndList($LC, HexToNum($NextToken), $DATA_WORD);
				}
				else {
					EmitToObjectAndList($LC, $NextToken, $DATA_WORD);
				}
			}
			$LC++;
		}
		return;
	}

	if ($Token eq ".CODE") {
		if ($ASMMode ne "NONE") {
			Error("Saw .CODE but assembly had already begun!");
		}
		$ASMMode = ".CODE";

		if ($OutputFormat == 1) {
			$LC = $V1_LOAD_ADDRESS;
		}
		elsif ($OutputFormat == 3) {
			$LC = $V3_CODE_LOAD_ADDRESS;
		}
		elsif ($OutputFormat == 4) {
			$LC = $V4_CODE_LOAD_ADDRESS;
		}

		return;
	}
	
	if ($Token eq ".DATA") {
		if ($ASMMode ne ".CODE") {
			Error("Saw .DATA but prev mode was not .CODE!");
		}
		$ASMMode = ".DATA";
		printf(STDERR "DEBUG Switching to $ASMMode\n");

		if ($OutputFormat == 1) {
			$LC = $LC;
		}
		elsif ($OutputFormat == 3) {
			$LC = $V3_DATA_LOAD_ADDRESS;
		}
		elsif ($OutputFormat == 4) {
			$LC = $LC;
		}

		return;
	}
	
	if ($Token eq ".UDATA") {
		if ($ASMMode ne ".DATA") {
			Error("Saw .UDATA but prev mode was not .DATA!");
		}
		$ASMMode = ".UDATA";
		printf(STDERR "DEBUG Switching to $ASMMode\n");
		# $LC += 0x0100;

		return;
	}
	
		
}
###############################################################################


###############################################################################
sub EmitToObjectAndList {
	my $Address = $_[0];
	my $Val = $_[1];
	my $ValType = $_[2];

	if ($ASMMode eq ".CODE") {
		push(@CodeBuffer, $Val);
		push(@CodeTypeBuffer, $ValType);
	}
		
	elsif ($ASMMode eq ".DATA") {
		push(@DataBuffer, $Val);
		push(@DataTypeBuffer, $ValType);
	}
		
	elsif ($ASMMode eq ".UDATA") {
		push(@DataBuffer, $Val);
		push(@DataTypeBuffer, $ValType);
	}
	else {
		Error("Unknown ASM mode in EmitToObjectAnd List");
	}
		
	SendObjectWordToList($Val);
}
###############################################################################


###############################################################################
sub SendObjectWordToList {
	my $ObjectWord = $_[0];
	printf(LISTFILE "%s ", NumToHex($ObjectWord));
}
###############################################################################


###############################################################################
sub SendLCToList {
	my $Address = $_[0];
	printf(LISTFILE "@%s ", NumToHex($Address));
}
###############################################################################


###############################################################################
sub SendSrcLineToList {
	my $SrcLine = $_[0];

	#
	# Expand tabs so listing looks pretty.
	#
	$SrcLine = expand($SrcLine);

	my $TruncatedLine = substr($SrcLine, 0, $SRC_LINE_LISTING_WIDTH);
	printf(LISTFILE "%-${SRC_LINE_LISTING_WIDTH}s ", $TruncatedLine);
}
###############################################################################


###############################################################################
sub SendLineNumToList {
	my $LineNum = $_[0];
	printf(LISTFILE "%4d ", $LineNum);
}
###############################################################################


###############################################################################
sub SendNLToList {
	printf(LISTFILE "\n");
}
###############################################################################


###############################################################################
sub OutputV1Object {

	# V1 format is Pat's Original loader format from 2006!
	# Assume Loaded at 0x0403
	# Start address defined by MAIN
	#
	# 
	# loader i.e. ascii hex strings (organized as hex words - 4 digits each)
	#    word 1 - word count excluding 2 word header
	#    word 2 - starting address
	#    words 2-n data words, loaded starting at 0x0403
	# 	
	my $V1FileName = $ObjFileName . ".V1" ;

	open(OBJFILE, ">$V1FileName") || die("Could not open $V1FileName\n");
	
	my $Size = $#CodeBuffer + 1 + $#DataBuffer + 1;
	printf(OBJFILE "%s", NumToHex($Size));
	printf(OBJFILE "%s", 	NumToHex($SymbolTable{'MAIN'}->{'Value'}));
	foreach my $ObjectWord (@CodeBuffer) {
		printf(OBJFILE "%s", NumToHex($ObjectWord));
	}
	foreach my $ObjectWord (@DataBuffer) {
		printf(OBJFILE "%s", NumToHex($ObjectWord));
	}
	close(OBJFILE);
	
	return;

    #
    # Create another output file for use with the simulator
    # This is a BINARY format
    #
    my $SimulatorObjFileName = $ObjFileName . ".sim" ;

    open(OBJFILE, ">$SimulatorObjFileName") || 
        die("Could not open $ObjFileName\n");

	my $Size = $#CodeBuffer + 1;

    # First 2 hex words are the MAGIC signature for use with the loader
#	printf(OBJFILE "%s\r", NumToHex(0));
#	printf(OBJFILE "%s\r", NumToHex(2));
#
#	printf(OBJFILE "%s\r", NumToHex($Size));
#	printf(OBJFILE "%s\r", NumToHex($LoadAddress));
#	printf(OBJFILE "%s\r", 	NumToHex($SymbolTable{'MAIN'}->{'Value'}));

	printf(OBJFILE "%s%s", chr(0), chr(0));
	printf(OBJFILE "%s%s", chr(0), chr(2));

	my $LoadAddress = $V1_LOAD_ADDRESS;
	
	printf(OBJFILE "%s%s", 
        chr(($Size >>8) & 255), 
        chr($Size & 255)         );
	printf(OBJFILE "%s%s", 
        chr(($LoadAddress >>8) & 255), 
        chr($LoadAddress & 255)        );
	printf(OBJFILE "%s%s", 
        chr(($SymbolTable{'MAIN'}->{'Value'} >>8) & 255), 
        chr($SymbolTable{'MAIN'}->{'Value'}  & 255  )      );


    if ($#CodeBuffer != $#CodeTypeBuffer) {
        printf("FATAL Error CodeBuffer and CodeTypeBuffer are not the same length\n");
        exit(1);
    }

    my $i;
    for $i (0..$#CodeBuffer) {
#		printf(OBJFILE "%s\r", NumToHex($CodeTypeBuffer[$i]));
#		printf(OBJFILE "%s\r", NumToHex($CodeBuffer[$i]));

        printf(OBJFILE "%s", chr($CodeTypeBuffer[$i] & 255));
		printf(OBJFILE "%s%s", 
            chr(($CodeBuffer[$i] >> 8) & 255), 
            chr($CodeBuffer[$i]  & 255)        );
	}
	close(OBJFILE);

}
###############################################################################



###############################################################################
sub OutputV3Object {

	# V3 output format
	# Each word comes as 2 bytes MSB first
	#    word 1     :  Words 1 and 2 are a MAGIC identifier 0000 0003
	#    word 2  
	#    word 3     : size of CODE in words
	#    word 4     : CODE loading address
	#    word 5     : CODE starting address
	#
	#    word 6     : size of DATA in words
	#    word 7     : DATA loading address
	#
	# words 2 * size in words for code
	#
	# words 2 * size in words for data
	#


	my $V3FileName = $ObjFileName . ".V3" ;

    open(OBJFILE, ">$V3FileName") || 
        die("Could not open V3 File : $V3FileName\n");

	my $CodeSize = $#CodeBuffer + 1;
	printf(STDERR "DEBUG CodeBuffer size is %X\n", $CodeSize);


	# Write pair of magic words
	# Words 1 and 2
	printf(OBJFILE "%s%s", chr(0), chr(0));
	printf(OBJFILE "%s%s", chr(0), chr(3));

	# Word 3 size of code in words
	printf(OBJFILE "%s%s", 
        chr(($CodeSize >>8) & 255), 
        chr($CodeSize & 255)         );

	# Word 4 Code Loading Address
	printf(OBJFILE "%s%s", 
        chr(($V3_CODE_LOAD_ADDRESS >>8) & 255), 
        chr($V3_CODE_LOAD_ADDRESS & 255)  );
		
	# Word 5 Code Starting Address		
	printf(OBJFILE "%s%s", 
        chr(($SymbolTable{'MAIN'}->{'Value'} >>8) & 255), 
        chr($SymbolTable{'MAIN'}->{'Value'}  & 255  )      );


	my $DataSize = $#DataBuffer + 1 ;
	printf(STDERR "DEBUG DataBuffer size is %X\n", $DataSize);

	# Word 6 size of code in words
	printf(OBJFILE "%s%s", 
        chr(($DataSize >>8) & 255), 
        chr($DataSize & 255)         );

	$DataLoadAddress = $V3_DATA_LOAD_ADDRESS;
	# Word 7 Data Loading Address
	printf(OBJFILE "%s%s", 
        chr(($DataLoadAddress >>8) & 255), 
        chr($DataLoadAddress & 255)  );
		
		
		

	# Write the code
    my $i;
    for $i (0..$#CodeBuffer) {
		printf(OBJFILE "%s%s", 
            chr(($CodeBuffer[$i] >> 8) & 255), 
            chr($CodeBuffer[$i]  & 255)        );
	}


	# Write the data
    my $i;
    for $i (0..$#DataBuffer) {
		printf(OBJFILE "%s%s", 
            chr(($DataBuffer[$i] >> 8) & 255), 
            chr($DataBuffer[$i]  & 255)        );
	}




	close(OBJFILE);

}
###############################################################################



###############################################################################
sub OutputV4Object {

	# V4 output format
	# Like V3 but assumes all go into a single 64K bank
	#
	# Each word comes as 2 bytes MSB first
	#    word 1     :  Words 1 and 2 are a MAGIC identifier 0000 0004
	#    word 2  
	#    word 3     : size of CODE in words
	#    word 4     : CODE loading address
	#    word 5     : CODE starting address
	#
	#    word 6     : size of DATA in words
	#    word 7     : DATA loading address
	#
	# words 2 * size in words for code
	#
	# words 2 * size in words for data
	#


	my $V4FileName = $ObjFileName . ".V4" ;

    open(OBJFILE, ">$V4FileName") || 
        die("Could not open V4 File : $V4FileName\n");

	my $CodeSize = $#CodeBuffer + 1;
	printf(STDERR "DEBUG CodeBuffer size is %X\n", $CodeSize);


	# Write pair of magic words
	# Words 1 and 2
	printf(OBJFILE "%s%s", chr(0), chr(0));
	printf(OBJFILE "%s%s", chr(0), chr(4));

	# Word 3 size of code in words
	printf(OBJFILE "%s%s", 
        chr(($CodeSize >>8) & 255), 
        chr($CodeSize & 255)         );

	# Word 4 Code Loading Address
	printf(OBJFILE "%s%s", 
        chr(($V4_CODE_LOAD_ADDRESS >>8) & 255), 
        chr($V4_CODE_LOAD_ADDRESS & 255)  );
		
	# Word 5 Code Starting Address		
	printf(OBJFILE "%s%s", 
        chr(($SymbolTable{'MAIN'}->{'Value'} >>8) & 255), 
        chr($SymbolTable{'MAIN'}->{'Value'}  & 255  )      );


	my $DataSize = $#DataBuffer + 1 ;
	printf(STDERR "DEBUG DataBuffer size is %X\n", $DataSize);

	# Word 6 size of code in words
	printf(OBJFILE "%s%s", 
        chr(($DataSize >>8) & 255), 
        chr($DataSize & 255)         );

	# $DataLoadAddress = $V4_DATA_LOAD_ADDRESS;
	
	$DataLoadAddress = $V4_CODE_LOAD_ADDRESS + $CodeSize;
	
	# Word 7 Data Loading Address
	printf(OBJFILE "%s%s", 
        chr(($DataLoadAddress >>8) & 255), 
        chr($DataLoadAddress & 255)  );

		
	# Write the code
    my $i;
    for $i (0..$#CodeBuffer) {
		printf(OBJFILE "%s%s", 
            chr(($CodeBuffer[$i] >> 8) & 255), 
            chr($CodeBuffer[$i]  & 255)        );
	}


	# Write the data
    my $i;
    for $i (0..$#DataBuffer) {
		printf(OBJFILE "%s%s", 
            chr(($DataBuffer[$i] >> 8) & 255), 
            chr($DataBuffer[$i]  & 255)        );
	}

	close(OBJFILE);
}
###############################################################################




###############################################################################
# 
# Main Program
#
{
$| = 1;

Init;

GetOptions(	
	"outputformat=i" => \$OutputFormat,
	"v4codeaddress=i" => \$V4_CODE_LOAD_ADDRESS,
	"srcfile=s"		=> \$SrcFileName,
	"objfile=s"		=> \$ObjFileName,
	"errorfile=s"		=> \$ErrorFileName,
	"listfile=s"	=> \$ListFileName);
	
#
if (! defined($OutputFormat) ) {	
	printf(STDERR "ERROR: No Output Format specified.\n");
	Usage();
	exit(1);
}

if (($OutputFormat != 1) && ($OutputFormat != 3) && ($OutputFormat != 4) ) {
	printf(STDERR "ERROR OutputFormat must be 1|3|4. \n");
	Usage();
	exit(1);
}

	


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

if (! defined($ListFileName) ) {
	printf(STDERR "ERROR: No LISTFILE file specified.\n");
	Usage();
	exit(1);
}

if (! defined($ErrorFileName) ) {
	printf(STDERR "ERROR: No ERRORFILE file specified.\n");
	Usage();
	exit(1);
}

open(LISTFILE, ">$ListFileName") || die("Could not open $ListFileName\n");

open(ERRORFILE, ">$ErrorFileName") || die("Could not open $ErrorFileName\n");


ReadFile($SrcFileName);

#
# Do 2 Pass Assembly
#	
$PassNum = 1;
while (1) {

	$LC = "UNDEFINED";
	$ASMMode = "NONE";
	

	if ($PassNum > 2) { last; }

	printf(STDERR "DEBUG PassNum is <$PassNum>\n");
	
	#
	# Iterate over all lines in the the global FileBuffer
	#
	$LineNum = 1;
	while (1) {

		if ($LineNum > $#FileBuffer) { last; }

		my $Line = $FileBuffer[$LineNum];

		if ($PassNum == 2) {
			SendLineNumToList($LineNum);
			SendSrcLineToList($Line);
			SendLCToList($LC);
		}

		@TokenList = split(' ', $Line);

		#
		# Iterate over all tokens ON A LINE
		#
		$TokenPointer = 0;
		while (1) {
			if ($TokenPointer > $#TokenList) { last; };

			my $Token = $TokenList[$TokenPointer];
			$TokenPointer++;

			if (IsInstruction($Token)) {
				AssembleInstruction($Token);
				next; 
			}
   
  			if (IsPsuedoOp($Token)) {
  				ProcessPsuedoOp($Token);
  				next; 
	  		}

			if (IsNumber($Token)) {
				AssembleNumber($Token);
				next;
			}

			if (IsHexNumber($Token)) {
				my $Num = HexToNum($Token);
				AssembleNumber($Num);
				next;
			}

			if (IsLabel($Token)) {
				ProcessLabel($Token);
				next;
			}

			if (IsCommentDelimiter($Token)) {
				last;
			}

			# if (IsGlobalVariable($Token)) {
				# AssembleGlobalVariable($Token);
				# next;
			# }
			AssembleGlobalVariable($Token);
				
			# Error("Unknown token [$Token] on line [$LineNum]\n");
		}
		$LineNum++;

		if ($PassNum == 2) { SendNLToList; }

	}
	$PassNum++;
}

printf(LISTFILE "Global Symbol table:\n");
foreach my $Symbol (sort(keys(%SymbolTable))) {
	printf(LISTFILE "%-15s %4s\n", $Symbol, NumToHex($SymbolTable{$Symbol}->{'Value'}));
}


if ($OutputFormat == 1) {
	OutputV1Object();
}
elsif ($OutputFormat == 3) {
	OutputV3Object();
}
elsif ($OutputFormat == 4) {
	OutputV4Object();
}


exit($GlobalError);

}
