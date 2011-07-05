#include <stl_config.h>
#include <iostream>
#include <string>
#include <stdint.h>
#include <vector>
//#include <map>
using namespace std;

//typedef std::map<string, string> key_val_map_t;

class RemoteDuinoServer {
private:
    char const *ts;
    char const *us;
    char const *ks;
    uint8_t cs; /* The current parser state */
    uint32_t currentNumber;
    bool error;
    //key_val_map_t data;
    const char* buf;
    const char* p;
    void init();
public:
    RemoteDuinoServer() {
        init();
    }
    bool get_error() const {
        return error;
    }
    void reset() {
        ts = NULL;
        us = NULL;
        ks = NULL;
        error = true;
        currentNumber = 0;
    }
    void parse_microscript(const char* input, uint16_t len);
    void handle_error();

    uint32_t code;
    int protocol;
};
