#!/usr/bin/env python

import sys
import serial
import argparse
from xmpp import Client, Debug

PORT_NAME = '/dev/ttyUSB0'
DEFAULT_JID = 'jid@jabber.org'
DEFAULT_JPWD = 'jabber_password'
DEFAULT_JABBER_SERVER = 'jabber.org'

cmd_index = {True : '0', False : '2'}
serial_port = PORT_NAME
online = True

class BuildServerStatus(object):
    PROJECT_NAME_INDEX = 1
    PROJECT_STATUS_INDEX = 4

    FAILURE_STATUSES = ["FAILURE", "STILL"]

    def __init__(self):
        self.builds = {}

    def process_message(self, message):
        project_name, project_status = self._parse_message(message)
        self.builds[project_name] = project_status

        print "--- Current build server status ---"
        print self.builds
        print "-----------------------------------"
        
        return all([v not in self.FAILURE_STATUSES for v in self.builds.values()])

    def _parse_message(self, message):
        index = message.find("Project")
        chunks = message[index:].split(" ")
        return chunks[1], chunks[4]

build_status = BuildServerStatus()
ser = None

def message_handler(con, event):
    print 'Got message', event
    type = event.getType()
    if type in ['message', 'chat', None]:
        message = event.getBody().strip()
    else:
        return # Unknown message
    status = build_status.process_message(message)

    command = cmd_index[status]
    rd = ''
    while (rd != 'r'):
        rd = ser.read(size = 1)
    rd = ''
    ser.timeout = 0.5
    while (rd != 'r'):
        ser.write(command)
        rd = ser.read(size = 1)        
            

def connect_jid(server, jid, password):
    print server, jid, password
    client = Client(server, debug=[])
    client.connect()
    if not client.auth(jid, password):
        raise IOError('Cannot connect to %s' % server)
    client.RegisterHandler('message', message_handler)
    return client

def main():
    parser = argparse.ArgumentParser(description='Build status indicator. Works together with Arduino based LED indicator')
    parser.add_argument('--port', '-p', default=PORT_NAME, dest='port', help='COM port on which Arduino board is present');
    parser.add_argument('--jid', '-j', default=DEFAULT_JID, dest='jid', help='Jabber ID that will be used for getting messages from build server');
    parser.add_argument('--password', '-P', default=DEFAULT_JPWD, dest='jpwd', help='Password for Jabber ID');
    parser.add_argument('--xmpp-server', '-s', default=DEFAULT_JABBER_SERVER, dest='server', help='XMPP server to connect');

    Debug.DEBUGGING_IS_ON = 0

    args = parser.parse_args()

    global ser
    ser = serial.Serial(args.port, 9600, timeout = 0)

    client = connect_jid(args.server, args.jid, args.jpwd)
    client.sendInitPresence(requestRoster=0)
    online = True

    while online:
        client.Process(1)
        if not client.isConnected():
            client.reconnectAndReauth()
    client.disconnect()

if __name__ == "__main__":
    main()



