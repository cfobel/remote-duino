#include "RemoteDuinoServer.h"


int SerialRemoteDuinoServer::available() {
    return Serial.available();
}


int SerialRemoteDuinoServer::read_data(char *p, int const max_length) {
    int curr_char = 0;
    bool currentLineIsBlank = true;
    while(Serial.available()) {
        p[curr_char] = Serial.read();
        char &c = p[curr_char];
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
        if(curr_char >= max_length) {
            break;
        }
        delay(20);
    }
    return curr_char;
}
