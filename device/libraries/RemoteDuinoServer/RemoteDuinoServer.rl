#include "RemoteDuinoServer.h"

%%{
    machine microscript;

    action store_code {
        code = currentNumber;
    }

    action store_protocol {
        protocol = currentNumber;
    }

    action ClearNumber {
        currentNumber = 0;
    }
    
    action RecordDigit {
        uint8_t digit = (*p) - '0';
        currentNumber = (currentNumber * 10) + digit;
    }

    action RecordHexDigit {
        uint8_t digit = (*p) - '0';
        currentNumber = (currentNumber << 4) + digit;
    }

    action RecordHexAlpha {
        uint8_t digit = (*p) - 'A';
        currentNumber = (currentNumber << 4) + (10 + digit);
    }

    action cmd_error {
        handle_error();
    }

    action finish_parse {
        error = false;
    }

    number = (((digit @RecordDigit))+) >ClearNumber; 
    hex_number = (((digit @RecordHexDigit) | ([A-F] @RecordHexAlpha))+) >ClearNumber; 
    
    post = ("POST"i (any* - (any* '\n' (space - '\n')* '\n' any*)) '\n' (space - '\n') '\n');

    #url_encoded = ('%' [0-9a-fA-F]{2}) >StartChar %RecordChar;
    #key = ((ascii - space - '&')+) >StartKey %RecordKey;
    #value = ((url_encoded | (ascii - space - '&'))+) >StartKey %RecordValue;
    url_encoded = ('%' [0-9a-fA-F]{2});
    key = ((ascii - space - '&')+);
    value = ((url_encoded | (ascii - space - '&'))+);
    code_value = '0x' hex_number %store_code;
    protocol_value = number %store_protocol;
    code = ('c=' code_value);
    protocol = ('p=' protocol_value);
    data = (code | protocol);
    data_set = (data ('&' data)*);
    header = ( post );

    main := (post data_set space*) <!cmd_error %finish_parse;
    #main := (header data_set space*) <!cmd_error %finish_parse;
}%% 

/* Regal data ****************************************/
%% write data nofinal;
/* Regal data: end ***********************************/


void RemoteDuinoServer::init() {
    reset();

	%% write init;
}

void RemoteDuinoServer::parse_microscript(const char* input, uint16_t len) {
    reset();
    p = input;
    const char* pe = p + len; /* pe points to 1 byte beyond the end of this block of data */
    const char* eof = pe; /* Indicates the end of all data, 0 if not in this block */
    buf = p;
    
    %% write exec;
} 
