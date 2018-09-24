#include "base.h"
#include "libstr.cpp"
#include "libvlist.cpp"

#define min(a,b)                \
  ({ __typeof__ (a) _a = (a);   \
    __typeof__ (b) _b = (b);    \
    _a < _b ? _a : _b; })

FILE *fp, *wr, *exportfp;
string *linedata  =new string(),
       *blockdata =new string(),
       *opdata    =new string(),
       *tempstr0  =new string(),
       *tempstr1  =new string(),
       *tempstr2  =new string(),
       *tempstr3  =new string(),
       *macroline =new string(),
       *lnamespace=new string();
ulong pass, filenum, linenum, blocknum, opnum, opargs, oparg_labels,
  oparg_labels_unresolved; //0=all labels resolved, 1=label used before it was defined (in pass 0)

#define mode_hirom 0
#define mode_lorom 1
#define mode_flat  2
struct {
  ulong pc;           //rom position
  byte  mode;         //lorom or hirom or flat
  byte  header;       //whether or not to skip 512 byte header
  byte  fillbyte;     //byte to write with 'fill' command
  byte  padbyte;      //byte to write with 'pad' command
  ulong base;         //used for relocatable code
  ulong basepc;       //used for relocatable code
  ulong table[256];   //table for db strings
  ulong rep;          //repeat counter for 'rep' command
  ulong bytecount;    //counter for bytes written
  ulong opcount;      //counter for opcodes written
  ulong inmacro;      //macro recursion counter
  ulong macronum;     //macro call counter used for macro labels
  byte  retmacro;     //true only after first return from a macro
  byte  retfile;      //return file flag
  ulong brcount[6];   //branch counters [+,++,+++,-,--,---]
  byte  ips;          //ips mode
  ulong ipsoffset;    //ips mode prior file offset
  word  ipscount;     //ips mode current byte count
 }state;
struct {
  byte f_mx, f_db, f_d;
  byte mx;
  byte db;
  byte d;
}assume;

typedef struct {
  char *data;
  char *fn;
  ulong fsize;
  ulong pfilenum, plinenum, pblocknum;
}file_item;
file_item file_list[512];
ulong file_count;

void error(byte t, char *s, ...) {
va_list args;
char str[16384];
int i;
  va_start(args, s);
  vsprintf(str, s, args);
  printf("error: %s: line %d", file_list[filenum].fn, linenum+1);
  if(count(blockdata)>1)printf("{%d}", blocknum+1);
  printf(": %s", str);
  if(!t) {
    printf(" [");
    strcpy(tempstr0, blockdata, 0, blocknum);
    split_eq(tempstr0, " ");
    ntrim(tempstr0);
    for(i=0;i<count(tempstr0);i++) {
      printf("%s", strptr(tempstr0, i));
      if(i!=count(tempstr0)-1)printf(" ");
    }
    printf("]");
  }
  printf("\n");
  va_end(args);
}

typedef struct {
  char *s;
  char *a;
  ulong filenum, start, end, argcount;
}macro_item;

class macro_list {
public:
vectorlist  list;
macro_item *new_macro;
ulong       count;

  macro_item *get(ulong num) {
    return (macro_item*)list.get(num);
  }

  ulong find(char *name) {
    for(int i=0;i<count;i++) {
      new_macro=(macro_item*)list.get(i);
      if(!strcmp(new_macro->s, name))return i;
    }
    return null;
  }

  void add(char *name, char *args, ulong start, ulong end, ulong argcount) {
  int nsl=strlen(name), asl=strlen(args);
    if(find(name)!=null) {
      error(1, "macro [%s] already defined", name);
      return;
    }
    new_macro=(macro_item*)malloc(sizeof(macro_item));
    new_macro->s=(char*)malloc(nsl+1);
    strcpy(new_macro->s, name);
    new_macro->a=(char*)malloc(asl+1);
    strcpy(new_macro->a, args);
    new_macro->filenum =filenum;
    new_macro->start   =start;
    new_macro->end     =end;
    new_macro->argcount=argcount;
    list.add((ulong)new_macro);
    count++;
  }

  macro_list() { count = 0; }

  ~macro_list() {
    for(int i=0;i<count;i++) {
      new_macro=(macro_item*)list.get(i);
      free(new_macro->s);
      free(new_macro->a);
      free(new_macro);
    }
  }
};
macro_list macros;

typedef struct {
  char *s;
  char *r;
}define_item;

class define_list {
public:
vectorlist   list;
define_item *new_define;
ulong        count;

  char *get(ulong num) {
    new_define=(define_item*)list.get(num);
    return new_define->r;
  }

  ulong find(char *name) {
    for(int i=0;i<count;i++) {
      new_define=(define_item*)list.get(i);
      if(!strcmp(new_define->s, name))return i;
    }
    return null;
  }

  void add(char *name, char *value) {
  ulong v=find(name);
  int nsl=strlen(name), vsl=strlen(value);
    if(v!=null) {
      new_define=(define_item*)list.get(v);
    } else {
      new_define=(define_item*)malloc(sizeof(define_item));
      new_define->s=(char*)malloc(nsl+1);
      new_define->r=(char*)malloc(vsl+1);
      strcpy(new_define->s, name);
      list.add((ulong)new_define);
      count++;
    }
    strcpy(new_define->r, value);
  }

  define_list() { count = 0; }

  ~define_list() {
    for(int i=0;i<count;i++) {
      new_define=(define_item*)list.get(i);
      free(new_define->s);
      free(new_define->r);
      free(new_define);
    }
  }
};
define_list defines;

typedef struct {
  char *s;
  ulong pc;
  byte pass; //this is used to tell if a label has been defined in the second pass: for assume.db
}label_item;

class label_list {
public:
vectorlist  list;
label_item *new_label;
string     *lprefix;
ulong       count, v;
char        t[256];
  ulong find(string *str, ulong str_num = 0) {
    if(strlen(lnamespace) > 0)strinsert(str, 0, lnamespace, str_num);
    for(int i=0;i<count;i++) {
      new_label=(label_item*)list.get(i);
      if(!strcmp(new_label->s, strptr(str, str_num)))return i;
    }
    return null;
  }

  ulong get(ulong l) {
    new_label=(label_item*)list.get(l);
    return new_label->pc;
  }

  byte getpass(ulong l) {
    new_label=(label_item*)list.get(l);
    return new_label->pass;
  }

  void add(string *str, ulong offset, ulong str_num = 0) {
    if(!strbegin(str, "?", str_num)) { //macro label
      if(!state.inmacro) {
        if(!pass)error(0, "macro label declared outside of macro");
      }
      strltrim(str, "?", str_num);
      strrtrim(str, ":", str_num);
      sprintf(t, "__macro_%d_", state.macronum);
      strinsert(str, 0, t, str_num);
    } else if(!strbegin(str, ".", str_num)) { //sublabel
      strltrim(str, ".", str_num);
      strinsert(str, 0, lprefix, str_num);
    } else { //label
      strrtrim(str, ":",  str_num); //remove both types of label suffixes, it will only
      strrtrim(str, "()", str_num); //remove if found, so just remove both with no checks
      strcpy(lprefix, str, 0, str_num);
      strcat(lprefix, "_");
    }
    if(pass) { //update the existing label to state that it has been defined in the second pass
      v=find(str, str_num);
      new_label=(label_item*)list.get(v);
      new_label->pass=1;
    } else {   //add the label for the first time
      if(find(str, str_num)==null) { //not found
        new_label=(label_item*)malloc(sizeof(label_item));
        new_label->s=(char*)malloc(strlen(str)+1);
        strcpy(new_label->s, strptr(str, str_num));
        new_label->pc=offset;
        new_label->pass=0;
        list.add((ulong)new_label);
        count++;
      } else error(0, "string [%s] already defined", strptr(str, str_num));
    }
  }

  label_list() {
    lprefix=new string();
    count  =0;
  }

  ~label_list() {
    for(int i=0;i<count;i++) {
      new_label=(label_item*)list.get(i);
      free(new_label->s);
      free(new_label);
    }
    delete(lprefix);
  }
};
label_list labels;

ulong sfctopc(ulong v) {
ulong r;
  if(state.mode==mode_lorom) { //lorom
    r=(v&0x7f0000)>>1|(v&0x7fff);
  } else if (state.mode==mode_hirom) { //hirom
    r=v-0xc00000;
  }
  else {
    r = v;
  }
  if(state.header)r+=0x000200;
  return r;
}

