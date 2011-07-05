#include "Server.hpp"
#include <new.cpp>

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
    Server s(400);

    string data = "test=sony%20%25as&mode=repeat&key=10";
    string headers = "POST / HTTP/1.1\n"\
                    "USER-AGENT: CURL/7.21.0 (I686-PC-LINUX-GNU) LIBCURL/7.21.0 OPENSSL/0.9.8O ZLIB/1.2.3.4 LIBIDN/1.18\n"\
                    "HOST: 0.0.0.0:9999\n"\
                    "ACCEPT: */*\n"\
                    "CONTENT-LENGTH: 55\n"\
                    "CONTENT-TYPE: APPLICATION/X-WWW-FORM-URLENCODED\n"\
                    + data + "\n"\
                    "bloaadfadf";

    s.parse_microscript(headers.c_str(), headers.size(), 1);

    return 0;
}
