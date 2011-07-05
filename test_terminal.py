import serial
import time


if __name__ == '__main__':
    s = serial.Serial(port='/dev/ttyUSB0')
    s.setTimeout(1)
