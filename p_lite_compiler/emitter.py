


def EmitCode(Line, LineNum):
    """ Emit Line to the annotated listing file. """

    global NewLineWasEmitted
    global OutputFile

    if NewLineWasEmitted:
        OutputFile.writelines('               ');
    OutputFile.writelines(Line + ' ');
    NewLineWasEmitted = False


def EmitCodeLabel(AsmLabel, LineNum):
    """ Emit line to the annotated listing file. """

    global NewLineWasEmitted
    global OutputFile

    if not NewLineWasEmitted:
        OutputFile.writelines('\n')

    OutputFile.writelines('               ')
    OutputFile.writelines(AsmLabel + ':\n')
    NewLineWasEmitted = True

   

   
#####################################################################
# Data only comes after a data label (otherwise what's the point of 
# the data?
# So we never have to worry about a new line BEFORE data
def EmitData(Line, LineNum):
    """ Emit Line to the annotated listing file. """

    global DataNewLineWasEmitted
    global DataBuffer

    DataBuffer.append(Line + ' ');
#####################################################################


#####################################################################
def EmitDataLabel(AsmLabel, LineNum):
    """ Emit line to the annotated listing file. """

    global DataNewLineWasEmitted
    global DataBuffer


    DataBuffer.append('\n')

    DataBuffer.append('               ')
    DataBuffer.append(AsmLabel + ': \n')
#####################################################################


    

#####################################################################
def EmitUData(Line, LineNum):
    """ Emit Line to the annotated listing file. """

    global NewLineWasEmitted
    global UDataBuffer

    UDataBuffer.append(Line + " ");
#####################################################################


#####################################################################
def EmitUDataLabel(AsmLabel, LineNum):
    """ Emit line to the annotated listing file. """

    global NewLineWasEmitted
    global UDataBuffer

    UDataBuffer.append('\n')
    UDataBuffer.append('               ')
    UDataBuffer.append(AsmLabel + ': ')
    
#####################################################################


    
    
    
    
#####################################################################
def EmitSrc(SrcLine, LineNum):
    """ Emit line to the annotated listing file. """

    global NewLineWasEmitted
    global OutputFile

    # SrcLine = SrcLine.rstrip()
    # SrcLine = SrcLine + " " # to get formatting compatibility with PASCAL version

    if not NewLineWasEmitted:
        OutputFile.writelines('\n')

    OutputFile.writelines((';SRC ', '%4d'%LineNum, '|', '%s'%SrcLine))
    OutputFile.writelines("\n")
    NewLineWasEmitted = True
#####################################################################




#####################################################################
def FinishEmitter():
    global OutputFile

    # Source Code and corresponding ASM have already been
    # emitted
    # Now we emit initialized and unintialized data at the end 
    # of the compilation.
    OutputFile.writelines(".DATA")
    OutputFile.writelines(DataBuffer)
    OutputFile.writelines(".UDATA")
    OutputFile.writelines(UDataBuffer)
    OutputFile.close()
#####################################################################
    

#####################################################################
def EmitInit(OutputFileName):
    """ Initialize the emitter, by opening OutputFileName. """

    global OutputFile
    global NewLineWasEmitted
    global DataNewLineWasEmitted
    
    global DataBuffer
    global UDataBuffer
    
    

    OutputFile = open(OutputFileName, 'w')
    NewLineWasEmitted = True

    DataBuffer = list()
    UDataBuffer = list()
#####################################################################
    