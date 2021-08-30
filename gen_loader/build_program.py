#!/usr/bin/python
#

import os
import sys

def usage():
   print("USAGE: %s BaseName (e.g. main not main.pas)" % (sys.argv[0]))



#
# Main Program
# 

if (len(sys.argv) != 2):
   usage()
   sys.exit(1)


include_dir = "../minix_common"
output_dir = "./obj";
rm_command = "/bin/rm -f %s/*" % (output_dir)
print "rm command is [%s]" % rm_command
status = os.system(rm_command)
print "   Status is : " + str(status)
if (status != 0):
    print "command failed"
    exit(1)


base_name = sys.argv[1]

# base_name = base_no_pas + ".pas"
#print "Base name is [%s]" % (base_name)

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