void set_ipsoffset(ulong offset) {
  if (state.ips && pass && state.ipsoffset) {
    ulong pos = ftell(wr);
    fseek(wr, state.ipsoffset+0, SEEK_SET);
    fputc((offset >> 16) & 0xFF, wr);
    fputc((offset >>  8) & 0xFF, wr);
    fputc((offset >>  0) & 0xFF, wr);
    fseek(wr, pos, SEEK_SET);     
  }
}

ulong get_ipsoffset(void) {
  ulong val = 0;
  if (state.ips && pass && state.ipsoffset) {
    ulong pos = ftell(wr);
    fseek(wr, state.ipsoffset+0, SEEK_SET);
    val <<= 8; val |= fgetc(wr);
    val <<= 8; val |= fgetc(wr);
    val <<= 8; val |= fgetc(wr);
    fseek(wr, pos, SEEK_SET);
  }
  return val;
}

void set_ipscount(ulong count) {
  if (state.ips && pass && state.ipsoffset) {
    ulong pos = ftell(wr);
    fseek(wr, state.ipsoffset+3, SEEK_SET);
    fputc((count >> 8) & 0xFF, wr);
    fputc((count >> 0) & 0xFF, wr);
    fseek(wr, pos, SEEK_SET); 
  }
}

void add_ipsrecord(ulong offset) {
  if (state.ips && pass) {
    // record previous count (big endian)
    set_ipscount(state.ipscount);
    // write new record (big-endian)
    fseek(wr, 0, SEEK_END);
    state.ipsoffset = ftell(wr);
    state.ipscount = 0;

    set_ipsoffset(offset);
    set_ipscount(state.ipscount);
    fseek(wr, 0, SEEK_END);
  }
}

void setpcfp(void) {
  fseek(wr, sfctopc(state.pc), SEEK_SET);
  add_ipsrecord(sfctopc(state.pc));
}

ulong as_basetopc(ulong pc) {
  if(!state.base)return pc; //not using a base
  return state.base+(state.pc-state.basepc);
}

void inc_pc(ulong x) {
  if(pass)state.bytecount+=x;
  if(state.mode==mode_lorom) { //lorom
    while(x) {
      if(x>=0x4000) {
        state.pc+=0x4000;
        x-=0x4000;
      } else {
        state.pc+=x;
        x=0;
      }
      state.pc|=0x8000;
    }
  } else {                     //hirom/flat
    state.pc+=x;
  }
  if (state.ips) {
    // FIXME: support splitting here?  Since this can be incremented by >1 it's not really possible.
    if (pass) {
      state.ipscount+=x;
    }
  }
}

// FIXME: support ips
void fputb(byte x)  { inc_pc(1); if(!pass)return;
  fputc(x, wr); }
void fputw(word x)  { inc_pc(2); if(!pass)return;
  fputc(x, wr); fputc(x>>8, wr); }
void fputl(ulong x) { inc_pc(3); if(!pass)return;
  fputc(x, wr); fputc(x>>8, wr); fputc(x>>16, wr); }
void fputd(ulong x) { inc_pc(4); if(!pass)return;
  fputc(x, wr); fputc(x>>8, wr); fputc(x>>16, wr); fputc(x>>24, wr); }

enum { opsize_none=0, opsize_byte, opsize_word, opsize_long, opsize_dword };
byte as_setsize(void) {
int i, l;
char *str=strptr(opdata, 1);
ulong r;
  if(!strend(opdata, ".b", 0)) { strrtrim(opdata, ".b", 0); return opsize_byte;  }
  if(!strend(opdata, ".w", 0)) { strrtrim(opdata, ".w", 0); return opsize_word;  }
  if(!strend(opdata, ".l", 0)) { strrtrim(opdata, ".l", 0); return opsize_long;  }
  if(!strend(opdata, ".d", 0)) { strrtrim(opdata, ".d", 0); return opsize_dword; }

  if(oparg_labels)return opsize_none;
  if(strmathentity(opdata, 1))return opsize_none;

  for(i=0;i<strlen(str);i++) {
    if(str[i]>='0'&&str[i]<='9') { //we will guess by dec size
      r=strdectonum(str+i);
      if(r<=0xff    )return opsize_byte;
      if(r<=0xffff  )return opsize_word;
      if(r<=0xffffff)return opsize_long;
      return opsize_dword;
    }
    if(str[i]=='$') { //we will guess by hex length
      l=0;
      while(++i<strlen(str)) {
        if(str[i]>='0'&&str[i]<='9')l++;
        else if(str[i]>='A'&&str[i]<='F')l++;
        else if(str[i]>='a'&&str[i]<='f')l++;
        else break;
      }
      if(l<=2)return opsize_byte;
      if(l<=4)return opsize_word;
      if(l<=6)return opsize_long;
      return opsize_dword;
    }
    if(str[i]=='%') { //we will guess by bin length
      l=0;
      while(++i<strlen(str)) {
        if(str[i]=='0' || str[i]=='1')l++;
        else break;
      }
      if(l<=8 )return opsize_byte;
      if(l<=16)return opsize_word;
      if(l<=24)return opsize_long;
      return opsize_dword;
    }
  }
  return opsize_byte; //this should be changed to opsize_null and print an error
}

ulong as_getnum(void) {
int i;
char *s;
//asop_init should remove these symbols,
//but just in case...
  strtr(opdata, "#[]", "   ", 1);
  replace(opdata, " ", "", 1);
  if(strmathentity(opdata, 1)) {
    replace(opdata, "$", "0x", 1);
    replace(opdata, "%", "0b", 1);
    return strmath(opdata, 1);
  }
  s=strptr(opdata, 1);
  for(i=0;i<strlen(opdata);i++) {
    if(s[i]>='0'&&s[i]<='9')return strdectonum(s+i);
    if(s[i]=='$')return strhextonum(s+i+1);
    if(s[i]=='%')return strbintonum(s+i+1);
  }
  return 0;
}

void as_loadfile(char *fn) {
int i;
ulong fsize;
  fp=fopen(fn, "rb");
  if(!fp) {
    printf("error: [%s] not found\n", fn);
    return;
  }
  fseek(fp, 0, SEEK_END);
  fsize=ftell(fp);
  fseek(fp, 0, SEEK_SET);
  file_list[file_count].data=(char*)malloc(fsize+1);
  fread(file_list[file_count].data, 1, fsize, fp);
  file_list[file_count].data[fsize]=0;
  fclose(fp);
  i=strlen(fn);
  file_list[file_count].fn=(char*)malloc(i+1);
  strcpy(file_list[file_count].fn, fn);
  file_list[file_count].fn[i]=0;

  file_list[file_count].pfilenum  = filenum;
  file_list[file_count].plinenum  = linenum;
  file_list[file_count].pblocknum = blocknum;
  file_count++;
}

void as_setfile(char *fn) {
int i;
  for(i=0;i<file_count;i++) {
    if(!stricmp(fn, file_list[i].fn))break;
  }
  filenum=i;
  strcpy(linedata, file_list[i].data);
  replace(linedata, "\r", "");
  split(linedata, "\n");
  linenum = blocknum = 0;
}

//this is a limit on recursions (calling a macro, within a macro, ...),
//not on the number of macros possible to define (that is limited only
//by available memory)
#define __macro_rlimit 512
char *old_macroargs[__macro_rlimit];
ulong old_filenum  [__macro_rlimit],
      old_linenum  [__macro_rlimit],
      old_blocknum [__macro_rlimit],
      old_macronum [__macro_rlimit],
      current_macro = 0;

void as_beginmacro(ulong macro_num, char *arglist, ulong argcount) {
macro_item *pmacro=macros.get(macro_num);
int asl=strlen(arglist);
  if(state.inmacro>=__macro_rlimit-1) {
    error(1, "macro recursion limit (%d) reached", __macro_rlimit);
    return;
  }
  if(argcount!=pmacro->argcount) {
    error(1, "macro [%s] requires %d argument(s), %d specified",
      pmacro->s, pmacro->argcount, argcount);
    return;
  }
  state.macronum++;
  old_filenum  [state.inmacro]=filenum;
  old_linenum  [state.inmacro]=linenum;
  old_blocknum [state.inmacro]=blocknum+1; //+1 to skip this macro upon return
  old_macronum [state.inmacro]=current_macro;
  old_macroargs[state.inmacro]=(char*)malloc(asl+1);
  strcpy(old_macroargs[state.inmacro], arglist);
  current_macro              =macro_num;
  state.inmacro++;
  if(filenum != pmacro->filenum) {
    as_setfile(file_list[pmacro->filenum].fn);
  }
  linenum =pmacro->start;
  blocknum=0;
}

