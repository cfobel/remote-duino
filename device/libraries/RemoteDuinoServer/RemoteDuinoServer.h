#include <stl_config.h>
#include <iostream>
#include <string>
#include <stdint.h>
#include <vector>
#include <map>
using namespace std;

typedef std::map<string, string> key_val_map_t;

class RemoteDuinoServer {
private:
    char const *ts;
    char const *us;
    char const *ks;
    int content_length;
    uint8_t cs; /* The current parser state */
    uint16_t currentNumber;
    bool error;
    string key;
    key_val_map_t data;
    vector<string> encoded_chars;

    void init();
public:
    vector<char> buf_vector;
    RemoteDuinoServer() {
        init();
    }
    bool get_error() const {
        return error;
    }
    void reset() {
        ts = NULL;
        content_length = 0;
        error = true;
        currentNumber = 0;
    }
    void parse_microscript(const char* p, uint16_t len, uint8_t is_eof);
};
