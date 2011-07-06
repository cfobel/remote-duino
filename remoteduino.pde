#include <stl_config.h>
#include <new.cpp>
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <serstream>
#include <iomanip>
#include <sstream>
using namespace std;

/*
 * IRrecord: record and play back IR signals as a minimal 
 * An IR detector/demodulator must be connected to the input RECV_PIN.
 * An IR LED must be connected to the output PWM pin 3.
 * A button must be connected to the input BUTTON_PIN; this is the
 * send button.
 * A visible LED can be connected to STATUS_PIN to provide status.
 *
 * The logic is:
 * If the button is pressed, send the IR code.
 * If an IR code is received, record it.
 *
 * Version 0.11 September, 2009
 * Copyright 2009 Ken Shirriff
 * http://arcfn.com
 */

#if 0
#include <SPI.h>
#include <Ethernet.h>
#endif
#include <IRremote.h>
#include <RemoteDuinoServer.h>

#if 0
// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192,168,1, 182 };

// Initialize the Ethernet server library
// with the IP address and port you want to use 
// (port 80 is default for HTTP):
Server server(80);
#endif

std::ohserialstream cout(Serial);
std::ihserialstream serial_in(Serial);

void init_ethernet()
{
  pinMode(8, OUTPUT);
  digitalWrite(8, LOW);   // set the LED on
  delay(2000);              // wait for a second
  digitalWrite(8, HIGH);    // set the LED off
  delay(1000);              // wait for a second
#if 0
  // start the Ethernet connection and the server:
  Ethernet.begin(mac, ip);
  server.begin();
#endif
}

void setup() {
    init_ethernet();
    Serial.begin(9600);
    cout << "starting up..." << endl;
    cout << get_free_memory() << endl;
}


void loop() {
#if 0
    // listen for incoming clients
    Client client = server.available();
    RemoteDuinoServer RDServer;
    if (client) {
#endif
    SerialRemoteDuinoServer RDServer(50);
    if(RDServer.available()) {
        RDServer.process_request();
    }
#if 0
#if 0
        // send a standard http response header
        client.println("HTTP/1.1 200 OK");
        client.println("Content-Type: text/html");
        client.println();
        if(err) {
            client.println("<h1>ERROR</h1>");
            for(int i = 0; i < length; i++) {
                cout.write(&buffer[i], 1);
            }
        } else {
            /*
            for(int i = 0; i < RDServer.keys.size(); i++) {
                cout << RDServer.keys[i] << ": " << RDServer.values[i] << endl;
            }
            */
            cout << "action:" << RDServer.uri_action << endl;
            cout << "code:" << RDServer.code << endl;
            cout << "protocol:" << RDServer.protocol << endl;
            client.println("<h1>OK</h1>");
            // output the value of each analog input pin
            digitalWrite(STATUS_PIN, HIGH);
            for(int i = 0; i < 3; i++) {
                sendCode(RDServer.protocol, RDServer.code);
            }
            digitalWrite(STATUS_PIN, LOW);
            delay(50); // Wait a bit between retransmissions
            irrecv.enableIRIn(); // Re-enable receiver
        }
        delay(1);
        // close the connection:
        client.stop();
#endif
    } else if (irrecv.decode(&results)) {
        digitalWrite(STATUS_PIN, HIGH);
        storeCode(&results);
        irrecv.resume(); // resume receiver
        digitalWrite(STATUS_PIN, LOW);
    }
#endif
}