byte as_continuemacro(void) {
macro_item *pmacro=macros.get(current_macro);
  if(linenum > pmacro->end) {
    state.inmacro--;
    if(old_filenum[state.inmacro] != pmacro->filenum) {
      as_setfile(file_list[old_filenum[state.inmacro]].fn);
    }
    linenum      =old_linenum [state.inmacro];
    blocknum     =old_blocknum[state.inmacro];
    current_macro=old_macronum[state.inmacro];
    free(old_macroargs[state.inmacro]);
    return 1;
  }
  return 0;
}

ulong as_getmacroargnum(char *arg) {
macro_item *pmacro=macros.get(current_macro);
int i;
  split(tempstr1, ",", pmacro->a);
  for(i=0;i<count(tempstr1);i++) {
    if(!strcmp(tempstr1, arg, i))return i;
  }
  error(1, "argument [%s] not declared in macro [%s]", arg, pmacro->s);
  return 0;
}

void as_resolvemacroargs(void) {
macro_item *pmacro=macros.get(current_macro);
char *arglist=pmacro->a,
     *args=old_macroargs[state.inmacro-1],
     *s=strptr(linedata, linenum);
int i, ssl, start, end;
ulong z, argnum;

resolve_macroargs_loop:
  ssl=strlen(linedata, linenum);
//this will intentionally ignore quotes so that db,etc. can use args.
//as a side effect, < and > cannot be used inside db,etc. within macros.
  for(i=0;i<ssl;) {
    if(s[i]=='<' && s[i+1]=='<') { i+=2; continue; } //skip left shifts
    if(s[i]=='<') {
      start=i;
      i++;
      while(s[i++]!='>') {
        if(i>=ssl) { error(0, "broken macro argument"); return; }
      }
      end=i;
      strcpy(tempstr0, s+start+1);
      strset(tempstr0, strpos(tempstr0, ">"), 0);
      argnum=as_getmacroargnum(strptr(tempstr0));
      split_eq(tempstr1, ",", args);
      if(!strbegin(tempstr1, "\"", argnum) && !strend(tempstr1, "\"", argnum)) {
        strltrim(tempstr1, "\"", argnum);
        strrtrim(tempstr1, "\"", argnum);
      } else if(!strbegin(tempstr1, "\'", argnum) && !strend(tempstr1, "\'", argnum)) {
        strltrim(tempstr1, "\'", argnum);
        strrtrim(tempstr1, "\'", argnum);
      }
      strtrim(linedata, start, end-start, linenum);
      strinsert(linedata, start, strptr(tempstr1, argnum), linenum);
      goto resolve_macroargs_loop;
    } else i++;
  }
}

byte as_declaremacros(void) {
int i;
ulong argcount, z, start, end;
  strcpy(tempstr0, linedata, 0, linenum);
  split(tempstr0, " ");
  ntrim(tempstr0);
  if(count(tempstr0) == 2) {
    if(!stricmp(tempstr0, "macro")) {
      z=strpos_eq(tempstr0, "(", 1);
      if(z==null) {
        error(1, "invalid macro declaration");
        return 0;
      }
      strcpy(tempstr1, strptr(tempstr0, 1)+z);
      strset(tempstr0, z, 0, 1);
      strltrim(tempstr0, "%", 1); //allow macro x(...), or macro %x(...)
      strltrim(tempstr1, "(");
      strrtrim(tempstr1, ")");
      if(strlen(tempstr1) == 0)argcount=0;
      else {
        split_eq(tempstr2, ",", tempstr1);
        argcount=count(tempstr2);
      }
      start=++linenum;
      while(linenum<count(linedata)) {
        strcpy(tempstr3, linedata, 0, linenum);
        split(tempstr3, " ");
        ntrim(tempstr3);
        if(!stricmp(tempstr3, "endmacro"))break;
        linenum++;
      }
      if(linenum>=count(linedata)) {
        error(1, "macro declaration without matching endmacro tag");
        return 0;
      }
      if(!pass) {
        macros.add(strptr(tempstr0, 1), //macro name
                   strptr(tempstr1),    //macro arguments
                   start,               //first line# of macro
                   linenum-1,           //last line# of macro (-1 to exclude 'endmacro' line)
                   argcount);           //argument count
      }
      return 1;
    }
  }
  return 0;
}

void as_resolvedefines(void) {
int i, v, start, end, ssl;
char *s=strptr(linedata, linenum);
byte x;
define_item *pdefine;
//if this is actually defining a define, do not resolve it
  if(strpos_eq(s, "!")!=null) {
    if(strpos_eq(s, " equ ")!=null || strpos_eq(s, " = ")!=null)return;
  }

//this is used so that we can resolve any
//number of defines on a given line
define_resolve_loop:
  ssl=strlen(linedata, linenum);
  for(i=0;i<ssl;i++) {
    if(s[i]=='\"') {
      i++;
      while(i<ssl && s[i]!='\"')i++;
      i++;
    }
    if(s[i]=='!') {
      start=i;         //start of define
      i++;
      while(i<ssl) {
        if(s[i]>='A'&&s[i]<='Z');
        else if(s[i]>='a'&&s[i]<='z');
        else if(s[i]>='0'&&s[i]<='9');
        else if(s[i]=='_');
        else break;
        i++;
      }
      end=i;           //end of define
      strcpy(tempstr0, s+start);
      strset(tempstr0, end-start, 0);
      if(s[i]=='(' && s[i+1]==')')end+=2;
      v=defines.find(strptr(tempstr0));
      strtrim(linedata, start, end-start, linenum);
      if(v==null) {
        error(1, "define not declared (yet?)");
      } else {
        strinsert(linedata, start, defines.get(v), linenum);
        goto define_resolve_loop;
      }
    }
  }
}

byte as_resolvelabels(void) {
int i, start, ssl=strlen(opdata, 1);
char *s=strptr(opdata, 1), t[256];
byte x;
ulong r=0, v, l, sublabel;
  oparg_labels_unresolved=0;
  for(i=0;i<ssl;) {
    x=s[i];
    if((x>='0'&&x<='9') || x=='$' || x=='%') {
      if(x>='0'&&x<='9')x='0';
      i++;while(i<ssl) {
        if(x=='0') {
          if(s[i]>='0'&&s[i]<='9')i++;
          else break;
        } else if(x=='$') {
          if((s[i]>='0'&&s[i]<='9') || (s[i]>='A'&&s[i]<='F') || (s[i]>='a'&&s[i]<='f'))i++;
          else break;
        } else { //x=='%'
          if(s[i]=='0' || s[i]=='1')i++;
          else break;
        }
      }
      continue;
    }
    if((x>='A'&&x<='Z') || (x>='a'&&x<='z') || x=='_' || x=='.' || x=='?') {
      if     (x=='.')sublabel = 1; //sublabel
      else if(x=='?')sublabel = 2; //macrolabel
      else           sublabel = 0;
      start=i;i++;while(i<ssl) {
        if((s[i]>='A'&&s[i]<='Z') || (s[i]>='a'&&s[i]<='z') || (s[i]>='0'&&s[i]<='9') || s[i]=='_')i++;
        else break;
      }
      r=1;
      strcpy(tempstr0, s+start);
      strset(tempstr0, i-start, 0);
      if(sublabel == 1) {        //sublabel
        strltrim(tempstr0, ".");
        strinsert(tempstr0, 0, labels.lprefix);
      } else if(sublabel == 2) { //macrolabel
        strltrim(tempstr0, "?");
        sprintf(t, "__macro_%d_", state.macronum);
        strinsert(tempstr0, 0, t);
      }
      l=labels.find(tempstr0);
      if(l==null) {
        if(pass)error(0, "label [%s] not found", strptr(tempstr0));
        oparg_labels_unresolved=1;
        v=0;
      } else {
        v=labels.get(l);
        if(pass && !labels.getpass(l))oparg_labels_unresolved=1;
      }
      strtrim(opdata, start, i-start, 1);
      sprintf(t, "%d", v);
      strinsert(opdata, start, t, 1);
      i=start+strlen(t);
      ssl=strlen(opdata, 1);
      continue;
    }
    i++;
  }
  return r;
}

