#include "RemoteDuinoServer.h"

int EthernetRemoteDuinoServer::available() {
    if(!_available) {
        // listen for incoming clients
        client = server.available();
        _available = (true && client);
    }
    return _available;
}


void EthernetRemoteDuinoServer::begin() {
    BaseRemoteDuinoServer::begin();
    pinMode(8, OUTPUT);
    digitalWrite(8, LOW);   // turn on Ethernet reset
    delay(1000);              // wait for a second
    digitalWrite(8, HIGH);    // turn off Ethernet reset
    delay(1000);              // wait for a second
    // start the Ethernet connection and the server:
    Ethernet.begin(mac, ip);
    server.begin();
}


void EthernetRemoteDuinoServer::process_request() {
    if(!_available) return;

    // send a standard http response header
    client.println("HTTP/1.1 200 OK");
    client.println("Content-Type: text/html");
    client.println();

    BaseRemoteDuinoServer::process_request();

    if(error) {
        client.println("<h1>ERROR</h1>");
    } else {
        client.println("<h1>OK</h1>");
    }
    delay(1);
    // close the connection:
    client.stop();
    _available = false;
}


int EthernetRemoteDuinoServer::read_data(char *p, int const max_length) {
    // an http request ends with a blank line
    int curr_char = 0;
    boolean wait_for_data = true;
    while(client.connected()) {
        if(client.available()) {
            p[curr_char] = client.read();
            char &c = p[curr_char];
            curr_char++;
            if(curr_char >= max_length) {
                break;
            }
        } else if(wait_for_data) {
            delay(10);
            wait_for_data = false;
        } else {
            break;
        }
    }
    return curr_char;
}


// Write learned code to client
void EthernetRemoteDuinoServer::report_code() {
    if (codeType == UNKNOWN) {
        client.println("<p>Received unknown code, saving as raw</p><p>");
        // To store raw codes:
        // Drop first value (gap)
        // Convert from ticks to microseconds
        // Tweak marks shorter, and spaces longer to cancel out IR receiver distortion
        for(int i = 1; i <= codeLen; i++) {
            if(i % 2) {
                // Mark
                client.print(" m");
            } else {
                // Space
                client.print(" s");
            }
            client.print(rawCodes[i - 1], DEC);
        }
        client.println("</p>");
    } else {
        if (codeType == NEC) {
            client.println("<p>Received NEC: ");
            if (codeValue == REPEAT) {
                // Don't record a NEC repeat value as that's useless.
                client.println("repeat; ignoring.</p>");
                return;
            }
        } else if (codeType == SONY) {
            client.println("<p>Received Sony: ");
        } else if (codeType == RC5) {
            client.println("<p>Received RC5: ");
        } else if (codeType == RC6) {
            client.println("<p>Received RC6: ");
        } else {
            client.println("<p>Unexpected codeType ");
            client.print(codeType, DEC);
            client.println("</p>");
        }
        client.println("<h2>");
        client.println(codeValue, HEX);
        client.println("</h2>");
    }
}


void EthernetRemoteDuinoServer::learn_code() {
    BaseRemoteDuinoServer::learn_code();
    report_code();
}
