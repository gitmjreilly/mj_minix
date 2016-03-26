import SocketServer
import socket
from threading import Thread
import sys

#PTC  IS AT PORT 5050.
#HOST IS AT PORT 6000.
HOST_PORT = 6001

requests    = 16 * [0]
connections = 0

class service(SocketServer.BaseRequestHandler):
    def handle(self):
        global connections
        global requests
        
        terminal_char = 'dummy'
        print "Client connected with ", self.client_address
        requests[connections] = self.request    
        terminal = connections
        connections += 1

        req = self.request
        msg = list()
        
        # First cnt bytes are header so start at cnt (0..cnt-1 are header) 
        # payload is built up in msg
        # terminal_char is single byte
        while 1:
            terminal_char = self.request.recv(1)
            msg.append(terminal_char)


            # try:
                # if ord(terminal_char) == 127:
                    # cnt -= 1
                # else:    
                    # msg[cnt] = terminal_char
                    # cnt += 1
            # except:
                # continue


            # Echo character to terminal.
            self.request.send(terminal_char)

            if terminal_char == '\r':
                # If we got \r, build up header and message and send to host
            
                sequence_num = 0
                header = list()
                header[0] = chr(1)
                header[1] = chr(terminal)
                header[2] = chr(len(msg))
                header[3] = chr(sequence_num)
                
                
                out_msg = ''.join(header) + ''.join(msg)
                out_msg += 256 * ' '
                print '  Term Write :  <%04X>  msg len <%04X> seq <%04X>'  % (terminal, len(msg), sequence_num)
                out_msg = out_msg[0:256]
                for ch in out_msg:
                    host.send(ch)
                self.request.send('\n')
                msg = list()
                
        print "Client exited"
        self.request.close()


def get_from_host(a):
    global host
    print 'PTC connecting to host...'

    host = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    host.connect(('127.0.0.1', HOST_PORT))

    while (1):
        terminal = ord(host.recv(1))
        cnt = ord(host.recv(1))
        seq_num = ord(host.recv(1))

        print "  host write: term :    <%04X>  cnt < %04X> seq <%04X>" % (terminal, cnt, seq_num)
        
        s = ''
        for k in range(cnt):
            s += host.recv(1)
            
        req = requests[terminal]
        req.send(s)
        #send acknowledgement
        ack = chr(2) + chr(terminal) + chr(seq_num) + chr(20) + 'This is ack...\r' + 256 * ' '
        ack = ack[0:256]
        for ch in ack:
            host.send(ch)
        print "    PTC write ack: term <%04X>   seq <%04X> header <%02X>" % (terminal, seq_num, ord(ack[0]))

    

class ThreadedTCPServer(SocketServer.ThreadingMixIn, SocketServer.TCPServer):
    pass

# t = ThreadedTCPServer(('',5050), service)
t = ThreadedTCPServer(('', 4659), service)
q = Thread(target=get_from_host,args=(0,))
q.start()
t.serve_forever()