ulong as_relative(ulong v, byte s) {
ulong pc=state.pc+s;
if(state.base) pc=(pc-state.basepc)+state.base;

  if(pass) {
    if(s==1) {   //byte
      if(pc>v) { //negative branch
        if((v-pc)<0xffffff80)error(0, "negative branch too long, exceeded bounds");
      } else {   //positive branch
        if((v-pc)>0x0000007f)error(0, "positive branch too long, exceeded bounds");
      }
    } else {     //word
      if(pc>v) { //negative branch
        if((v-pc)<0xffff8000)error(0, "negative branch too long, exceeded bounds");
      } else {   //positive branch
        if((v-pc)>0x00007fff)error(0, "positive branch too long, exceeded bounds");
      }
    }
  }
  return v-pc;
}

void as_invalidop(void) {
  if(!pass)error(0, "invalid opcode or command");
}

void as1n_fn(byte x, ulong v) {
ulong i;
  for(i=0;i<v;i++) {
    state.opcount++;
    fputb(x);
  }
}

void as2c_fn(byte x, byte t, ulong v, ulong size) {
  state.opcount++;
  fputb(x);
  if(assume.f_mx) {
    if(assume.mx&t)fputb(v);
    else fputw(v);
  } else {
    if(size==opsize_byte)fputb(v);
    else fputw(v);
  }
}

void as2l_fn(byte x, ulong v, ulong size) {
  state.opcount++;
  if(assume.f_db && !oparg_labels_unresolved) {
    if(assume.db == ((v>>16)&0xff)) {
      fputb(x-2); //this is only possible because of the way the snes cpu was designed
      fputw(v);   //example: af-2=ad [af=lda.l label;ad=lda.w label]
      return;
    }
  }
force_long:
  fputb(x);
  fputl(v);
}

void as2b_rs(byte v) {
  if(assume.f_mx) {
    if(v&0x20)assume.mx&=~2;
    if(v&0x10)assume.mx&=~1;
  }
}

void as2b_ss(byte v) {
  if(assume.f_mx) {
    if(v&0x20)assume.mx|=2;
    if(v&0x10)assume.mx|=1;
  }
}

#define asop_init(l, r) striltrim(opdata, l, 1);strirtrim(opdata, r, 1); \
  oparg_labels=as_resolvelabels();byte size=as_setsize();ulong v=as_getnum()

#define as1(s, x) else if(!stricmp(opdata, s))     { state.opcount++; fputb(x); return;                       }
#define as1n(s, x) else if(!stricmp(opdata, s))    { as1n_fn(x, v); return;                                   }
#define as2b(s, x) else if(!stricmp(opdata, s))    { state.opcount++; fputb(x); fputb(v); return;             }
#define as2br(s, x) else if(!stricmp(opdata, s))   { state.opcount++; fputb(x); fputb(v); as2b_rs(v); return; }
#define as2bs(s, x) else if(!stricmp(opdata, s))   { state.opcount++; fputb(x); fputb(v); as2b_ss(v); return; }
#define as2w(s, x) else if(!stricmp(opdata, s))    { state.opcount++; fputb(x); fputw(v); return;             }
#define as2l(s, x) else if(!stricmp(opdata, s))    { as2l_fn(x, v, size); return;                             }
#define as2lf(s, x) else if(!stricmp(opdata, s))   { state.opcount++; fputb(x); fputl(v); return;             }
#define as2c(s, x, t) else if(!stricmp(opdata, s)) { as2c_fn(x, t, v, size); return;                          }
#define as2rb(s, x) else if(!stricmp(opdata, s))   { state.opcount++; \
  fputb(x); if(!oparg_labels)fputb(v); else fputb(as_relative(v, 1)); return;                                 }
#define as2rw(s, x) else if(!stricmp(opdata, s))   { state.opcount++; \
  fputb(x); if(!oparg_labels)fputw(v); else fputw(as_relative(v, 2)); return;                                 }

void assemble_op_1immediate(void) { ulong v=0; if(0);
  as1("php", 0x08) as1("asl", 0x0a) as1("phd", 0x0b) as1("clc", 0x18)
  as1("inc", 0x1a) as1("tcs", 0x1b) as1("plp", 0x28) as1("rol", 0x2a)
  as1("pld", 0x2b) as1("sec", 0x38) as1("dec", 0x3a) as1("tsc", 0x3b)
  as1("rti", 0x40) as1("pha", 0x48) as1("lsr", 0x4a) as1("phk", 0x4b)
  as1("cli", 0x58) as1("phy", 0x5a) as1("tcd", 0x5b) as1("rts", 0x60)
  as1("pla", 0x68) as1("ror", 0x6a) as1("rtl", 0x6b) as1("sei", 0x78)
  as1("ply", 0x7a) as1("tdc", 0x7b) as1("dey", 0x88) as1("txa", 0x8a)
  as1("phb", 0x8b) as1("tya", 0x98) as1("txs", 0x9a) as1("txy", 0x9b)
  as1("tay", 0xa8) as1("tax", 0xaa) as1("plb", 0xab) as1("clv", 0xb8)
  as1("tsx", 0xba) as1("tyx", 0xbb) as1("iny", 0xc8) as1("dex", 0xca)
  as1("wai", 0xcb) as1("cld", 0xd8) as1("phx", 0xda) as1("stp", 0xdb)
  as1("inx", 0xe8) as1("nop", 0xea) as1("xba", 0xeb) as1("sed", 0xf8)
  as1("plx", 0xfa) as1("xce", 0xfb)
  as1("dea", 0x3a) as1("ina", 0x1a) as1("tad", 0x5b) as1("tda", 0x7b)
  as1("tas", 0x1b) as1("tsa", 0x3b) as1("swa", 0xeb)
  as2b("brk", 0x00) as2b("cop", 0x02)
  as_invalidop();
}

void assemble_op1a(void) {
  if(0);
  as1("asl", 0x0a) as1("lsr", 0x4a) as1("rol", 0x2a) as1("ror", 0x6a)
  as1("inc", 0x1a) as1("dec", 0x3a)
  as_invalidop();
}

void assemble_op2constant(void) { asop_init ( "#" , "" );
  if(size==opsize_byte || size==opsize_word || size==opsize_none) { if(0);
    as2c("ora", 0x09, 2) as2c("and", 0x29, 2) as2c("eor", 0x49, 2) as2c("adc", 0x69, 2)
    as2c("bit", 0x89, 2) as2c("lda", 0xa9, 2) as2c("cmp", 0xc9, 2) as2c("sbc", 0xe9, 2)
    as2c("cpx", 0xe0, 1) as2c("cpy", 0xc0, 1) as2c("ldx", 0xa2, 1) as2c("ldy", 0xa0, 1)
    as1n("asl", 0x0a) as1n("lsr", 0x4a) as1n("rol", 0x2a) as1n("ror", 0x6a)
    as1n("inc", 0x1a) as1n("dec", 0x3a) as1n("inx", 0xe8) as1n("dex", 0xca)
    as1n("iny", 0xc8) as1n("dey", 0x88) as1n("nop", 0xea)
  }
  if(size==opsize_byte || size==opsize_none) { if(0);
    as2br("rep", 0xc2) as2bs("sep", 0xe2) as2b("brk", 0x00) as2b("cop", 0x02)
  }
  as_invalidop();
}

void assemble_op2stack_relative_indexed_indirect_y(void) { asop_init ( "(" , ",s),y" );
  if(size==opsize_byte || size==opsize_none) { if(0);
    as2b("ora", 0x13) as2b("and", 0x33) as2b("eor", 0x53) as2b("adc", 0x73)
    as2b("sta", 0x93) as2b("lda", 0xb3) as2b("cmp", 0xd3) as2b("sbc", 0xf3)
  }
  as_invalidop();
}

void assemble_op2indirect_long_indexed_y(void) { asop_init ( "[" , "],y" );
  if(size==opsize_byte || size==opsize_none) { if(0);
    as2b("ora", 0x17) as2b("and", 0x37) as2b("eor", 0x57) as2b("adc", 0x77)
    as2b("sta", 0x97) as2b("lda", 0xb7) as2b("cmp", 0xd7) as2b("sbc", 0xf7)
  }
  as_invalidop();
}

void assemble_op2indirect_long(void) { asop_init ( "[" , "]" );
  if(size==opsize_byte || size==opsize_none) { if(0);
    as2b("ora", 0x07) as2b("and", 0x27) as2b("eor", 0x47) as2b("adc", 0x67)
    as2b("sta", 0x87) as2b("lda", 0xa7) as2b("cmp", 0xc7) as2b("sbc", 0xe7)
  }
  if(size==opsize_word || size==opsize_none) { if(0);
    as2w("jmp", 0xdc) as2w("jml", 0xdc)
  }
  as_invalidop();
}

