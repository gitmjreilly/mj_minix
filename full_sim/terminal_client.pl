#!/usr/bin/perl

use strict;
use IO::Socket;
use Term::ReadKey;


# Handle for socket communication
my $handle;
my $ChildPID;



#####################################################################
sub ChildExitHandler {
   system("stty sane");
   printf("Child has exited.  Will wait() for it...\n");
   wait();
   printf("Finished waiting\n");
   exit(0);
}
#####################################################################

#####################################################################
# Run local menu 
# Should only be run from chile
sub menu {
my $ch;
my $tmp;

    ReadMode("normal");

    printf("This is a test menu, running locally...\n");
    printf("r - return to terminal\n");
    printf("f - send file to sim\n");
    printf("z - exit program\n");
    printf("local menu >");
    chomp($ch = <STDIN>);
    printf("$ch\n");
    if ($ch eq 'z') { exit(0) } 

    elsif ($ch eq 'f') {
        printf("Enter filename >");
        chomp(my $fileName = <STDIN>);
        open (SEND_FILE, "<$fileName");
        binmode(SEND_FILE);
        my $fileLength = sysread(SEND_FILE, $tmp, 1000000);
        printf("File length is %d\n", $fileLength);
        printf("*** Sending...");
        print $handle $tmp;
        printf("Finished.\n");
        close(SEND_FILE);
    }

    ReadMode("ultra-raw");
}
#####################################################################


#####################################################################
#
# Main Program
#
if ($#ARGV != 1) {
    printf("Usage: $0   hostname|IP    port\n");
    exit(1);
}
(my $host, my $port) = @ARGV;

$handle = IO::Socket::INET->new(Proto     => "tcp",
                                 PeerAddr  => $host,
                                 PeerPort  => $port)
        or die "can't connect to port $port on $host: $!";

# so output gets there right away
$handle->autoflush(1);

printf(STDERR "[Connected to $host:$port]\n");

#
# Fork so there are 2 processes
#   The parent reads from the socket and prints the results
#   The child reads from standard in and sends the result over the socket
#

$SIG{'CHLD'} = \&ChildExitHandler;

$ChildPID = fork();

if ($ChildPID) {
    $| = 1;
    # This is the PARENT
    my $byte;
    while (sysread($handle, $byte, 1) == 1) {
        print STDOUT $byte;
        if (ord($byte) == 10) { 
            print STDOUT chr(13);
        }
    }

     #
     # If we got this far, the remote side closed the connection
     # so we kill our own child.
     kill("TERM", $ChildPID);
     system("stty sane");
     exit
 }
 else {
     # This is the child
     #
     # Take all input from stdin w/o alteration
     # See CPAN Term::ReadKey for details on modes
     #
     printf("\nStarting child which reads from STDIN (press <ESC> to end) \n");

     my $ch;
     ReadMode("ultra-raw");
     while (1) {
         $ch = ReadKey(0) ;
         if (ord($ch) == 27) {
             menu();
             next;
         }
         if (ord($ch) == 127) {
            $ch = chr(8)
        }
        printf($handle "%s", $ch);
         # print $handle $ch;
     }
 }
