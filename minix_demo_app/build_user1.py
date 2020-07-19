#!/usr/bin/python
#
# Compile mj_minix demo program
#

import os


#
# Main Program
# 
base_name = "user1"
include_dir = "/home/mj/mint_2016/repo/minix_common"
output_dir = "./obj"

rm_command = "/bin/rm -f %s/*" % (output_dir)
print "rm command is [%s]" % rm_command
status = os.system(rm_command)
print "   Status is : " + str(status)
if (status != 0):
    print "command failed"
    exit(1)


print "We assume the program is called %s.pas" % (base_name)

pascal_src_name = base_name + ".pas"
cpp_output_name = output_dir + "/" + base_name + ".p"
cpp_command = "cpp -I %s %s %s" % \
        (include_dir, pascal_src_name, cpp_output_name)
print "Running : " + cpp_command
status = os.system(cpp_command)
print "   Status is : " + str(status)
if (status != 0):
    print "cpp failed!"
    exit(1)

jam_output_name = output_dir + "/" + base_name + ".jam"
log_output_name = output_dir + "/" + base_name + ".log"
pcomp_command = "pcomp.py %s %s %s" % \
        (cpp_output_name , jam_output_name, log_output_name)
print "Running : " + pcomp_command
status = os.system(pcomp_command)
print "   Status is : " + str(status)

if (status != 0):
    print "Compilation Failed!  Showing log below..."
    print "========================================="
    tail_command = "tail -20 %s" % log_output_name
    status = os.system(tail_command)
    exit(1)




hex_output_name = output_dir + "/" + base_name + ".hex"
list_output_name = output_dir + "/" + base_name + ".lst"
error_output_name = output_dir + "/" + base_name + ".err"
jamasm_command = "jamasm.pl -outputformat 3 -srcfile %s -objfile %s -listfile %s -errorfile %s " % \
        (jam_output_name, hex_output_name, list_output_name, error_output_name)
print "Running : " + jamasm_command
status = os.system(jamasm_command)
print "   Status is : " + str(status)
if (status != 0):
    print "jamasm failed - see log"
    exit(1)