void assemble_op2indirect_indexed_x(void) { asop_init ( "(" , ",x)" );
  if(size==opsize_byte || size==opsize_none) { if(0);
    as2b("ora", 0x01) as2b("and", 0x21) as2b("eor", 0x41) as2b("adc", 0x61)
    as2b("sta", 0x81) as2b("lda", 0xa1) as2b("cmp", 0xc1) as2b("sbc", 0xe1)
  }
  if(size==opsize_word || size==opsize_none) { if(0);
    as2w("jmp", 0x7c) as2w("jsr", 0xfc)
  }
  as_invalidop();
}

void assemble_op2indirect_indexed_y(void) { asop_init ( "(" , "),y" );
  if(size==opsize_byte || size==opsize_none) { if(0);
    as2b("ora", 0x11) as2b("and", 0x31) as2b("eor", 0x51) as2b("adc", 0x71)
    as2b("sta", 0x91) as2b("lda", 0xb1) as2b("cmp", 0xd1) as2b("sbc", 0xf1)
  }
  as_invalidop();
}

void assemble_op2indirect(void) { asop_init ( "(" , ")" );
  if(size==opsize_byte || size==opsize_none) { if(0);
    as2b("ora", 0x12) as2b("and", 0x32) as2b("eor", 0x52) as2b("adc", 0x72)
    as2b("sta", 0x92) as2b("lda", 0xb2) as2b("cmp", 0xd2) as2b("sbc", 0xf2)
    as2b("pei", 0xd4)
  }
  if(size==opsize_word || size==opsize_none) { if(0);
    as2w("jmp", 0x6c)
  }
  as_invalidop();
}

void assemble_op2stack_relative(void) { asop_init ( "" , ",s" );
  if(size==opsize_byte || size==opsize_none) { if(0);
    as2b("ora", 0x03) as2b("and", 0x23) as2b("eor", 0x43) as2b("adc", 0x63)
    as2b("sta", 0x83) as2b("lda", 0xa3) as2b("cmp", 0xc3) as2b("sbc", 0xe3)
  }
  as_invalidop();
}

void assemble_op2indexed_x(void) { asop_init( "" , ",x" );
  if(size==opsize_byte) { if(0);
    as2b("ora", 0x15) as2b("and", 0x35) as2b("eor", 0x55) as2b("adc", 0x75)
    as2b("sta", 0x95) as2b("lda", 0xb5) as2b("cmp", 0xd5) as2b("sbc", 0xf5)
    as2b("asl", 0x16) as2b("bit", 0x34) as2b("rol", 0x36) as2b("lsr", 0x56)
    as2b("stz", 0x74) as2b("ror", 0x76) as2b("ldy", 0xb4) as2b("dec", 0xd6)
    as2b("inc", 0xf6)
  }
  if(size==opsize_byte || size==opsize_none) { if(0);
    as2b("sty", 0x94)
  }
  if(size==opsize_word) { if(0);
    as2w("ora", 0x1d) as2w("and", 0x3d) as2w("eor", 0x5d) as2w("adc", 0x7d)
    as2w("sta", 0x9d) as2w("lda", 0xbd) as2w("cmp", 0xdd) as2w("sbc", 0xfd)
    as2w("asl", 0x1e) as2w("bit", 0x3c) as2w("rol", 0x3e) as2w("lsr", 0x5e)
    as2w("ror", 0x7e) as2w("stz", 0x9e) as2w("ldy", 0xbc) as2w("dec", 0xde)
    as2w("inc", 0xfe)
  }
  if(size==opsize_long || size==opsize_none) { if(0);
    as2l("ora", 0x1f) as2l("and", 0x3f) as2l("eor", 0x5f) as2l("adc", 0x7f)
    as2l("sta", 0x9f) as2l("lda", 0xbf) as2l("cmp", 0xdf) as2l("sbc", 0xff)
  }
  as_invalidop();
}

void assemble_op2indexed_y(void) { asop_init ( "" , ",y" );
  if(size==opsize_byte) { if(0);
    as2b("ldx", 0xb6)
  }
  if(size==opsize_byte || size==opsize_none) { if(0);
    as2b("stx", 0x96)
  }
  if(size==opsize_word || size==opsize_none) { if(0);
    as2w("ora", 0x19) as2w("and", 0x39) as2w("eor", 0x59) as2w("adc", 0x79)
    as2w("sta", 0x99) as2w("lda", 0xb9) as2w("cmp", 0xd9) as2w("sbc", 0xf9)
    as2w("ldx", 0xbe)
  }
  as_invalidop();
}

void assemble_op2absolute(void) {
  if(!stricmp(opdata,"mvn") || !stricmp(opdata,"mvp")){
    replace_eq(opdata,",",", ",1);
    split(tempstr3, " ", opdata, 1);
    if(count(tempstr3)==2){
      strcpy(opdata,tempstr3,1,0); strrtrim(opdata, ",", 1);
      oparg_labels=as_resolvelabels(); byte size=as_setsize(); ulong v=as_getnum();
      strcpy(opdata,tempstr3,1,1);
      oparg_labels=as_resolvelabels(); byte size2=as_setsize(); ulong v2=as_getnum();
      if( (size==opsize_byte || size==opsize_none) && (size2==opsize_byte || size2==opsize_none) ){
        ++state.opcount;
        fputb( ( !stricmp(opdata,"mvp") ? 0x44 : 0x54) ); fputb(v); fputb(v2);
      }else as_invalidop();
      return;
    }
  }
  asop_init ( "" , "" );

  if(size==opsize_byte || size==opsize_none) { if(0);
    as2rb("bra", 0x80)
    as2rb("bcc", 0x90) as2rb("bcs", 0xb0) as2rb("beq", 0xf0) as2rb("bne", 0xd0)
    as2rb("bmi", 0x30) as2rb("bpl", 0x10) as2rb("bvc", 0x50) as2rb("bvs", 0x70)
  }
  if(size==opsize_word || size==opsize_none) { if(0);
    as2rw("brl", 0x82) as2rw("per", 0x62)
  }
  if(size==opsize_byte) { if(0);
    as2b("ora", 0x05) as2b("and", 0x25) as2b("eor", 0x45) as2b("adc", 0x65)
    as2b("sta", 0x85) as2b("lda", 0xa5) as2b("cmp", 0xc5) as2b("sbc", 0xe5)
    as2b("tsb", 0x04) as2b("asl", 0x06) as2b("trb", 0x14) as2b("bit", 0x24)
    as2b("rol", 0x26) as2b("lsr", 0x46) as2b("stz", 0x64) as2b("ror", 0x66)
    as2b("sty", 0x84) as2b("stx", 0x86) as2b("ldy", 0xa4) as2b("ldx", 0xa6)
    as2b("cpy", 0xc4) as2b("dec", 0xc6) as2b("cpx", 0xe4) as2b("inc", 0xe6)
  }
  if(size==opsize_word) { if(0);
    as2w("ora", 0x0d) as2w("and", 0x2d) as2w("eor", 0x4d) as2w("adc", 0x6d)
    as2w("sta", 0x8d) as2w("lda", 0xad) as2w("cmp", 0xcd) as2w("sbc", 0xed)
    as2w("mvn", 0x54) as2w("mvp", 0x44)
  }
  if(size==opsize_word || size==opsize_long || size==opsize_none) { if(0);
    as2w("tsb", 0x0c) as2w("asl", 0x0e) as2w("trb", 0x1c) as2w("bit", 0x2c)
    as2w("rol", 0x2e) as2w("lsr", 0x4e) as2w("ror", 0x6e) as2w("sty", 0x8c)
    as2w("stx", 0x8e) as2w("stz", 0x9c) as2w("ldy", 0xac) as2w("ldx", 0xae)
    as2w("cpy", 0xcc) as2w("dec", 0xce) as2w("cpx", 0xec) as2w("inc", 0xee)
  }
  if(size==opsize_long || size==opsize_none) { if(0);
    as2l("ora", 0x0f) as2l("and", 0x2f) as2l("eor", 0x4f) as2l("adc", 0x6f)
    as2l("sta", 0x8f) as2l("lda", 0xaf) as2l("cmp", 0xcf) as2l("sbc", 0xef)
  }
  if(size==opsize_word || size==opsize_none) { if(0);
    as2w("jmp", 0x4c) as2w("jsr", 0x20) as2w("pea", 0xf4)
  }
  if(size==opsize_long || size==opsize_none) { if(0);
    as2lf("jmp", 0x5c) as2lf("jsr", 0x22)
    as2lf("jml", 0x5c) as2lf("jsl", 0x22)
  }
  as_invalidop();
}

