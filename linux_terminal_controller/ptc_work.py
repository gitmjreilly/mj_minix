import SocketServer
import socket
from threading import Thread
import sys

#PTC  IS AT PORT 5050.
#HOST IS AT PORT 6000.

requests    = 16 * [0]
connections = 0

class service(SocketServer.BaseRequestHandler):
    def handle(self):
        global connections
        global requests
        
        data = 'dummy'
        print "Client connected with ", self.client_address
        requests[connections] = self.request    
        terminal = connections
        connections += 1

        req = self.request
        msg = 256 * [' ']
        cnt = 3
        while 1:
            data = self.request.recv(1)
            try:
                if ord(data) == 127:
                    cnt -= 1
                else:    
                    msg[cnt] = data
                    cnt += 1
            except:
                continue
            #Echo character to terminal.
            self.request.send(data.upper())
            if data == '\r':
                msg[0] = chr(1)
                msg[1] = chr(terminal)
                msg[2] = chr(cnt - 3)
                out_msg = ''.join(msg[0:cnt])
                out_msg += '\r'
                out_msg += 256 * ' '
                print 'MESSAGE: '+ out_msg[0:cnt]
                out_msg = out_msg[0:256]
                for ch in out_msg:
                    host.send(ch)
                self.request.send('\n')
                msg = 256 * [' ']
                cnt = 3
                
        print "Client exited"
        self.request.close()


def get_from_host(a):
    global host
    print 'PTC connecting to host...'
    host = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    host.connect(('127.0.0.1',6000))
    while (1):
        term = host.recv(1)
        terminal = ord(term)
        cnt = ord(host.recv(1))
        s = ''
        for k in range(cnt):
            s += host.recv(1)
	print 'Terminal: %d' % terminal
        req = requests[terminal]
        data = s[0:cnt]
        req.send(data)
        #send acknowledgement
        ack = chr(2)+chr(terminal) + chr(20) + 'This is ack...\r' + 256 * ' '
        ack = ack[0:256]
        for ch in ack:
            print ch
            host.send(ch)
        print 'Sent ack...'

    

class ThreadedTCPServer(SocketServer.ThreadingMixIn, SocketServer.TCPServer):
    pass

t = ThreadedTCPServer(('',5050), service)
q = Thread(target=get_from_host,args=(0,))
q.start()
t.serve_forever()


