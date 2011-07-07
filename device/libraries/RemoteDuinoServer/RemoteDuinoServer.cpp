#include "RemoteDuinoServer.h"

extern "C" void __cxa_pure_virtual(void);
void __cxa_pure_virtual(void) {} 


int get_free_memory() {
    int free_memory;

    if((int)__brkval == 0)
        free_memory = ((int)&free_memory) - ((int)__bss_end);
    else
        free_memory = ((int)&free_memory) - ((int)__brkval);

    return free_memory;
}


void BaseRemoteDuinoServer::begin() {
    //irrecv.enableIRIn(); // Start the receiver
    pinMode(STATUS_PIN, OUTPUT);
    buf = &buf_vector[0];
    BUFSIZE = buf_vector.size();
    reset();
}


void BaseRemoteDuinoServer::sendCode(int protocol, uint32_t code, int code_length) {
    if(protocol == NEC) {
        irsend.sendNEC(code, code_length);
        cout << "Sent NEC ";
        Serial.println(code, HEX);
    } else if(protocol == SONY) {
        irsend.sendSony(code, code_length);
        cout << "Sent Sony ";
        Serial.println(code, HEX);
    } else if(protocol == RC5) {
        cout << "Sent RC5 ";
        Serial.println(code, HEX);
        irsend.sendRC5(code, code_length);
    } else if(protocol == RC6) {
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


void BaseRemoteDuinoServer::process_action(uint8_t action) {
    switch(action) {
        case SEND_CODE:
            cout << "code:" << code << endl;
            cout << "protocol:" << protocol << endl;
            // output the value of each analog input pin
            for(int i = 0; i < 3; i++) {
                sendCode(protocol, code);
            }
            break;
        case LEARN_CODE:
            learn_code();
            break;
        default:
            break;
    }
    delay(50);
}


void BaseRemoteDuinoServer::process_request() {
    if(available()) {
        parse();
        // send a standard http response header
        cout << get_free_memory() << endl;
        bool err = get_error();
        if(err) {
            cout << "Error parsing" << endl;
            return;
        } 

        cout << "Parse succesful" << endl;
        cout << "action:" << (int)uri_action << endl;
        process_action(uri_action);
    }
}

void BaseRemoteDuinoServer::learn_code() {
    irrecv.enableIRIn(); // Re-enable receiver
    while(!irrecv.decode(&results)) {
        delay(50);
    }
    store_code(&results);
    irrecv.resume(); // resume receiver
}


// Stores the code for later playback
// Most of this code is just logging
void BaseRemoteDuinoServer::store_code(decode_results *results) {
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
    } else {
        if (codeType == NEC) {
            cout << "Received NEC: ";
            if (results->value == REPEAT) {
                // Don't record a NEC repeat value as that's useless.
                cout << "repeat; ignoring." << endl;
                return;
            }
        } else if (codeType == SONY) {
            cout << "Received SONY: ";
        } else if (codeType == RC5) {
            cout << "Received RC5: ";
        } else if (codeType == RC6) {
            cout << "Received RC6: ";
        } else {
            cout << "Unexpected codeType ";
            Serial.print(codeType, DEC);
            cout << "" << endl;
        }
        Serial.println(results->value, HEX);
        codeValue = results->value;
        codeLen = results->bits;
    }
}


