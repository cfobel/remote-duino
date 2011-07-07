#include "RemoteDuinoServer.h"

%%{
    machine BaseRemoteDuinoServer;

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
        uint8_t digit = (*fpc) - '0';
        currentNumber = (currentNumber * 10) + digit;
    }

    action RecordHexDigit {
        uint8_t digit = (*fpc) - '0';
        currentNumber = (currentNumber << 4) + digit;
    }

    action RecordHexAlpha {
        uint8_t digit = (*fpc) - 'A';
        currentNumber = (currentNumber << 4) + (10 + digit);
    }

    action record_learn_action {
        uri_action = LEARN_CODE;
    }

    action record_send_action {
        uri_action = SEND_CODE;
    }

    action finish_parse {
        error = false;
    }

    action cmd_error {
    }


    number = (((digit @RecordDigit))+) >ClearNumber; 
    hex_number = (((digit @RecordHexDigit) | ([A-F] @RecordHexAlpha))+) >ClearNumber; 
    
    uriaction = (("learn" @record_learn_action) | ("send" @record_send_action));
    uripath = '/' (uriaction);
    #uripath = (any* - "?");

    post = ("POST"i (any* - (any* '\n' (space - '\n')* '\n' any*)) '\n' (space - '\n') '\n');
    get = ("GET"i space+ uripath "?");

    url_encoded = ('%' [0-9a-fA-F]{2});
    key = ((ascii - space - '&')+);
    value = ((url_encoded | (ascii - space - '&'))+);
    code_value = '0x' hex_number %store_code;
    protocol_value = number %store_protocol;
    code = ('c=' code_value);
    protocol = ('p=' protocol_value);
    data = (code | protocol);
    data_set = (data ('&' data)+);
    header = ( post );

    post_request = (post data_set space*);
    get_request = (get data_set space+ any*);
    main := get_request <!cmd_error %finish_parse;
    #main := (get_request) <!cmd_error %finish_parse;
    #main := (header data_set space*) <!cmd_error %finish_parse;
}%% 

/* Regal data ****************************************/
%% write data nofinal;
/* Regal data: end ***********************************/


void BaseRemoteDuinoServer::reset() {
    ts = NULL;
    error = false;
    currentNumber = 0;

    %% write init;
}


void BaseRemoteDuinoServer::parse() {
    reset();
    bool done = false;
    error = false;
    int i = 0;
    have = 0;
    while (!done) {
        /* How much space is in the buffer? */
        int space = BUFSIZE - have;
        if(space == 0) {
            /* Buffer is full. */
            error = true;
            break;
        }
        /* Read in a block after any data we already have. */
        char *p = buf + have;
        //in_stream.read( p, space );
        //int len = in_stream.gcount();
        int len = read_data(p, space);
        if(verbose) {
            cout.write(p, len);
        }
        char *pe = p + len;
        char *eof = 0;

        /* If no data was read indicate EOF. */
        if(len == 0) {
            eof = pe;
            done = true;
        } else {
            %% write exec;

            if(cs == BaseRemoteDuinoServer_error) {
                /* Machine failed before finding a token. */
                error = true;
                break;
            }
            if( ts == 0 ) {
                have = 0;
            } else {
                /* There is a prefix to preserve, shift it over. */
                have = pe - ts;
                memmove(buf, ts, have);
                te = buf + (te-ts);
                ts = buf;
            }
        }
    }
} 
