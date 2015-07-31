#!/usr/bin/python
""" TCP based disk controller """

import sys
import os

# Constants
NUM_DIRS = 330
NUM_FILES = 10


#   
# Main Program is Here
#
def main():

    for DirNum in range(NUM_DIRS):
        IsBigDir = ((DirNum % 100) == 0)
        if (IsBigDir):
            DirName = "big_dir_%04d" % (DirNum)
        else:
            DirName = "smal_dir_%04d" % (DirNum)
            
        print "Creating dir <%s>" % (DirName)
        try:
            os.mkdir(DirName)
        except:
            pass
        
        if (IsBigDir):
            FileName = "%s/big_file_%03d" % (DirName, DirNum)
            print "   creating file <%s>" % (FileName)
            # TODO Create a 10k file here
            l = list()
            for i in range(300):
                s = "This is file %s\n" % FileName
                l.append(s)
            f = open(FileName, "w")
            f.writelines(l)
            f.close()
            continue
            
        for FileNum in range(NUM_FILES):
            FileName = "%s/file_%04d" % (DirName, FileNum);
            print "   creating file <%s>" % (FileName)
            # TODO Create a small file here
            f = open(FileName, "w")
            f.write("This is file %s\n" % FileName)
            f.close()
        
    
    
if (__name__ == "__main__"):
    main()
        

