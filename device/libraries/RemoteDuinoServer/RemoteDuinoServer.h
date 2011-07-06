#include <stl_config.h>
#include <iostream>
#include <string>
#include <stdint.h>
#include <vector>
#include <wiring.h>
#include <HardwareSerial.h>

extern HardwareSerial Serial;

//#include <map>
using namespace std;

//typedef std::map<string, string> key_val_map_t;

class RemoteDuinoServer {
    vector<char> buf_vector;
    char* buf;
    int BUFSIZE;

	const char *ts;
	const char *te;
	const char *be;

	int cs;
	int have;
	int length;

    bool error;
    uint32_t currentNumber;
public:
    RemoteDuinoServer(int buffer_size) {
        buf_vector = vector<char>(buffer_size);
        init();
    }
    bool get_error() const {
        return error;
    }
    void reset() {
        ts = NULL;
        error = false;
        currentNumber = 0;
    }
	void init();
	void parse();
    void handle_error();

    int available();
    int read_data(char *p, int const max_length);
    void process_request();

    uint32_t code;
    int protocol;
    string uri_action;
};
