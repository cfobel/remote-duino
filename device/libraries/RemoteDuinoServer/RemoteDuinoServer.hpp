#include <stl_config.h>
#include <iostream>
#include <string>
#include <stdint.h>
#include <vector>
#include <map>
using namespace std;

typedef map<string, string> key_val_map_t;

class Server {
private:
    char const *ts;
    char const *us;
    char const *ks;
    int content_length;
    uint8_t cs; /* The current parser state */
    uint16_t currentNumber;
    char *buf;
    bool error;
    string key;
    key_val_map_t data;
    vector<string> encoded_chars;

    void init();
public:
    vector<char> buf_vector;
    Server(int buffer_size = 512) : ts(NULL), 
        content_length(0),
        error(true),
        currentNumber(0), buf_vector(vector<char>(buffer_size)) {
        init();
    }
    void parse_microscript(const char* p, uint16_t len, uint8_t is_eof);
};
