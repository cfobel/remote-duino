#include <stdint.h>
#include <vector>
#include <iostream>
using namespace std;

class Server {
private:
    char const *ts;
    uint8_t cs; /* The current parser state */
    uint16_t currentNumber;
    char *buf;
public:
    vector<char> buf_vector;
    Server() : ts(NULL), currentNumber(0), buf_vector(vector<char>(1024)) {
        init();
    }
    void init();
    void parse_microscript(const char* p, uint16_t len, uint8_t is_eof);
};
