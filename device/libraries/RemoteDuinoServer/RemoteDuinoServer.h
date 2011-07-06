#ifndef ___REMOTE_DUINO_SERVER__H___
#define ___REMOTE_DUINO_SERVER__H___

#include <WProgram.h>
#include <stl_config.h>
#include <serstream>
#include <sstream>
#include <string>
#include <stdint.h>
#include <vector>
#include <wiring.h>
#include <SPI.h>
#include <Ethernet.h>
#include <HardwareSerial.h>
#include <IRremote.h>

extern HardwareSerial Serial;

//#include <map>
using namespace std;

extern std::ohserialstream cout;

class BaseRemoteDuinoServer {
protected:
    vector<char> buf_vector;
    char* buf;
    int BUFSIZE;

	const char *ts;
	const char *te;
	const char *be;

	int cs;
	int have;
	int length;

    bool verbose;

    bool error;
    uint32_t currentNumber;
    int RECV_PIN;
    int STATUS_PIN;

    IRrecv irrecv;
    IRsend irsend;

    decode_results results;
public:
    BaseRemoteDuinoServer(int buffer_size, bool verbose = false) 
            : buf_vector(vector<char>(buffer_size)), verbose(verbose), 
                RECV_PIN(7), STATUS_PIN(13), irrecv(IRrecv(RECV_PIN)) {}

    bool get_error() const {
        return error;
    }

    void reset();

    uint32_t code;
    int protocol;
    string uri_action;

	virtual void begin();
    virtual void handle_error() { }
	virtual void parse();
    virtual void process_request();
    virtual int available() = 0;
    virtual int read_data(char *p, int const max_length) = 0;
    void sendCode(int protocol, uint32_t code, int code_length = 32);
};


class SerialRemoteDuinoServer : public BaseRemoteDuinoServer {
public:
    SerialRemoteDuinoServer(int buffer_size) :
        BaseRemoteDuinoServer(buffer_size) {}

    virtual int available();
    virtual int read_data(char *p, int const max_length);
};


class EthernetRemoteDuinoServer : public BaseRemoteDuinoServer {
    // Enter a MAC address and IP address for your controller below.
    // The IP address will be dependent on your local network:
    byte *mac; // = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
    byte *ip; // = { 192,168,1, 182 };

    // Initialize the Ethernet server library
    // with the IP address and port you want to use 
    // (port 80 is default for HTTP):
    Server server; //(80);
    Client client; // = server.available();
    bool _available;
public:
    EthernetRemoteDuinoServer(int buffer_size, byte *mac, byte *ip) :
        BaseRemoteDuinoServer(buffer_size), mac(mac), ip(ip),
        server(Server(80)), client(Client(MAX_SOCK_NUM)), _available(false) {}

	virtual void begin();
    virtual int available();
    virtual int read_data(char *p, int const max_length);
    virtual void process_request();
};


extern void *__bss_end;
extern void *__brkval;

int get_free_memory();

#if 0
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
#endif

#endif
