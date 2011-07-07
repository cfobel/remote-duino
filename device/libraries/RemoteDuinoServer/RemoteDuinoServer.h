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
    enum { SEND_CODE, LEARN_CODE };

    // Storage for the recorded code
    int codeType; // The type of code
    unsigned long codeValue; // The code value if not raw
    unsigned int rawCodes[RAWBUF]; // The durations if raw
    int codeLen; // The length of the code
    int toggle; // The RC5/6 toggle state

    void process_action(uint8_t action);
    void store_code(decode_results *results);
    virtual void handle_error() { }
	virtual void parse();
    virtual void learn_code();
    virtual int read_data(char *p, int const max_length) = 0;
    void sendCode(int protocol, uint32_t code, int code_length = 32);
public:
    BaseRemoteDuinoServer(int buffer_size, bool verbose = false) 
            : buf_vector(vector<char>(buffer_size)), verbose(verbose), 
                RECV_PIN(7), STATUS_PIN(13), irrecv(IRrecv(RECV_PIN)),
                codeType(-1), toggle(0) {}

    bool get_error() const {
        return error;
    }

    void reset();

    uint32_t code;
    int protocol;
    uint8_t uri_action;

	virtual void begin();
    virtual void process_request();
    virtual int available() = 0;
};


class SerialRemoteDuinoServer : public BaseRemoteDuinoServer {
protected:
    virtual int read_data(char *p, int const max_length);
public:
    SerialRemoteDuinoServer(int buffer_size) :
        BaseRemoteDuinoServer(buffer_size) {}

    virtual int available();
};


class EthernetRemoteDuinoServer : public BaseRemoteDuinoServer {
protected:
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
    void report_code();
    virtual int read_data(char *p, int const max_length);
    virtual void learn_code();
public:
    EthernetRemoteDuinoServer(int buffer_size, byte *mac, byte *ip) :
        BaseRemoteDuinoServer(buffer_size), mac(mac), ip(ip),
        server(Server(80)), client(Client(MAX_SOCK_NUM)), _available(false) {}

	virtual void begin();
    virtual int available();
    virtual void process_request();
};


extern void *__bss_end;
extern void *__brkval;

int get_free_memory();


#endif
