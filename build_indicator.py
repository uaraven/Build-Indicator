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
	ser = serial.Serial(args.port, 9600, timeout = 0)
	rd = ''
	print 'Waiting for board'
	while (rd != 'r'):
		rd = ser.read(size = 1)
	rd = ''
	ser.timeout = 0.5
	while (rd != 'r'):
	    ser.write(cmd)
            rd = ser.read(size = 1)


if __name__ == "__main__":
	main()



