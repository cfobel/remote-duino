#include "RemoteDuinoServer.h"

%%{
    machine RemoteDuinoServer;

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

    action clear_uri_action {
        uri_action.clear();
    }

    action record_action_char {
        uri_action.push_back(*fpc);
    }

    action cmd_error {
        handle_error();
    }

    action finish_parse {
        error = false;
    }

    number = (((digit @RecordDigit))+) >ClearNumber; 
    hex_number = (((digit @RecordHexDigit) | ([A-F] @RecordHexAlpha))+) >ClearNumber; 
    
    uriaction = (("learn")? $record_action_char); # >start_uri_action @store_uri_action;
    uripath = '/' (uriaction) >clear_uri_action;
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


void RemoteDuinoServer::init() {
    buf = &buf_vector[0];
    BUFSIZE = buf_vector.size();
    reset();

	%% write init;
}

void RemoteDuinoServer::parse() {
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
        char *pe = p + len;
        char *eof = 0;

        /* If no data was read indicate EOF. */
        if(len == 0) {
            eof = pe;
            done = true;
        } else {
            %% write exec;

            if(cs == RemoteDuinoServer_error) {
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


int RemoteDuinoServer::available() {
    return Serial.available();
}


int RemoteDuinoServer::read_data(char *p, int const max_length) {
    int curr_char = 0;
    bool currentLineIsBlank = true;
    while(Serial.available()) {
        p[curr_char] = Serial.read();
        char &c = p[curr_char];
        curr_char++;
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
            break;
        }
        if (c == '\n') {
            // you're starting a new line
            currentLineIsBlank = true;
        } 
        else if (c != '\r') {
            // you've gotten a character on the current line
            currentLineIsBlank = false;
        }
        if(curr_char >= max_length) {
            break;
        }
        delay(20);
    }
    return curr_char;
}
