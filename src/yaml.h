#ifndef __YAML_H
#define __YAML_H

#ifdef DEBUG_YAML
#define DBG_YAML
#else
#define DBG_YAML while(0)
#endif

#include <stdbool.h>
#include <stdint.h>

#define YAML_BUFLEN (256)

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
  YAML_ITEM_START,
  YAML_UNKNOWN
} yaml_token_type;

#define YAML_DELIM_LIST_INLINE    ("[,\r\n")
#define YAML_DELIM_LIST_MULTILINE ("\r\n")
#define YAML_DELIM_KEY            (":\r\n")
#define YAML_DELIM_VALUE          ("\r\n")
#define YAML_DELIM_NONE           (" \r\n")

#define YAML_FLAG_FILE_OPEN       (0x01)
#define YAML_FLAG_BUF_EMPTY       (0x02)
#define YAML_FLAG_REWIND_LINE     (0x04)
#define YAML_FLAG_REWIND_TOKEN    (0x08)

typedef enum _yaml_scope {
  YAML_SCOPE_GLOBAL = 0,
  YAML_SCOPE_ITEM
} yaml_scope;

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
  uint8_t  flags;
  uint8_t  ff_flags;
  int      depth;
  uint32_t line_offset;
  uint32_t parent_offset;
  yaml_parse_state state;
  char     line[YAML_BUFLEN+1];
  char     *delim;
} yaml_state_t;

void yaml_file_open(char *filename, uint8_t ff_flags);
void yaml_file_close(void);

/* read next token sequentially */
int yaml_get_next(yaml_token_t *tok);
/* search for next token with given properties */
int yaml_search_next(yaml_token_t *tok, yaml_scope scope);
/* go back to head of file */
void yaml_rewind(void);
/* go back to start of current item */
void yaml_rewind_item(void);
/* go to next item */
int yaml_next_item(void);
/* retrieve value of a given key */
int yaml_get_value(char *key, yaml_token_t *tok, yaml_scope scope);
/* retrieve value from within current item only */
int yaml_get_itemvalue(char *key, yaml_token_t *tok);

#endif
