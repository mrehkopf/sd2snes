#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#include "config.h"
#include "yaml.h"
#include "ff.h"
#include "fileops.h"
#include "uart.h"

yaml_state_t ystate;

void yaml_file_open(char *filename, uint8_t ff_flags) {
  if(ystate.flags & YAML_FLAG_FILE_OPEN) {
    printf("yaml_file_open: there is already a yaml file open!\n");
    return;
  }
  file_open((uint8_t*)filename, ff_flags);
  if(file_res) return;
  ystate.flags = YAML_FLAG_FILE_OPEN | YAML_FLAG_BUF_EMPTY;
  ystate.ff_flags = ff_flags;
  ystate.depth = 0;
  ystate.parent_offset = 0;
  ystate.line[0] = 0;
  ystate.state = YAML_PSTATE_NONE;
  ystate.delim = YAML_DELIM_NONE;
  ystate.line_offset = 0;
}

void yaml_file_close() {
  file_close();
  ystate.flags &= ~YAML_FLAG_FILE_OPEN;
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
  } else if (   !strcasecmp(*token, "true")
             || !strcasecmp(*token, "yes")
             || !strcasecmp(*token, "on")
             || !strcasecmp(*token, "y")) {
    type = YAML_BOOL;
    tok->boolvalue = true;
  } else if (   !strcasecmp(*token, "false")
             || !strcasecmp(*token, "no")
             || !strcasecmp(*token, "off")
             || !strcasecmp(*token, "n")) {
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
int yaml_get_next(yaml_token_t *tok) {
  static char *tokline = NULL, *line = NULL, *token = NULL;
  uint8_t repeat = 0;
  static int indent = 0;
  int len = 0;

  yaml_token_type type;
  do {
    DBG_YAML printf("yaml flags = %02x\n", ystate.flags);
    repeat = 0;
    if (ystate.flags & YAML_FLAG_REWIND_LINE) {
      tokline = line;
    } else if (ystate.flags & YAML_FLAG_REWIND_TOKEN) {
      tokline = token;
    } else if(ystate.flags & YAML_FLAG_BUF_EMPTY) {
      DBG_YAML printf("refilling line buffer... ");
      ystate.line_offset = f_tell(&file_handle);
      line = f_gets(ystate.line, YAML_BUFLEN, &file_handle);
      /* truncate comments */
      if(line && *line) {
        char *ptr = line;
        int dblquote = 0;
        int quote = 0;
        while(*ptr) {
          if(*ptr == '#' && !dblquote && !quote) {
            /* check for escaped # */
            DBG_YAML printf("truncating comment %s from line %s\n", ptr, line);
            *ptr = 0;
            break;
          }
          if(*ptr == '\'') {
            quote ^= 1;
          }
          if(*ptr == '\"') {
            dblquote ^= 1;
          }
          ptr++;
        }
      }
      tokline = line;
      DBG_YAML printf("line = %p f_eof=%d f_error=%d\n", line, f_eof(&file_handle), f_error(&file_handle));
    }
    if(line) {
      ystate.flags &= ~YAML_FLAG_BUF_EMPTY;
      /* measure indentation on new line */
      if(tokline) {
        for(indent=0; line[indent] == ' '; indent++);
      }
      token = strtok(tokline, ystate.delim);
      tokline = NULL;
      if(token == NULL && !(ystate.flags & (YAML_FLAG_REWIND_LINE | YAML_FLAG_REWIND_TOKEN))) {
        repeat = 1; /* end of line, read next line */
        ystate.flags |= YAML_FLAG_BUF_EMPTY;
      }
      /* trim leading spaces */
      while(token && (*token == ' ')) {
        token++;
      }
      /* skip comments */
      if(token && *token == '#') {
        DBG_YAML printf("skipping comment line: %s\n", token);
        repeat = 1;
      }
    }
  } while (repeat);
  if(line == NULL) return EOF;

  ystate.flags &= ~(YAML_FLAG_REWIND_LINE | YAML_FLAG_REWIND_TOKEN);

  type = YAML_UNKNOWN;
  DBG_YAML printf("indent: %d; state.depth: %d; token: %s; pstate: %d -> ", indent, ystate.depth, token, ystate.state);
  switch (ystate.state) {
    case YAML_PSTATE_NONE:
      if(!strncmp(token, "---", 3)) {
        type = YAML_DOC_START;
        ystate.delim = YAML_DELIM_KEY;
        ystate.state = YAML_PSTATE_KEY;
      }
      break;
    case YAML_PSTATE_KEY:
      if(!strncmp(token, "- ", 2)) {
        /* use "bullet" as item start marker, emit ITEM_START type */
        ystate.parent_offset = ystate.line_offset + 2;
        /* eat bullet so it doesn't get re-tokenized after REWIND_LINE */
        while(*token == ' ' || *token == '-') {
          *token = ' ';
          token++;
        }
        /* HACK restore delimiter so strtok can work with the whole line again */
        token[strlen(token)]=':';
        ystate.flags |= YAML_FLAG_REWIND_LINE;
        type = YAML_ITEM_START;
        ystate.state = YAML_PSTATE_KEY;
        DBG_YAML printf("Item start! line_offset=%ld  parent_offset=%ld\n", ystate.line_offset, ystate.parent_offset);
      } else if(!strncmp(token, "...", 3)) {
        type = YAML_DOC_END;
        ystate.delim = YAML_DELIM_NONE;
        ystate.state = YAML_PSTATE_NONE;
      } else {
        type = YAML_KEY;
        ystate.delim = YAML_DELIM_VALUE;
        ystate.state = YAML_PSTATE_VALUE;
        ystate.depth = indent;
        strncpy(tok->stringvalue, token, YAML_BUFLEN);
      }
      break;
    case YAML_PSTATE_VALUE:
      ystate.delim = YAML_DELIM_KEY;
      ystate.state = YAML_PSTATE_KEY;
      if(!strncmp(token, "- ", 2)) {
        if(indent >= ystate.depth) {
          type = YAML_LIST_START;
          ystate.delim = YAML_DELIM_VALUE;
          ystate.state = YAML_PSTATE_LIST_MULTILINE;
          ystate.flags |= YAML_FLAG_REWIND_LINE;
          ystate.depth = indent;
        } else {
        /* this isn't a list item anymore, re-run state machine on this line */
          ystate.flags |= YAML_FLAG_REWIND_LINE;
          ystate.delim = YAML_DELIM_KEY;
          ystate.state = YAML_PSTATE_KEY;
          type = YAML_NONE;
        }
      } else if(*token == '[') {
        /* go to sub state */
        type = YAML_LIST_START;
        ystate.delim = YAML_DELIM_LIST_INLINE;
        ystate.state = YAML_PSTATE_LIST_INLINE;
        ystate.flags |= YAML_FLAG_REWIND_TOKEN;
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
        ystate.flags |= YAML_FLAG_REWIND_LINE;
        ystate.delim = YAML_DELIM_KEY;
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
        ystate.delim = YAML_DELIM_KEY;
        ystate.flags |= YAML_FLAG_REWIND_TOKEN;
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
  return 1;
}

/* search for next token with given properties */
int yaml_search_next(yaml_token_t *tok, yaml_scope scope) {
  yaml_token_t cmp;
  int found = 0;
  while(!found && (yaml_get_next(&cmp) != EOF)) {
    if(scope == YAML_SCOPE_ITEM && cmp.type == YAML_ITEM_START) {
      break;
    }
    if(cmp.type == tok->type) {
      switch(tok->type) {
        case YAML_KEY:
        case YAML_STRING:
          if(!tok->stringvalue[0] || !strcasecmp(tok->stringvalue, cmp.stringvalue)) {
            found = 1;
          }
          break;
        default: found = 1;
      }
    }
    if(found) *tok = cmp;
  }
  return found;
}

void yaml_seek(uint32_t offset) {
  ystate.depth = 0;
  ystate.flags |= YAML_FLAG_BUF_EMPTY;
  ystate.flags &= ~(YAML_FLAG_REWIND_LINE | YAML_FLAG_REWIND_TOKEN);
  ystate.line[0] = 0;
  f_lseek(&file_handle, offset);
}

/* go back to head of file */
void yaml_rewind() {
  DBG_YAML printf("rewinding file (offset: 0)\n");
  yaml_seek(0);
  ystate.parent_offset = 0;
  ystate.state = YAML_PSTATE_NONE;
  ystate.delim = YAML_DELIM_NONE;
}

/* go to after last occurrence of "^- " */
void yaml_rewind_item() {
  DBG_YAML printf("rewinding item (offset: %ld)\n", ystate.parent_offset);
  if(ystate.parent_offset) {
    yaml_seek(ystate.parent_offset);
    ystate.state = YAML_PSTATE_KEY;
    ystate.delim = YAML_DELIM_KEY;
  } else {
    /* rewind entire file when not within item */
    yaml_rewind();
  }
}

/* search for next item start ("^- ") */
int yaml_next_item() {
  yaml_token_t cmp;
  cmp.type = YAML_ITEM_START;
  return yaml_search_next(&cmp, YAML_SCOPE_GLOBAL);
}

/* retrieve value of a given key (returns next hit) */
int yaml_get_value(char *key, yaml_token_t *tok, yaml_scope scope) {
  int found;
  /* always search whole item */
  if(scope == YAML_SCOPE_ITEM) {
    yaml_rewind_item();
  }
  yaml_token_t cmp;
  cmp.type = YAML_KEY;
  strncpy(cmp.stringvalue, key, YAML_BUFLEN);
  /* look for key */
  found = yaml_search_next(&cmp, scope);
  /* now move to value */
  if(found) {
    found = yaml_get_next(tok);
  }
  return found;
}

int yaml_get_itemvalue(char *key, yaml_token_t *tok) {
  return yaml_get_value(key, tok, YAML_SCOPE_ITEM);
}
