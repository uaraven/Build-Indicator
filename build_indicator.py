#!/usr/bin/env python

import sys
import serial
import argparse

PORT_NAME = '/dev/ttyUSB0'

cmd_index = {'reset' : '3', 'success' : '0', 'in_progress' : '1', 'failed' : '2'}

def main():
	parser = argparse.ArgumentParser(description='Build status indicator. Works together with Arduino based LED indicator')
	parser.add_argument('--port', '-p', default=PORT_NAME, dest='port', help='COM port on which Arduino board is present');
	parser.add_argument('command', default='-', help='Command to send to Arduino board', nargs=1, 
	    choices=['success', 'in_progress', 'failed', 'reset'])
	    
	args = parser.parse_args()
	cmd = cmd_index[args.command[0]]
	port = args.port
	ser = serial.Serial(port, 9600)
	ser.setDTR(False)
	rd = ''
	print 'Waiting for board'
	while (rd != 'r'):
		rd = ser.read(size = 1)
	ser.write(cmd)
	ser.flush()
	ser.close()
	print 'Sent',cmd

if __name__ == "__main__":
	main()