void assemble_op(void) {
int i, l, ssl;
ulong v, z, vpc, zpc, fsize;
char *s, *data;
FILE *wf;
byte *fdata;
char t[256];
  if(!opargs)return;

//resolve +/- labels
  if(opargs==1) {
    if(!strcmp(opdata, "+",   0) || !strcmp(opdata, "-",   0) ||
       !strcmp(opdata, "++",  0) || !strcmp(opdata, "--",  0) ||
       !strcmp(opdata, "+++", 0) || !strcmp(opdata, "---", 0)) {
      if(!strcmp(opdata, "+",   0))v=0;if(!strcmp(opdata, "-",   0))v=3;
      if(!strcmp(opdata, "++",  0))v=1;if(!strcmp(opdata, "--",  0))v=4;
      if(!strcmp(opdata, "+++", 0))v=2;if(!strcmp(opdata, "---", 0))v=5;
      sprintf(t, ".__br_%s%d_%d", (v<=2)?"pos":"neg", (v<=2)?v+1:v-3+1, state.brcount[v]);
      strcpy(opdata, t, 0);
      state.brcount[v]++;
    }
  } else if(opargs==2) {
    if(!strcmp(opdata, "+",   1) || !strcmp(opdata, "-",   1) ||
       !strcmp(opdata, "++",  1) || !strcmp(opdata, "--",  1) ||
       !strcmp(opdata, "+++", 1) || !strcmp(opdata, "---", 1)) {
      if(!strcmp(opdata, "+",   1))v=0;if(!strcmp(opdata, "-",   1))v=3;
      if(!strcmp(opdata, "++",  1))v=1;if(!strcmp(opdata, "--",  1))v=4;
      if(!strcmp(opdata, "+++", 1))v=2;if(!strcmp(opdata, "---", 1))v=5;
      sprintf(t, ".__br_%s%d_%d", (v<=2)?"pos":"neg", (v<=2)?v+1:v-3+1, (v<=2)?state.brcount[v]:state.brcount[v]-1);
      strcpy(opdata, t, 1);
    }
  }

  if(opargs==1) {
    if(!strbegin(opdata, "%")) {
      if(state.inmacro)strcpy(linedata, macroline, linenum, 0);
      strltrim(opdata, "%");
      v=strpos_eq(opdata, "(");
      if(v == null) {
        error(0, "macro declared improperly");
        return;
      }
      strcpy(tempstr0, strptr(opdata)+v);
      strset(opdata, v, 0);
      strltrim(tempstr0, "(");
      strrtrim(tempstr0, ")");
      if(strlen(tempstr0) == 0)z=0;
      else {
        split_eq(tempstr1, ",", tempstr0);
        z=count(tempstr1);
      }
      v=macros.find(strptr(opdata));
      if(v == null) {
        if(!pass)error(0, "macro not defined");
        return;
      }
      as_beginmacro(v,                //macro number
                    strptr(tempstr0), //macro arguments
                    z);               //number of macro arguments
      return;
    } else if(!strend(opdata, ":") || !strend(opdata, "()") ||
        !strbegin(opdata, ".") || (!strbegin(opdata, "?") && !strend(opdata, ":")) ||
        !strcmp(opdata, "+") || !strcmp(opdata, "-")) {
      labels.add(opdata, as_basetopc(state.pc));
    } else if(!stricmp(opdata, "lorom")) {
      state.mode=mode_lorom;
      state.pc=0x008000;
      setpcfp();
    } else if(!stricmp(opdata, "hirom")) {
      state.mode=mode_hirom;
      state.pc=0xc00000;
      setpcfp();
    } else if(!stricmp(opdata, "flat")) {
      state.mode=mode_flat;
      state.pc=0x000000;
      setpcfp();
    } else if(!stricmp(opdata, "ips")) {
      // write header
      if (!state.ips) {
        state.ips = 1;
        state.ipsoffset = 0;
        state.ipscount = 0;
        if (pass) {
          fputc('P',wr);
          fputc('A',wr);
          fputc('T',wr);
          fputc('C',wr);
          fputc('H',wr);
        }
      }
    } else if(!stricmp(opdata, "setipsrec")) {
      set_ipsoffset(as_getnum());
    } else if(!stricmp(opdata, "header")) {
      state.header=1;
      setpcfp();
    } else if(!stricmp(opdata, "export.close")) {
      if(pass) {
        if(exportfp)fclose(exportfp);
      }
    } else if(!stricmp(opdata, "cleartable")) {
      for(i=0;i<256;i++)state.table[i]=i;
    }
    else assemble_op_1immediate();
  }

  else if(opargs==2) {
    if(!stricmp(opdata, "org")) {
      state.pc=as_getnum();
      setpcfp();
    } else if(!stricmp(opdata, "ipsoffset")) {
      set_ipsoffset(as_getnum());
    } else if(!stricmp(opdata, "base")) {
      if(!stricmp(opdata, "off", 1))state.base = 0;
      else                          state.base = as_getnum();
      state.basepc = state.pc;
    } else if(!stricmp(opdata, "assume")) {
      split_eq(tempstr1, ",", opdata, 1);
      for(i=0;i<count(tempstr1);i++) {
        split_eq(tempstr2, ":", tempstr1, i);
        if(count(tempstr2) != 2)error(0, "invalid assume argument");
        else {
          if(!stricmp(tempstr2, "mx", 0)) {
            if     (!stricmp(tempstr2, "off", 1))assume.f_mx=0;
            else if(!stricmp(tempstr2, "on",  1))assume.f_mx=1;
            else {
              assume.f_mx=1;
              if     (!strcmp(tempstr2, "%00", 1))assume.mx=0;
              else if(!strcmp(tempstr2, "%01", 1))assume.mx=1;
              else if(!strcmp(tempstr2, "%10", 1))assume.mx=2;
              else if(!strcmp(tempstr2, "%11", 1))assume.mx=3;
              else if(!strcmp(tempstr2, "%0-", 1))assume.mx&=1;
              else if(!strcmp(tempstr2, "%1-", 1))assume.mx|=2;
              else if(!strcmp(tempstr2, "%-0", 1))assume.mx&=2;
              else if(!strcmp(tempstr2, "%-1", 1))assume.mx|=1;
              else error(0, "invalid assume argument");
            }
          } else if(!stricmp(tempstr2, "db", 0)) {
            if(!stricmp(tempstr2, "off", 1))assume.f_db=0;
            else {
              assume.f_db=1;
              strcpy(opdata, tempstr2, 1, 1);
              assume.db=as_getnum();
            }
          } else if(!stricmp(tempstr2, "d", 0)) {
          } else error(0, "invalid assume argument");
        }
      }
    } else if(!stricmp(opdata, "namespace")) {
      if(!stricmp(opdata, "off", 1))strset(lnamespace, 0, 0);
      else {
        if(!strbegin(opdata, "\"", 1) && !strend(opdata, "\"", 1)) {
          strltrim(opdata, "\"", 1);strrtrim(opdata, "\"", 1);
        } else if(!strbegin(opdata, "\'", 1) && !strend(opdata, "\'", 1)) {
          strltrim(opdata, "\'", 1);strrtrim(opdata, "\'", 1);
        } else error(0, "invalid namespace argument");
        strcpy(lnamespace, opdata, 0, 1);
        strcat(lnamespace, "_");
      }
    } else if(!stricmp(opdata, "export.open")) {
      if(pass) {
        if(!strbegin(opdata, ">>", 1)) {
          strltrim(opdata, ">>", 1);
          strcpy(t, "rb+wb");
        } else if(!strbegin(opdata, ">", 1)) {
          strltrim(opdata, ">", 1);
          strcpy(t, "wb");
        } else strcpy(t, "wb");
        exportfp=fopen(strptr(opdata, 1), t);
        if(!exportfp)error(0, "failed to open export file [%s]", strptr(opdata, 1));
        if(!strcmp(t, "rb+wb"))fseek(exportfp, 0, SEEK_END);
      }
    } else if(!stricmp(opdata, "export.label")) {
      if(pass) {
        if(!exportfp)error(0, "you must use export.open to select a file first");
        else {
          fprintf(exportfp, "%s = $", strptr(opdata, 1));
          as_resolvelabels();
          fprintf(exportfp, "%0.6x\r\n", as_getnum());
        }
      }
    } else if(!stricmp(opdata, "export.define")) {
      if(pass) {
        if(!exportfp)error(0, "you must use export.open to select a file first");
        else {
          strinsert(opdata, 0, "!", 1);
          fprintf(exportfp, "%s = ", strptr(opdata, 1));
          v=defines.find(strptr(opdata, 1));
          if(v==null) {
            error(0, "error: define not found");
            fprintf(exportfp, "{error}\r\n");
          }
          else {
            s=defines.get(v);
            fprintf(exportfp, "\"%s\"\r\n", s);
          }
        }
      }
    } else if(!stricmp(opdata, "fillbyte")) {
      state.fillbyte=as_getnum();
    } else if(!stricmp(opdata, "padbyte")) {
      state.padbyte=as_getnum();
    } else if(!stricmp(opdata, "fill")) {
      v=as_getnum();
      inc_pc(v);
      if(pass) {
        // FIXME: support ips
        fdata=(byte*)malloc(v);
        memset(fdata, state.fillbyte, v);
        fwrite(fdata, 1, v, wr);
        free(fdata);
      }
    } else if(!stricmp(opdata, "pad")) {
      v=as_getnum(); vpc=sfctopc(v);
      z=state.pc;    zpc=sfctopc(z);
      if(vpc>=zpc) { //don't pad if we've already gone past specified location
        v=vpc-zpc;
        inc_pc(v);
        if(pass) {
          // FIXME: support ips
          fdata=(byte*)malloc(v);
          memset(fdata, state.padbyte, v);
          fwrite(fdata, 1, v, wr);
          free(fdata);
        }
      }
    } else if(!stricmp(opdata, "reset")) {
      if(pass) {
        split_eq(tempstr1, ",", opdata, 1);
        for(i=0;i<count(tempstr1);i++) {
          if(!stricmp(tempstr1, "bytes",   i))state.bytecount=0;
          if(!stricmp(tempstr1, "opcodes", i))state.opcount  =0;
        }
      }
    } else if(!stricmp(opdata, "print")) {
      if(pass) {
        split_eq(tempstr1, ",", opdata, 1);
        for(i=0;i<count(tempstr1);i++) {
          if     (!stricmp(tempstr1, "pc",      i))printf("%0.6x", state.pc        );
          else if(!stricmp(tempstr1, "bytes",   i))printf("%d",    state.bytecount );
          else if(!stricmp(tempstr1, "opcodes", i))printf("%d",    state.opcount   );
          else if((!strbegin(tempstr1, "\"", i) && !strend(tempstr1, "\"", i)) ||
                  (!strbegin(tempstr1, "\'", i) && !strend(tempstr1, "\'", i))) {
            if(!strbegin(tempstr1, "\"", i) && !strend(tempstr1, "\"", i)) {
              strltrim(tempstr1, "\"", i);strrtrim(tempstr1, "\"", i);
            } else {
              strltrim(tempstr1, "\'", i);strrtrim(tempstr1, "\'", i);
            }
            replace(tempstr1, "\\n", "\n", i);
            replace(tempstr1, "\\t", "\t", i);
            replace(tempstr1, "\\\\", "\\", i);
            printf(strptr(tempstr1, i));
          }
        }
        printf("\n");
      }
    } else if(!stricmp(opdata, "table")) {
      split_eq(tempstr1, ",", opdata, 1);
      wf=fopen(strptr(tempstr1), "rb");
      if(!wf) {
        if(!pass)error(0, "file not found");
      } else {
        memset(state.table, 0, 256);
        z=0; //default to left-to-right [A=00]
        if(count(tempstr1) == 2) {
          if(!stricmp(tempstr1, "ltr", 1) || !stricmp(tempstr1, "l", 1))z=0;
          if(!stricmp(tempstr1, "rtl", 1) || !stricmp(tempstr1, "r", 1))z=1;
        }
        fseek(wf, 0, SEEK_END);
        fsize=ftell(wf);
        fseek(wf, 0, SEEK_SET);
        data=(char*)malloc(fsize+1);
        fread(data, 1, fsize, wf);
        fclose(wf);
        data[fsize]=0;
        strcpy(tempstr1, data);
        free(data);
        replace(tempstr1, "\r", "");
        split(tempstr1, "\n");
        ntrim(tempstr1);
        for(i=0;i<count(tempstr1);i++) {
          split(tempstr2, "=", tempstr1, i);
          if(count(tempstr2) == 2) {
            if(!z) { //left-to-right [A=00]
              v=strhextonum(tempstr2, 1);
              s=strptr(tempstr2, 0);
              state.table[s[0]]=v;
            } else { //right-to-left [00=A]
              v=strhextonum(tempstr2, 0);
              s=strptr(tempstr2, 1);
              state.table[s[0]]=v;
            }
          }
        }
      }
    } else if(!stricmp(opdata, "incsrc") || !stricmp(opdata, "import")) {
      if(!pass)as_loadfile(strptr(opdata, 1));
      as_setfile(strptr(opdata, 1));
    } else if(!stricmp(opdata, "incbin")) {
      wf=fopen(strptr(opdata, 1), "rb");
      if(!wf)error(0, "file not found");
      else {
        fseek(wf, 0, SEEK_END);
        fsize=ftell(wf);
        if (!state.ips) {
          inc_pc(fsize);
          if(pass) {
            fseek(wf, 0, SEEK_SET);
            fdata=(byte*)malloc(fsize);
            fread(fdata, 1, fsize, wf);
            fwrite(fdata, 1, fsize, wr);
            free(fdata);
          }
        }
        else {
          // chop the file into $8000 sized chunks
          for (i=0;i<fsize;i+=0x8000) {
            ulong cursize = min(0x8000, fsize - i);
            inc_pc(cursize);
            if (pass) {
              fseek(wf, i, SEEK_SET);
              fdata=(byte*)malloc(cursize);
              fread(fdata, 1, cursize, wf);
              fwrite(fdata, 1, cursize, wr);
              free(fdata);
              if (i + 0x8000 < fsize) {
                add_ipsrecord(get_ipsoffset() + 0x8000);
              }
            }
          }
        }
        fclose(wf);
      }
    } else if(!stricmp(opdata, "loadpc")) {
      split_eq(tempstr1, ",", opdata, 1);
      wf=fopen(strptr(tempstr1), "rb");
      if(!wf) {
        if(!pass)error(0, "file not found");
      } else {
        if(count(tempstr1) == 1)v=0;
        else {
          strcpy(opdata, tempstr1, 1, 1);
          v=as_getnum();
        }
        fseek(wf, 0, SEEK_END);
        z=ftell(wf);
        if(v*4>=z) {
          if(!pass)error(0, "requested pc value past end of file");
        } else {
          fseek(wf, v*4, SEEK_SET);
          state.pc =fgetc(wf)    ;state.pc|=fgetc(wf)<< 8;
          state.pc|=fgetc(wf)<<16;state.pc|=fgetc(wf)<<24;
          setpcfp();
        }
        fclose(wf);
      }
    } else if(!stricmp(opdata, "savepc")) {
      if(pass) {
        split_eq(tempstr1, ",", opdata, 1);
        wf=fopen(strptr(tempstr1), "rb+wb");
        if(!wf)wf=fopen(strptr(tempstr1), "wb");
        if(count(tempstr1) == 1)v=0;
        else {
          strcpy(opdata, tempstr1, 1, 1);
          v=as_getnum();
        }
        fseek(wf, v*4, SEEK_SET);
        fputc(state.pc    , wf);fputc(state.pc>> 8, wf);
        fputc(state.pc>>16, wf);fputc(state.pc>>24, wf);
        fclose(wf);
      }
    } else if(!stricmp(opdata, "warnpc")) {
      if(pass) {
        v=as_getnum();
        if(state.pc>=v)error(0, "warnpc() value >= pc [pc=%0.6x]", state.pc);
      }
    } else if(!stricmp(opdata, "skip")) {
      // FIXME: support ips
      inc_pc(as_getnum());
      setpcfp();
    } else if(!stricmp(opdata, "db") || !stricmp(opdata, "dw") ||
              !stricmp(opdata, "dl") || !stricmp(opdata, "dd")) {
      if(!stricmp(opdata, "db"))z=opsize_byte;
      if(!stricmp(opdata, "dw"))z=opsize_word;
      if(!stricmp(opdata, "dl"))z=opsize_long;
      if(!stricmp(opdata, "dd"))z=opsize_dword;
      split_eq(tempstr1, ",", opdata, 1);
      for(i=0;i<count(tempstr1);i++) {
        if((!strbegin(tempstr1, "\"", i) && !strend(tempstr1, "\"", i)) ||
           (!strbegin(tempstr1, "\'", i) && !strend(tempstr1, "\'", i))) {
          s=strptr(tempstr1, i);
          ssl=strlen(s);
          for(l=1;l<ssl-1;l++) {
            v=state.table[s[l]];
            if     (z==opsize_byte )fputb(v);
            else if(z==opsize_word )fputw(v);
            else if(z==opsize_long )fputl(v);
            else if(z==opsize_dword)fputd(v);
          }
        } else {
          strcpy(opdata, tempstr1, 1, i); //as_ functions work on opdata[1] only
          as_resolvelabels();
          v=as_getnum();
          if     (z==opsize_byte )fputb(v);
          else if(z==opsize_word )fputw(v);
          else if(z==opsize_long )fputl(v);
          else if(z==opsize_dword)fputd(v);
        }
      }
    } else if(!stricmp(opdata, "rep") && strbegin(opdata, "#", 1)) {
      state.rep=as_getnum();
    } //strend for endings with no alphas, striend for case insensitive endings with alphas
    else if(!stricmp (opdata, "a", 1)                                )assemble_op1a();
    else if(!strbegin(opdata, "#", 1)                                )assemble_op2constant();
    else if(!strbegin(opdata, "(", 1) && !striend(opdata, ",s),y", 1))assemble_op2stack_relative_indexed_indirect_y();
    else if(!strbegin(opdata, "[", 1) && !striend(opdata, "],y",   1))assemble_op2indirect_long_indexed_y();
    else if(!strbegin(opdata, "[", 1) && !strend (opdata, "]",     1))assemble_op2indirect_long();
    else if(!strbegin(opdata, "(", 1) && !striend(opdata, ",x)",   1))assemble_op2indirect_indexed_x();
    else if(!strbegin(opdata, "(", 1) && !striend(opdata, "),y",   1))assemble_op2indirect_indexed_y();
    else if(!strbegin(opdata, "(", 1) && !strend (opdata, ")",     1))assemble_op2indirect();
    else if(                             !striend(opdata, ",s",    1))assemble_op2stack_relative();
    else if(                             !striend(opdata, ",x",    1))assemble_op2indexed_x();
    else if(                             !striend(opdata, ",y",    1))assemble_op2indexed_y();
    else                                                              assemble_op2absolute();
  } else if(opargs==3) {
    if(!stricmp(opdata, "equ", 1) || !strcmp(opdata, "=", 1)) {
      if(!strbegin(opdata, "\"", 2) && !strend(opdata, "\"", 2)) {
        strltrim(opdata, "\"", 2);strrtrim(opdata, "\"", 2);
      } else if(!strbegin(opdata, "\'", 2) && !strend(opdata, "\'", 2)) {
        strltrim(opdata, "\'", 2);strrtrim(opdata, "\'", 2);
      }
      if(!strbegin(opdata, "!", 0)) {
        defines.add(strptr(opdata, 0), strptr(opdata, 2));
      } else {
        strcpy(opdata, opdata, 1, 2);
        as_resolvelabels();
        labels.add(opdata, as_getnum(), 0);
      }
    } else as_invalidop();
  } else as_invalidop();
}

