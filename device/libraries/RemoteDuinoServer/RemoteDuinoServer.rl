#include "RemoteDuinoServer.h"

extern "C" void __cxa_pure_virtual(void);
void __cxa_pure_virtual(void) {} 


int get_free_memory() {
    int free_memory;

    if((int)__brkval == 0)
        free_memory = ((int)&free_memory) - ((int)__bss_end);
    else
        free_memory = ((int)&free_memory) - ((int)__brkval);

    return free_memory;
}

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


void BaseRemoteDuinoServer::init() {
    //irrecv.enableIRIn(); // Start the receiver
    pinMode(STATUS_PIN, OUTPUT);
    buf = &buf_vector[0];
    BUFSIZE = buf_vector.size();
    reset();

	%% write init;
}

void BaseRemoteDuinoServer::parse() {
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


void BaseRemoteDuinoServer::sendCode(int protocol, uint32_t code, int code_length) {
    if(protocol == NEC) {
        irsend.sendNEC(code, code_length);
        cout << "Sent NEC ";
        Serial.println(code, HEX);
    } else if(protocol == SONY) {
        irsend.sendSony(code, code_length);
        cout << "Sent Sony ";
        Serial.println(code, HEX);
    } else if(protocol == RC5) {
        cout << "Sent RC5 ";
        Serial.println(code, HEX);
        irsend.sendRC5(code, code_length);
    } else if(protocol == RC6) {
        irsend.sendRC6(code, code_length);
        cout << "Sent RC6 ";
        Serial.println(code, HEX);
    } else {
    //else if (protocol == UNKNOWN /* i.e. raw */) {
        // Assume 38 KHz
        //irsend.sendRaw(rawCodes, codeLen, 38);
        Serial.println("Unkown protocol");
    }
}


void BaseRemoteDuinoServer::process_request() {
    if(available()) {
        parse();
        // send a standard http response header
        cout << get_free_memory() << endl;
        bool err = get_error();
        if(err) {
            cout << "Error parsing" << endl;
            return;
        } 

        cout << "Parse succesful" << endl;
        cout << "action:" << uri_action << endl;
        cout << "code:" << code << endl;
        cout << "protocol:" << protocol << endl;

        // output the value of each analog input pin
        for(int i = 0; i < 3; i++) {
            sendCode(protocol, code);
        }
        delay(50); // Wait a bit between retransmissions
        //irrecv.enableIRIn(); // Re-enable receiver
    }
}

