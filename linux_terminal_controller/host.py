#!/home/pjfd/anaconda/bin/python


import socket
from threading import Thread
import sys
import time

def listen_to_ptc(a):
    global ptc
    print 'Host Listening on 6000...'
    #All Communication with host is via port 6000.
    TCP_PORT = 6000
    TCP_IP = '127.0.0.1'
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind((TCP_IP, TCP_PORT))
    s.listen(5)
    ptc, addr = s.accept()
   #Receive data from ptc...
    cnt = 0
    while 1:
        msg = ''
        for k in range(256):
            c = ptc.recv(1)
            cnt += 1
            msg += c
            print c,
        print int(ord(msg[0]))
        print int(ord(msg[1]))
        print int(ord(msg[2]))
        for item in msg[3:]:
            if item == '\r':
                break
            #import pdb; pdb.set_trace()
            sys.stdout.write(item)
        print         
        


def send_to_ptc(a):
    while (1):
        inp = raw_input('::')
        for k in range(1):
            terminal = chr(int(inp[0]))
            inp += '\r'
            data = (len(inp) + 2) * [' ']
            data[0] = terminal
            data[1] = chr(len(inp))
            for c,char in enumerate(inp):
                data[2+c] = char
            msg = ''.join(data)
            ptc.send(msg)


if __name__ == '__main__':
    t = Thread(target=listen_to_ptc,args=(0,))
    t.start()

    t = Thread(target=send_to_ptc,args=(0,))
    t.start()
