#!/usr/bin/python
#
# Test Program
#

import os


#
# Main Program
# 
include_dir = "/home/mjamet/src/src-ten-year/minix_common"
output_dir = "./obj";


print "We assume the test1 main is called test1.pas"
base_name = "second"

cpp_command = "cpp -I %s %s.pas %s/%s.p" % \
        (include_dir, base_name, output_dir, base_name)
print "Running : " + cpp_command
status = os.system(cpp_command)
print "   Status is : " + str(status)
if (status != 0):
    print "cpp failed!"
    exit(1)

test1_log = "%s/%s.log" % (output_dir, base_name)
pcomp_command = "pcomp.py %s/%s.p %s/%s.jam %s" % \
        (output_dir, base_name, output_dir, base_name, test1_log)
print "Running : " + pcomp_command
status = os.system(pcomp_command)
print "   Status is : " + str(status)
if (status != 0):
    print "Compilation Failed!  Showing log below..."
    print "========================================="
    tail_command = "tail -20 %s" % test1_log
    status = os.system(tail_command)
    exit(1)

jamasm_command = "jamasm.pl -outputformat 1 -srcfile %s/%s.jam -objfile %s/%s.hex -listfile %s/%s.lst -errorfile %s/%s.err " % \
        (output_dir, base_name, output_dir, base_name, output_dir, base_name, output_dir, base_name)
print "Running : " + jamasm_command
status = os.system(jamasm_command)
print "   Status is : " + str(status)
if (status != 0):
    print "jamasm failed - see log"
    exit(1)


