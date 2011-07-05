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

#include <RemoteDuinoServer.h>
#include <IRremote.h>

int RECV_PIN = 11;
int STATUS_PIN = 13;

IRrecv irrecv(RECV_PIN);
IRsend irsend;

decode_results results;

std::ohserialstream cout(Serial);
std::ihserialstream serial_in(Serial);
RemoteDuinoServer RDServer;

void setup() {
    Serial.begin(9600);
    irrecv.enableIRIn(); // Start the receiver
    pinMode(STATUS_PIN, OUTPUT);
    cout << "starting up..." << endl;
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

void sendCode(int repeat) {
  if (codeType == NEC) {
    if (repeat) {
      irsend.sendNEC(REPEAT, codeLen);
      cout << "Sent NEC repeat" << endl;
    } 
    else {
      irsend.sendNEC(codeValue, codeLen);
      cout << "Sent NEC ";
      Serial.println(codeValue, HEX);
    }
  } 
  else if (codeType == SONY) {
    irsend.sendSony(codeValue, codeLen);
    cout << "Sent Sony ";
    Serial.println(codeValue, HEX);
  } 
  else if (codeType == RC5 || codeType == RC6) {
    if (!repeat) {
      // Flip the toggle bit for a new button press
      toggle = 1 - toggle;
    }
    // Put the toggle bit into the code to send
    codeValue = codeValue & ~(1 << (codeLen - 1));
    codeValue = codeValue | (toggle << (codeLen - 1));
    if (codeType == RC5) {
      cout << "Sent RC5 ";
      Serial.println(codeValue, HEX);
      irsend.sendRC5(codeValue, codeLen);
    } 
    else {
      irsend.sendRC6(codeValue, codeLen);
      cout << "Sent RC6 ";
      Serial.println(codeValue, HEX);
    }
  } 
  else if (codeType == UNKNOWN /* i.e. raw */) {
    // Assume 38 KHz
    irsend.sendRaw(rawCodes, codeLen, 38);
    Serial.println("Sent raw");
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

void loop() {
    if(Serial.available()) {
        cout << "data:" << endl;
        int length = read_data();
        RDServer.parse_microscript(&buffer[0], length, 1);
        // send a standard http response header
        cout << "free mem: " << get_free_memory() << endl;
        cout << "error? " << RDServer.get_error() << endl;

        // output the value of each analog input pin
        //cout.write(&buffer[0], length);
#if 0
        digitalWrite(STATUS_PIN, HIGH);
        for(int i = 0; i < 3; i++) {
            sendCode(false);
        }
        digitalWrite(STATUS_PIN, LOW);
        delay(50); // Wait a bit between retransmissions
        irrecv.enableIRIn(); // Re-enable receiver
#endif
    } 
    else if (irrecv.decode(&results)) {
        digitalWrite(STATUS_PIN, HIGH);
        storeCode(&results);
        irrecv.resume(); // resume receiver
        digitalWrite(STATUS_PIN, LOW);
    }
}
