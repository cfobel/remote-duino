import serial
import time

def test_serial():
    s.write('GET /?c=0x01&p=1 blah' + 200 * '-')
    time.sleep(2)
    print ''.join(s.readlines())

if __name__ == '__main__':
    s = serial.Serial(port='/dev/ttyUSB0')
    s.setTimeout(1)
    time.sleep(1)
    print ''.join(s.readlines())
