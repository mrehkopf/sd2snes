#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "config.h"
#include "yaml.h"
#include "ff.h"
#include "fileops.h"
#include "uart.h"

yaml_state_t ystate;

void yaml_file_open(char *filename, uint8_t ff_flags) {
  if(ystate.file_open) {
    printf("yaml_file_open: there is already a yaml file open!\n");
    return;
  }
  file_open((uint8_t*)filename, ff_flags);
  if(file_res) return;
  ystate.file_open = true;
  ystate.ff_flags = ff_flags;
  ystate.depth = 0;
  ystate.parent_offset = 0;
  ystate.empty = 1;
  ystate.line[0] = 0;
}

void yaml_file_close() {
  file_close();
  ystate.file_open = false;
}

yaml_token_type yaml_detect_value(char **token, yaml_token_t *tok) {
  yaml_token_type type = YAML_UNKNOWN;
  /* as a default, copy the token literal value to stringvalue */
  strncpy(tok->stringvalue, *token, YAML_BUFLEN);
  if (**token == '"') {
    /* String value: discard quotes */
    (*token)++;
    for(int i=0; (*token)[i]; i++) {
      if((*token)[i] == '"') {
        (*token)[i] = 0;
        break;
      }
    }
    type = YAML_STRING;
    strncpy(tok->stringvalue, *token, YAML_BUFLEN);
  } else if (!strcasecmp(*token, "true")) {
    type = YAML_BOOL;
    tok->boolvalue = true;
  } else if (!strcasecmp(*token, "false")) {
    type = YAML_BOOL;
    tok->boolvalue = false;
  } else {
    char *endptr;
    long longvalue;
    longvalue = strtol(*token, &endptr, 0);
    if(*endptr == 0) {
      tok->longvalue = longvalue;
      type = YAML_LONG;
    }
  }
  return type;
}

/* read next token sequentially */
int yaml_get_next(yaml_token_t *tok){
  static char *tokline = NULL, *line = NULL, *token = NULL;
  static bool rewind_line = false;
  static bool rewind_token = false;
  uint8_t repeat = 0;
  static char *delim = YAML_DELIM_NONE;
  static int indent = 0;
  int len = 0;

  yaml_token_type type;
  do {
    repeat = 0;
    if (rewind_line) {
      tokline = line;
    } else if (rewind_token) {
      tokline = token;
    } else if(ystate.empty) {
      line = f_gets(ystate.line, YAML_BUFLEN, &file_handle);
      tokline = line;
    }
    if(line) {
      ystate.empty = false;
      /* measure indentation on new line */
      if(tokline) {
        for(indent=0; line[indent] == ' '; indent++);
      }
      token = strtok(tokline, delim);
      tokline = NULL;
      if(token == NULL && !rewind_line && !rewind_token) {
        repeat = 1; /* end of line, read next line */
        ystate.empty = true;
      }
    }
  } while (repeat);
  if(line == NULL) return EOF;
  /* trim leading spaces */
  while(token && (*token == ' ')) {
    token++;
  }

  rewind_line = false;
  rewind_token = false;

  type = YAML_UNKNOWN;
  DBG_YAML printf("indent: %d; token: %s; pstate: %d -> ", indent, token, ystate.state);
  switch (ystate.state) {
    case YAML_PSTATE_NONE:
      if(!strncmp(token, "---", 3)) {
        type = YAML_DOC_START;
        delim = YAML_DELIM_KEY;
        ystate.state = YAML_PSTATE_KEY;
      }
      break;
    case YAML_PSTATE_KEY:
      if(!strncmp(token, "- ", 2)) {
        /* eat lists at key level */
        while(*token == ' ' || *token == '-') token++;
      }
      if(!strncmp(token, "...", 3)) {
        type = YAML_DOC_END;
        delim = YAML_DELIM_NONE;
        ystate.state = YAML_PSTATE_NONE;
      } else {
        type = YAML_KEY;
        delim = YAML_DELIM_VALUE;
        ystate.state = YAML_PSTATE_VALUE;
        strncpy(tok->stringvalue, token, YAML_BUFLEN);
      }
      break;
    case YAML_PSTATE_VALUE:
      delim = YAML_DELIM_KEY;
      ystate.state = YAML_PSTATE_KEY;
      if(!strncmp(token, "- ", 2)) {
        type = YAML_LIST_START;
        delim = YAML_DELIM_VALUE;
        ystate.state = YAML_PSTATE_LIST_MULTILINE;
        rewind_line = true;
        ystate.depth = indent;
      } else if(*token == '[') {
        /* go to sub state */
        type = YAML_LIST_START;
        delim = YAML_DELIM_LIST_INLINE;
        ystate.state = YAML_PSTATE_LIST_INLINE;
        rewind_token = true;
      } else {
        type = yaml_detect_value(&token, tok);
      }
      break;
    case YAML_PSTATE_LIST_MULTILINE:
      /* strip enumeration sign */
      if(!strncmp(token, "- ", 2) && indent == ystate.depth) {
        while(*token == ' ' || *token == '-') token++;
        type = yaml_detect_value(&token, tok);
      } else {
      /* this isn't a list item anymore, re-run state machine on this line */
        rewind_line = true;
        delim = YAML_DELIM_KEY;
        ystate.state = YAML_PSTATE_KEY;
        type = YAML_LIST_END;
      }
      break;
    case YAML_PSTATE_LIST_INLINE:
      len = strlen(token)-1;
      if(token[len] == ']') {
        token[len--] = 0;
        while(len && token[len] == ' ') {
          token[len] = 0;
          len--;
        }
        ystate.state = YAML_PSTATE_LIST_INLINE_END;
        delim = YAML_DELIM_KEY;
        rewind_token = true;
      }
      type = yaml_detect_value(&token, tok);
      break;
    case YAML_PSTATE_LIST_INLINE_END:
      ystate.state = YAML_PSTATE_KEY;
      type = YAML_LIST_END;
      break;
  }
  DBG_YAML printf("%d; token: %s (type: %d intval: %ld)\n", ystate.state, token, type, tok->longvalue);
  tok->type = type;
  return 0;
}


/* search for previous token with given properties */
int yaml_search_prev(yaml_token_t *tok){
  return -1;
}

/* search for next token with given properties */
int yaml_search_next(yaml_token_t *tok){
  return -1;
}

/* go back to head of file */
void yaml_rewind(){
}

/* retrieve value of a given key (returns first hit) */
int yaml_get_value(char *key){
  return -1;
}
