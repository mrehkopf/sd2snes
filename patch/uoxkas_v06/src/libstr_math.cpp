#define STRMATH_ADD  1
#define STRMATH_SUB  2
#define STRMATH_MUL  3
#define STRMATH_DIV  4
#define STRMATH_MOD  5
#define STRMATH_AND  6
#define STRMATH_OR   7
#define STRMATH_XOR  8
#define STRMATH_SHL  9
#define STRMATH_SHR 10

#define STRMATHMODE_NEG 1
#define STRMATHMODE_NOT 2

#define __strunktonum()                            \
  t=strptr(s1);                                    \
  if(t[0]=='0'&&t[1]=='x')r=strhextonum(t+2);      \
  else if(t[0]=='0'&&t[1]=='b')r=strbintonum(t+2); \
  else r=strdectonum(t)

#define __strmath_setmode()                       \
  if     (str[i]=='-'){mode=STRMATHMODE_NEG;i++;} \
  else if(str[i]=='~'){mode=STRMATHMODE_NOT;i++;} \
  else if(str[i]=='+'){                     i++;} \
  else                mode=0

#define __strmath_modeset()            \
  if     (mode==STRMATHMODE_NEG)r*=-1; \
  else if(mode==STRMATHMODE_NOT)r=~r

#define __strmath_set(__x)   \
  strset(s1, z, 0);          \
  z=0;                       \
  __strunktonum();           \
  __strmath_modeset();       \
  array[array_size++]=r;     \
  array_gate[array_size]=__x

/***************************************
strmath(str)
  resolves all math entities from within
  str, and returns numerical result
  example: strmath("5+5")=10
***************************************/
ulong strmath(char *str) {
string *s1;
int i=0, ssl=strlen(str);
byte x, mode=0;
ulong r, array[128], array_size=0, z=0;
byte  array_gate[128];
char *t;
  if(!ssl)return 0;
  s1=new string();
  __strmath_setmode();
  while(i<ssl) {
    x=str[i++];
    if     (x=='+') { __strmath_set(STRMATH_ADD); __strmath_setmode(); }
    else if(x=='-') { __strmath_set(STRMATH_SUB); __strmath_setmode(); }
    else if(x=='*') { __strmath_set(STRMATH_MUL); __strmath_setmode(); }
    else if(x=='/') { __strmath_set(STRMATH_DIV); __strmath_setmode(); }
    else if(x=='%') { __strmath_set(STRMATH_MOD); __strmath_setmode(); }
    else if(x=='&') { __strmath_set(STRMATH_AND); __strmath_setmode(); }
    else if(x=='|') { __strmath_set(STRMATH_OR ); __strmath_setmode(); }
    else if(x=='^') { __strmath_set(STRMATH_XOR); __strmath_setmode(); }
    else if(x=='<' && str[i]=='<') { __strmath_set(STRMATH_SHL); i++; __strmath_setmode(); }
    else if(x=='>' && str[i]=='>') { __strmath_set(STRMATH_SHR); i++; __strmath_setmode(); }
    else strset(s1, z++, x);
  }
  strset(s1, z, 0);
  __strunktonum();
  __strmath_modeset();
  array[array_size++]=r;
  delete(s1);

  r=array[0];
  for(i=1;i<array_size;i++) {
    if     (array_gate[i]==STRMATH_ADD)r+= array[i];
    else if(array_gate[i]==STRMATH_SUB)r-= array[i];
    else if(array_gate[i]==STRMATH_MUL)r*= array[i];
    else if(array_gate[i]==STRMATH_DIV)r/= array[i];
    else if(array_gate[i]==STRMATH_MOD)r%= array[i];
    else if(array_gate[i]==STRMATH_AND)r&= array[i];
    else if(array_gate[i]==STRMATH_OR )r|= array[i];
    else if(array_gate[i]==STRMATH_XOR)r^= array[i];
    else if(array_gate[i]==STRMATH_SHL)r<<=array[i];
    else if(array_gate[i]==STRMATH_SHR)r>>=array[i];
  }

  return r;
}
ulong strmath(string *str, ulong str_num = 0) { return strmath(strptr(str, str_num)); }

byte strmathentity(char *str) {
int i, ssl=strlen(str);
  for(i=0;i<ssl;i++) {
    if(str[i]=='+' || str[i]=='-' || str[i]=='*' || str[i]=='/' ||
       str[i]=='%' || str[i]=='&' || str[i]=='|' || str[i]=='^' ||
      (str[i]=='<' && str[i+1]=='<') || (str[i]=='>' && str[i+1]=='>'))return 1;
  }
  return 0;
}
byte strmathentity(string *str, ulong str_num = 0) { return strmathentity(strptr(str, str_num)); }
