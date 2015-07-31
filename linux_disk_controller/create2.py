#!/usr/bin/python
""" TCP based disk controller """

import sys
import os

# Constants
NUM_DIRS = 1
NUM_FILES = 700


#   
# Main Program is Here
#
def main():

    for DirNum in range(NUM_DIRS):

        DirName = "fat_dir_%04d" % (DirNum)
            
        print "Creating dir <%s>" % (DirName)
        try:
            os.mkdir(DirName)
        except:
            pass
        
        for FileNum in range(NUM_FILES):
            FileName = "%s/file_%04d" % (DirName, FileNum);
            print "   creating file <%s>" % (FileName)
            # TODO Create a small file here
            f = open(FileName, "w")
            f.write("This is file %s\n" % FileName)
            f.close()
        
    
    
if (__name__ == "__main__"):
    main()
        