void as_splitblocks(void) {
int i, num;
  split_eq(blockdata, " : ", linedata,  linenum);
  split_eq(opdata,    " ",   blockdata, 0      );
  ntrim(opdata);
//if there is a label for the first arg
  if(!strend(opdata, ":") || !strend(opdata, "()") ||
    !strbegin(opdata, ".") || (!strbegin(opdata, "?") && !strend(opdata, ":")) ||
    !strcmp(opdata, "+"  ) || !strcmp(opdata, "-"  ) ||
    !strcmp(opdata, "++" ) || !strcmp(opdata, "--" ) ||
    !strcmp(opdata, "+++") || !strcmp(opdata, "---"))
  {
    if(count(opdata) == 1)return; //line already contains ' : ' or is label only
    num=count(blockdata);
    for(i=num;i>=1;i--)strcpy(blockdata, strptr(blockdata, i-1), i);
    strcpy(blockdata, opdata, 0, 0);
  //remove the label from the first [now second] block
    i=strpos_eq(blockdata, opdata, 1, 0);
    strtrim(blockdata, i, strlen(opdata), 1);
  }
}

void assemble(char *dfn, char *sfn) {
int i, r, fsize, x, l, z, im, cf;

  wr=fopen(dfn, "rb+");
  if(!wr) {
    wr=fopen(dfn, "wb");
    for(i=0;i<32768;i++)fputc(0, wr);
    fclose(wr);
    wr=fopen(dfn, "rb+wb");
  }

  file_count = 0;
  filenum = linenum = blocknum = 0;
  as_loadfile(sfn);

  for(l=0;l<2;l++) {
    pass                               = l;
    state.pc                           = 0xc00000;
    state.mode                         = mode_hirom;
    state.header                       = 0;
    state.fillbyte = state.padbyte     = 0x00;
    state.base                         = 0;
    state.rep                          = 0;
    state.bytecount=state.opcount      = 0;
    state.inmacro=state.retmacro       = 0;
    state.macronum                     = 0;
    state.retfile                      = 0;
    state.ips                          = 0;
    state.ipsoffset                    = 0;
    state.ipscount                     = 0;
    assume.f_mx                        = 0;
    assume.f_db                        = 0;
    assume.f_d                         = 0;
    filenum                            = 0;
    for(i=0;i<  6;i++)state.brcount[i] = 0;
    for(i=0;i<256;i++)state.table[i]   = i;
    strcpy(labels.lprefix, "__null_");

    as_setfile(sfn);
line_loop:
    for(;linenum<count(linedata);linenum++) {
      if(state.inmacro)state.retmacro=as_continuemacro();
      x=strpos_eq(linedata, ";", linenum);
      if(x!=null)strset(linedata, x, 0, linenum);
      replace_eq(linedata, "\t", " ", linenum);
      replace_eq(linedata, "{",  " ", linenum);
      replace_eq(linedata, "}",  " ", linenum);
      do {
        z=strlen(linedata, linenum);
        replace_eq(linedata, ", ", ",", linenum);
      } while(strlen(linedata, linenum) != z);
      if(as_declaremacros())continue;
      if(state.inmacro) {
        strcpy(macroline, linedata, 0, linenum);
        as_resolvemacroargs();
      }
      as_resolvedefines();
      as_splitblocks();
      if(state.retmacro || state.retfile) {
        state.retmacro=state.retfile=0;
      }
      else blocknum=0;
      for(;blocknum<count(blockdata);blocknum++) {
        r=state.rep;
        if(!r)r=1;
        else state.rep=0;
        for(i=0;i<r;i++) {
          split_eq(opdata, " ", blockdata, blocknum);
          ntrim(opdata);
          opargs=count(opdata);
          im=state.inmacro;
          cf=filenum;
          assemble_op();
          if(im!=state.inmacro)goto line_loop;
          if(cf!=filenum      )goto line_loop;
        }
      }
      if(state.inmacro )strcpy(linedata, macroline, linenum, 0);
      if(state.retmacro)linenum--;
    }
    if(filenum) {
      cf=filenum;
      as_setfile(file_list[file_list[cf].pfilenum].fn);
      linenum      =file_list[cf].plinenum;
      blocknum     =file_list[cf].pblocknum+1;
      state.retfile=1;
      goto line_loop;
    }
  }
  if(exportfp)fclose(exportfp);
  if(state.ips) {
    set_ipscount(state.ipscount);
    fseek(wr, 0, SEEK_END);
    fputc('E',wr);
    fputc('O',wr);
    fputc('F',wr);
  }
  fclose(wr);
}

int main(int argc, char *argv[]) {
char sfn[256], dfn[256];

  /*argc = 3;
  argv[1] = "test.asm";
  argv[2] = "out.sfc";*/

  if(argc!=2 && argc!=3) {
    printf("xkas v0.06.1 ~byuu\nusage: xkas file.asm <file.smc>\n");
    return 0;
  }
  strcpy(sfn, argv[1]);
  if(argc==3)strcpy(dfn, argv[2]);
  else {
    strcpy(dfn, argv[1]);
    strcpy(dfn, argv[1]);
    strrtrim(dfn, ".asm");
    strcat(dfn, ".smc");
  }
  assemble(dfn, sfn);

  return 0;
}
