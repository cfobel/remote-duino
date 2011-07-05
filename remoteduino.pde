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

#include <SPI.h>
#include <Ethernet.h>
#include <RemoteDuinoServer.h>
#include <IRremote.h>

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192,168,1, 182 };

// Initialize the Ethernet server library
// with the IP address and port you want to use 
// (port 80 is default for HTTP):
Server server(80);

int RECV_PIN = 7;
int STATUS_PIN = 13;

IRrecv irrecv(RECV_PIN);
IRsend irsend;

decode_results results;

std::ohserialstream cout(Serial);
std::ihserialstream serial_in(Serial);

void init_ethernet()
{
  pinMode(8, OUTPUT);
  digitalWrite(8, LOW);   // set the LED on
  delay(2000);              // wait for a second
  digitalWrite(8, HIGH);    // set the LED off
  delay(1000);              // wait for a second
  // start the Ethernet connection and the server:
  Ethernet.begin(mac, ip);
  server.begin();
}

extern void *__bss_end;
extern void *__brkval;

int get_free_memory() {
    int free_memory;

    if((int)__brkval == 0)
        free_memory = ((int)&free_memory) - ((int)__bss_end);
    else
        free_memory = ((int)&free_memory) - ((int)__brkval);

    return free_memory;
}

void setup() {
    init_ethernet();
    Serial.begin(9600);
    irrecv.enableIRIn(); // Start the receiver
    pinMode(STATUS_PIN, OUTPUT);
    cout << "starting up..." << endl;
    cout << get_free_memory() << endl;
}

// Storage for the recorded code
int codeType = -1; // The type of code
unsigned long codeValue; // The code value if not raw
unsigned int rawCodes[RAWBUF]; // The durations if raw
int codeLen; // The length of the code
int toggle = 0; // The RC5/6 toggle state

// Stores the code for later playback
// Most of this code is just logging
void storeCode(decode_results *results) {
  codeType = results->decode_type;
  int count = results->rawlen;
  if (codeType == UNKNOWN) {
    cout << "Received unknown code, saving as raw" << endl;
    codeLen = results->rawlen - 1;
    // To store raw codes:
    // Drop first value (gap)
    // Convert from ticks to microseconds
    // Tweak marks shorter, and spaces longer to cancel out IR receiver distortion
    for (int i = 1; i <= codeLen; i++) {
      if (i % 2) {
        // Mark
        rawCodes[i - 1] = results->rawbuf[i]*USECPERTICK - MARK_EXCESS;
        cout << " m";
      } 
      else {
        // Space
        rawCodes[i - 1] = results->rawbuf[i]*USECPERTICK + MARK_EXCESS;
        cout << " s";
      }
      Serial.print(rawCodes[i - 1], DEC);
    }
    cout << "" << endl;
  }
  else {
    if (codeType == NEC) {
      cout << "Received NEC: ";
      if (results->value == REPEAT) {
        // Don't record a NEC repeat value as that's useless.
        cout << "repeat; ignoring." << endl;
        return;
      }
    } 
    else if (codeType == SONY) {
      cout << "Received SONY: ";
    } 
    else if (codeType == RC5) {
      cout << "Received RC5: ";
    } 
    else if (codeType == RC6) {
      cout << "Received RC6: ";
    } 
    else {
      cout << "Unexpected codeType ";
      Serial.print(codeType, DEC);
      cout << "" << endl;
    }
    Serial.println(results->value, HEX);
    codeValue = results->value;
    codeLen = results->bits;
  }
}

void sendCode(int protocol, uint32_t code, int code_length = 32) {
    if(protocol == NEC) {
        irsend.sendNEC(code, code_length);
        cout << "Sent NEC ";
        Serial.println(code, HEX);
    } else if(protocol == SONY) {
        irsend.sendSony(code, code_length);
        cout << "Sent Sony ";
        Serial.println(code, HEX);
    } else if (codeType == RC5) {
        cout << "Sent RC5 ";
        Serial.println(code, HEX);
        irsend.sendRC5(code, code_length);
    } else if (codeType == RC6) {
        irsend.sendRC6(code, code_length);
        cout << "Sent RC6 ";
        Serial.println(code, HEX);
    } else {
    //else if (protocol == UNKNOWN /* i.e. raw */) {
        // Assume 38 KHz
        //irsend.sendRaw(rawCodes, codeLen, 38);
        Serial.println("Unkown protocol");
    }
}

typedef char buff_char_t;
buff_char_t buffer[400];

int read_data() {
    int curr_char = 0;
    boolean currentLineIsBlank = true;
    while(Serial.available()) {
        buffer[curr_char] = Serial.read();
        buff_char_t &c = buffer[curr_char];
        curr_char++;
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
            break;
        }
        if (c == '\n') {
            // you're starting a new line
            currentLineIsBlank = true;
        } 
        else if (c != '\r') {
            // you've gotten a character on the current line
            currentLineIsBlank = false;
        }
        delay(10);
    }
    return curr_char;
}

int read_request(Client &client) {
    // an http request ends with a blank line
    int curr_char = 0;
    boolean wait_for_data = true;
    while (client.connected()) {
        if (client.available()) {
            buffer[curr_char] = client.read();
            buff_char_t &c = buffer[curr_char];
            curr_char++;
        } else if(wait_for_data) {
            delay(10);
            wait_for_data = false;
        } else {
            break;
        }
    }
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
    return curr_char;
}

void loop() {
    // listen for incoming clients
    Client client = server.available();
    RemoteDuinoServer RDServer;
    if (client) {
        Serial.println("gclient request");

        int length = read_request(client);
        cout << "got " << length << " bytes." << endl;
        RDServer.parse_microscript(&buffer[0], length);
        // send a standard http response header
        cout << get_free_memory() << endl;
        bool err = RDServer.get_error();
        if(err) {
            for(int i = 0; i < length; i++) {
                cout.write(&buffer[i], 1);
            }
        } else {
            /*
            for(int i = 0; i < RDServer.keys.size(); i++) {
                cout << RDServer.keys[i] << ": " << RDServer.values[i] << endl;
            }
            */
            cout << "code:" << RDServer.code << endl;
            cout << "protocol:" << RDServer.protocol << endl;
            // output the value of each analog input pin
            digitalWrite(STATUS_PIN, HIGH);
            for(int i = 0; i < 3; i++) {
                sendCode(RDServer.protocol, RDServer.code);
            }
            digitalWrite(STATUS_PIN, LOW);
            delay(50); // Wait a bit between retransmissions
            irrecv.enableIRIn(); // Re-enable receiver
#if 0
#endif
        }
    } 
    else if (irrecv.decode(&results)) {
        digitalWrite(STATUS_PIN, HIGH);
        storeCode(&results);
        irrecv.resume(); // resume receiver
        digitalWrite(STATUS_PIN, LOW);
    }
}


void RemoteDuinoServer::handle_error() {
    cout << "ERR:" << endl;
}
