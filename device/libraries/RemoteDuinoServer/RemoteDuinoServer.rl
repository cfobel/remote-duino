#include "Server.hpp"

%%{
    machine microscript;

    action StartKey {
        ks = p;
    }
    
    action RecordKey {
        key = string(ks, (p - ks));
    }

    action RecordValue {
        string value = string(ks, (p - ks));
        data[key] = value;
    }

    action StartChar {
        us = p;
    }
    
    action RecordChar {
        encoded_chars.push_back(string(us, (p - us)));
    }

    action ClearNumber {
        currentNumber = 0;
    }
    
    action RecordDigit {
        uint8_t digit = (*p) - '0';
        currentNumber = (currentNumber * 10) + digit;
    }

    action RecordContentLength {
        content_length = currentNumber;
    }

    action UpdateEOF {
        eof = p + content_length;
        pe = eof;
    }

    action cmd_error {
#if 0
        cout << "Error" << endl;
#endif
    }

    action finish_parse {
        error = false;
    }

    number = ((digit @RecordDigit)+) >ClearNumber; 
    
    post = ("POST"i [^\n]* '\n');
    user_agent = ("USER-AGENT:"i [^\n]* '\n');
    host = ("HOST:"i [^\n]* '\n');
    accept = ("ACCEPT:"i [^\n]* '\n');
    content_length = ("CONTENT-LENGTH:"i space+ number '\n') %RecordContentLength;
    content_type = ("CONTENT-TYPE:" space+ "APPLICATION/X-WWW-FORM-URLENCODED"i space*) %UpdateEOF;

    url_encoded = ('%' [0-9a-fA-F]{2}) >StartChar %RecordChar;
    key = ((ascii - space - '&')+) >StartKey %RecordKey;
    value = ((url_encoded | (ascii - space - '&'))+) >StartKey %RecordValue;
    data = (key '=' value);
    data_set = (data ('&' data)*);
    header = (
            post 
            user_agent
            host
            accept
            content_length
            content_type
            );

    main := (header data_set space*) <!cmd_error %finish_parse;
#    main := post user_agent host accept content_length content_type
}%% 

/* Regal data ****************************************/
%% write data nofinal;
/* Regal data: end ***********************************/


void Server::init() {
    buf = &buf_vector[0];

	%% write init;
}

void Server::parse_microscript(const char* p, uint16_t len, uint8_t is_eof) {
  const char* pe = p + len; /* pe points to 1 byte beyond the end of this block of data */
  const char* eof = is_eof ? pe : ((char*) 0); /* Indicates the end of all data, 0 if not in this block */
 
  %% write exec;
} 
