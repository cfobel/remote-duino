#include "Server.hpp"

%%{
    machine microscript;

    action StartPost {
        ts = p;
    }
    
    action PrintPost {
        cout << string(ts, (p - ts)) << endl;
    }

    action ClearNumber {
        currentNumber = 0;
    }
    
    action RecordDigit {
        uint8_t digit = (*p) - '0';
        currentNumber = (currentNumber * 10) + digit;
    }

    action cmd_error {
        cout << "Error" << endl;
    }

    number = ((digit @RecordDigit)+) >ClearNumber; 
    
    post = ("POST"i [^\n]* '\n') >StartPost %PrintPost;
    user_agent = ("USER-AGENT:"i [^\n]* '\n') >StartPost %PrintPost;
    host = ("HOST:"i [^\n]* '\n') >StartPost %PrintPost;
    accept = ("ACCEPT:"i [^\n]* '\n') >StartPost %PrintPost;
    content_length = ("CONTENT-LENGTH:"i space+ number '\n') >StartPost %PrintPost;
    content_type = ("CONTENT-TYPE:" space+ "APPLICATION/X-WWW-FORM-URLENCODED"i) >StartPost %PrintPost;
    key = (ascii - space)+;
    value = (ascii - space)+;
    data = (key '=' value);
    data_set = (data ('&' data)*) >StartPost %PrintPost;
    
    main := (
            post 
            user_agent
            host
            accept
            content_length
            content_type space*
            data_set space+) <!cmd_error;
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
