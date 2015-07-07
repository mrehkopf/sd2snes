#ifndef __YAML_H
#define __YAML_H

#ifdef DEBUG_YAML
#define DBG_YAML
#else
#define DBG_YAML while(0)
#endif

#include <stdbool.h>
#include <stdint.h>

#define YAML_BUFLEN (80)

/* token types emitted by yaml_get_next */
typedef enum _yaml_token_type {
  YAML_DOC_START = 0,
  YAML_DOC_END,
  YAML_KEY,
  YAML_LIST_START,
  YAML_LIST_END,
  YAML_STRING,
  YAML_LONG,
  YAML_BOOL,
  YAML_NONE,
  YAML_UNKNOWN
} yaml_token_type;

#define YAML_DELIM_LIST_INLINE    ("[,\r\n")
#define YAML_DELIM_LIST_MULTILINE ("\r\n")
#define YAML_DELIM_KEY            (":\r\n")
#define YAML_DELIM_VALUE          ("\r\n")
#define YAML_DELIM_NONE           (" \r\n")

typedef enum _yaml_parse_state {
  YAML_PSTATE_NONE = 0,
  YAML_PSTATE_LIST_INLINE,
  YAML_PSTATE_LIST_INLINE_END,
  YAML_PSTATE_LIST_MULTILINE,
  YAML_PSTATE_KEY,
  YAML_PSTATE_VALUE
} yaml_parse_state;

typedef struct _yaml_token {
  yaml_token_type type;
  char            stringvalue[YAML_BUFLEN+1];
  long            longvalue;
  bool            boolvalue;
} yaml_token_t;

typedef struct _yaml_state {
  bool     file_open;
  uint8_t  ff_flags;
  int      depth;
  uint32_t parent_offset;
  bool     empty;
  yaml_parse_state state;
  char     line[YAML_BUFLEN+1];
} yaml_state_t;

void yaml_file_open(char *filename, uint8_t ff_flags);
void yaml_file_close(void);

/* read next token sequentially */
int yaml_get_next(yaml_token_t *tok);
/* search for previous token with given properties */
int yaml_search_prev(yaml_token_t *tok);
/* search for next token with given properties */
int yaml_search_next(yaml_token_t *tok);
/* go back to head of file */
void yaml_rewind(void);
/* retrieve value of a given key */
int yaml_get_value(char *key);

#endif
