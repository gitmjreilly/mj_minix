#!/usr/bin/python
""" TCP based disk controller """

import sys
import socket
import select
from time import sleep

# Constants
SECTOR_SIZE = 512

  
def create_test_file(file_name):
    print "Creating a dummy test file : %s" % file_name
    f = open(file_name, "w+")
    for ch in range(48, 123):
        data = 512 * [chr(ch)]
        s = "".join(data)
        f.write(s)
        f.flush()
    f.close()
  
#   
# Main Program is Here
#
def main():

    disk_file_name = raw_input("Enter (new) disk file name >")    
    create_test_file(disk_file_name)
        
    
    
if (__name__ == "__main__"):
    main()
        

