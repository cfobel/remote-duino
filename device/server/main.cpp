#include <iostream>
#include <string>
#include "Server.hpp"

using namespace std;

/*
curl --data-urlencode "test=hello" http://0.0.0.0:9999

POST / HTTP/1.1
USER-AGENT: CURL/7.21.0 (I686-PC-LINUX-GNU) LIBCURL/7.21.0 OPENSSL/0.9.8O ZLIB/1.2.3.4 LIBIDN/1.18
HOST: 0.0.0.0:9999
ACCEPT: 
CONTENT-LENGTH: 10
CONTENT-TYPE: APPLICATION/X-WWW-FORM-URLENCODED

TEST=HELLO
*/

int main() {
    Server s;
    string data = "POST / HTTP/1.1\n"\
                    "USER-AGENT: CURL/7.21.0 (I686-PC-LINUX-GNU) LIBCURL/7.21.0 OPENSSL/0.9.8O ZLIB/1.2.3.4 LIBIDN/1.18\n"\
                    "HOST: 0.0.0.0:9999\n"\
                    "ACCEPT: */*\n"\
                    "CONTENT-LENGTH: 10\n"\
                    "CONTENT-TYPE: APPLICATION/X-WWW-FORM-URLENCODED\n"\
                    "TEST=HELLO&TEST2=adsfasdf\n";

    s.parse_microscript(data.c_str(), data.size(), 1);

    return 0;
}
