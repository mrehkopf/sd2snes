ulong __malloc_resize_value(ulong val)
{
int i;
  for(i=0;i<32;i++) {
    if(1<<i>=val)break;
  }
//if the value is >2 million, this will fail, in which case,
//just use value. otherwise, use the power of 2.
  if(1<<i>val)val=1<<i;
  return val;
}

class string_item {
public:
  char *s, *new_s;
  ulong length, max_length;

  void alloc(ulong size) {
    size=__malloc_resize_value(size);
    new_s=(char*)malloc(size+1);
    memcpy(new_s, s, max_length);
    free(s);
    s=new_s;
    max_length=size;
  }
  string_item() {
    s=(char*)malloc(257); //add one for zero terminator
    *s=0;
    length=0;
    max_length=256;
  }
  ~string_item() {
    free(s);
    length=max_length=0;
  }
};

class string {
public:
  ulong str_count, list_size;
  ulong *str_list, *new_str_list;

  void         alloclist(ulong size);
  ulong        count(void);
  string_item *getsi(ulong str_num);
  string() {
    str_list=0;
    str_count=1;
    list_size=0;
    alloclist(32);
  }
  ~string() {
  string_item *si;
    for(int i=0;i<list_size;i++) {
      si=getsi(i);
      delete(si);
    }
    free(str_list);
  }
};

void string::alloclist(ulong size) {
int i;
string_item *si;
  if(list_size>size)return;
  size=__malloc_resize_value(size);
  new_str_list=(ulong*)malloc(size*4);
  memcpy(new_str_list, str_list, list_size*4);
  for(i=list_size;i<size;i++) {
    si=new string_item();
    new_str_list[i]=(ulong)si;
  }
  if(str_list)free(str_list);
  str_list=new_str_list;
  list_size=size;
}

/***************************************
count(str)
  returns number of array entries in str
***************************************/
ulong string::count(void) {
  return str_count;
}
ulong count(string *str) { return str->count(); }

string_item *string::getsi(ulong str_num)
{
  if(str_num >= list_size)alloclist(str_num+1);
  if(str_num >= str_count)str_count=str_num+1;
  return (string_item*)str_list[str_num];
}

/*************************************
ntrim(str)
  removes all empty strings from array
  within str
*************************************/
void ntrim(string *str) {
int i, l;
string_item *si;
ulong x;
trim_loop:
  for(i=0;i<str->str_count;) {
    si=(string_item*)str->str_list[i];
    if(!*si->s) {
      x=str->str_list[i];
      for(l=i;l<str->str_count-1;l++)str->str_list[l]=str->str_list[l+1];
      str->str_list[--str->str_count]=x;
    } else i++;
  }
}

/**************************************
strptr(str)
  returns a (char*) pointer to a string
**************************************/
char *strptr(string *str, ulong str_num = 0) {
string_item *si=str->getsi(str_num);
  return si->s;
}

//functions used before being defined
void strcpy(string *dest, char *src, ulong str_num);
void strcpy(string *dest, string *src, ulong dest_str_num, ulong src_str_num);
char *strptr(string *str, ulong str_num);

#include "libstr_split.cpp"
#include "libstr_replace.cpp"

/*******************
strset(str, pos, c)
  sets str[pos] to c
*******************/
void strset(string *str, ulong pos, byte c, ulong str_num = 0) {
string_item *si=str->getsi(str_num);
  if(pos>si->max_length)si->alloc(pos);
  si->s[pos]=c;
  if(!c && si->length>pos)si->length=pos;
}

/**********************************
strcat(dest, src)
  attaches dest onto the end of src
**********************************/
void strcat(string *dest, char *src, ulong str_num = 0) {
ulong src_strlen = strlen(src), true_src_strlen;         //get source string length
string_item *si=dest->getsi(str_num);                    //set class pointer to dest string
  true_src_strlen = src_strlen;                          //save a backup of original source string length
  src_strlen += si->length;                              //get the length of source+dest strings combined
  if(si->max_length < src_strlen) si->alloc(src_strlen); //if this exceeds the existing string length, resize it
  memcpy(si->s + si->length, src, true_src_strlen);      //attach the src string to the end of dest string
  si->s[src_strlen] = 0;                                 //add string terminator value
  si->length = src_strlen;                               //set new string length
}
void strcat(string *dest, string *src, ulong dest_str_num = 0, ulong src_str_num = 0) { strcat(dest, strptr(src, src_str_num), dest_str_num); }

/**********************
strlen(str)
  returns length of str
**********************/
ulong strlen(string *str, ulong str_num = 0) {
string_item *si=str->getsi(str_num);
  return si->length;
}

/*****************************************
strinsert(dest, pos, src)
  inserts src into dest at pos
  example: strinsert("tt", 1, "es")="test"
*****************************************/
void strinsert(string *dest, ulong pos, char *src, ulong str_num = 0) {
ulong src_strlen = strlen(src), true_src_strlen;
string_item *si=dest->getsi(str_num);
string *t=new string();
int i;
  true_src_strlen = src_strlen;
  src_strlen += si->length;
  if(si->max_length < src_strlen)si->alloc(src_strlen);
  strcpy(t, strptr(dest, str_num)+pos, 0);
  strset(dest, pos, 0, str_num);
  strcat(dest, src, str_num);
  strcat(dest, t, str_num);
  delete(t);
}
void strinsert(string *dest, ulong pos, string *src, ulong dest_str_num = 0, ulong src_str_num = 0) {
  strinsert(dest, pos, strptr(src, src_str_num), dest_str_num); }

/*********************************************
strtrim(str, start, length)
  removes specified portion of string from str
  example: strtrim("test", 1, 2)="tt"
*********************************************/
void strtrim(char *str, ulong start, ulong length = 0) {
int i, ssl=strlen(str);
  if(!length) { str[start]=0; return; }
  for(i=start;i<=ssl;i++)str[i]=(i+length<=ssl)?str[i+length]:0;
}

void strtrim(string *str, ulong start, ulong length = 0, ulong str_num = 0) {
string_item *si=str->getsi(str_num);
int i;
  if(!length) {
    if(si->length>start) {
      si->s[start]=0;
      si->length=start;
    }
    return;
  }
  for(i=start;i<=si->length;i++) {
    si->s[i]=(i+length<=si->length)?si->s[i+length]:0;
  }
  si->length-=length;
}

/**********************************************
strcmp(dest, src) : stricmp(dest, src)
  compares dest to src, if they match, function
  will return 0 (true), otherwise, 1 (false)
**********************************************/
byte strcmp(string *dest, char *src, ulong str_num = 0) {
string_item *si=dest->getsi(str_num);
  if(!strcmp(si->s, src))return 0; //true,  equal
  return 1;                        //false, not equal
}
byte strcmp(string *dest, string *src, ulong dest_str_num = 0, ulong src_str_num = 0) {
  return strcmp(dest, strptr(src, src_str_num), dest_str_num); }

byte stricmp(char *dest, char *src) {
ulong dl=strlen(dest), sl=strlen(src);
int i;
  if(dl!=sl)return 1;//false
  for(i=0;i<sl;i++) {
    if(src[i]>='A'&&src[i]<='Z') {
      if(src[i]!=dest[i]&&(src[i]+0x20)!=dest[i])return 1;//false
    } else if(src[i]>='a'&&src[i]<='z') {
      if(src[i]!=dest[i]&&(src[i]-0x20)!=dest[i])return 1;//false
    } else if(src[i]!=dest[i])return 1;//false
  }
  return 0;//true
}
byte stricmp(string *dest, char *src, ulong str_num = 0) { return stricmp(strptr(dest, str_num), src); }
byte stricmp(string *dest, string *src, ulong dest_str_num = 0, ulong src_str_num = 0) {
  return stricmp(strptr(dest, dest_str_num), strptr(src, src_str_num));
}

/*********************
strcpy(dest, src)
  copies src into dest
*********************/
void strcpy(string *dest, char *src, ulong str_num = 0) {
ulong src_strlen = strlen(src);                          //get source string length
string_item *si=dest->getsi(str_num);                    //set class pointer to dest string
  if(si->max_length < src_strlen)si->alloc(src_strlen);  //if src length exceeds dest string length, resize dest string
  memcpy(si->s, src, src_strlen);                        //copy src string into dest string
  si->s[src_strlen] = 0;                                 //add string terminator value
  si->length = src_strlen;                               //set new string length
}
void strcpy(string *dest, string *src, ulong dest_str_num = 0, ulong src_str_num = 0) { strcpy(dest, strptr(src, src_str_num), dest_str_num); }

/**************************************************
strlower(str)
  converts all capital letters to lowercase letters
**************************************************/
void strlower(string *str, ulong str_num = 0) {
string_item *si=str->getsi(str_num);
  strlwr(si->s);
}
void strlwr(string *str, ulong str_num = 0) { strlower(str, str_num); }

/**************************************************
strupper(str)
  converts all lowercase letters to capital letters
**************************************************/
void strupper(string *str, ulong str_num = 0) {
string_item *si=str->getsi(str_num);
  strupr(si->s);
}
void strupr(string *str, ulong str_num = 0) { strupper(str, str_num); }

/*******************************************************
strpos(str, key) : strpos_eq(str, key)
  will return the first position where key exists within
  str, if key does not exist within str, will return -1
*******************************************************/
ulong strpos(char *str, char *key) {
int i, z, ssl=strlen(str), ksl=strlen(key);
byte x;
  if(ksl>ssl)return null;
  for(i=0;i<=ssl-ksl;i++) {
    if(!memcmp(str+i, key, ksl))return i;
  }
  return null;
}
ulong strpos(string *str, char *key, ulong str_num = 0) { return strpos(strptr(str, str_num), key); }
ulong strpos(string *str, string *key, ulong str_num = 0, ulong key_num = 0) {
  return strpos(strptr(str, str_num), strptr(key, key_num)); }

ulong strpos_eq(char *str, char *key) {
int i, z, ssl=strlen(str), ksl=strlen(key);
byte x;
  if(ksl>ssl)return null;
  for(i=0;i<=ssl-ksl;) {
    x=str[i];
    if( x=='\"' || x=='\'' ) {
      z=i++;
      while(str[i]!=x && i<ssl)i++;
      if(i>=ssl)i=z;
    }
    if(!memcmp(str+i, key, ksl)) {
      return i;
    } else i++;
  }
  return null;
}
ulong strpos_eq(string *str, char *key, ulong str_num = 0) { return strpos_eq(strptr(str, str_num), key); }
ulong strpos_eq(string *str, string *key, ulong str_num = 0, ulong key_num = 0) {
  return strpos_eq(strptr(str, str_num), strptr(key, key_num)); }

/********************************************************
strtr(str, before, after)
  will scan str for all instances of before[] and replace
  them with after[], the before and after are 1-byte
  arrays. example: strtr(str, "ABCDEF", "abcdef")
********************************************************/
void strtr(string *str, char *before, char *after, ulong str_num = 0) {
string_item *si=str->getsi(str_num);
int i, l, ssl=strlen(before);
  if(strlen(after)!=ssl)return; //invalid strtr arguments
  for(i=0;i<si->length;i++) {
    for(l=0;l<ssl;l++) {
      if(si->s[i]==before[l])si->s[i]=after[l];
    }
  }
}

/**********************************************************
strbegin(str, key) : stribegin(str, key)
  if the beginning of str matches key, function will return
  0 (true), otherwise function will return 1 (false)
**********************************************************/
byte strbegin(char *str, char *key) {
int i, ssl=strlen(str), ksl=strlen(key);
  if(ksl>ssl)return 1;
  if(!memcmp(str, key, ksl))return 0;
  return 1;
}
byte strbegin(string *str, char *key, ulong str_num = 0) { return strbegin( strptr(str, str_num), key); }
byte strbegin(string *str, string *key, ulong str_num = 0, ulong key_num = 0) { return strbegin( strptr(str, str_num), strptr(key, key_num) ); }

byte stribegin(char *str, char *key) {
int i, z, ssl=strlen(str), ksl=strlen(key);
  if(ksl>ssl)return 1;
  for(i=z=0;i<ksl;i++, z++) {
    if(str[i]>='A'&&str[i]<='Z') {
      if(str[i]!=key[z] && str[i]+0x20!=key[z])return 1;
    } else if(str[i]>='a'&&str[i]<='z') {
      if(str[i]!=key[z] && str[i]-0x20!=key[z])return 1;
    } else {
      if(str[i]!=key[z])return 1;
    }
  }
  return 0;
}
byte stribegin(string *str, char *key, ulong str_num = 0) { return stribegin( strptr(str, str_num), key); }
byte stribegin(string *str, string *key, ulong str_num = 0, ulong key_num = 0) { return stribegin( strptr(str, str_num), strptr(key, key_num) ); }

/****************************************************
strend(str, key) : striend(str, key)
  if the end of str matches key, function will return
  0 (true), otherwise function will return 1 (false)
****************************************************/
byte strend(char *str, char *key) {
int i, ssl=strlen(str), ksl=strlen(key);
  if(ksl>ssl)return 1;
  if(!memcmp(str+ssl-ksl, key, ksl))return 0;
  return 1;
}
byte strend(string *str, char *key, ulong str_num = 0) { return strend( strptr(str, str_num), key); }
byte strend(string *str, string *key, ulong str_num = 0, ulong key_num = 0) { return strend( strptr(str, str_num), strptr(key, key_num) ); }

byte striend(char *str, char *key) {
int i, z, ssl=strlen(str), ksl=strlen(key);
  if(ksl>ssl)return 1;
  for(i=ssl-ksl, z=0;i<ssl;i++, z++) {
    if(str[i]>='A'&&str[i]<='Z') {
      if(str[i]!=key[z] && str[i]+0x20!=key[z])return 1;
    } else if(str[i]>='a'&&str[i]<='z') {
      if(str[i]!=key[z] && str[i]-0x20!=key[z])return 1;
    } else {
      if(str[i]!=key[z])return 1;
    }
  }
  return 0;
}
byte striend(string *str, char *key, ulong str_num = 0) { return striend( strptr(str, str_num), key); }
byte striend(string *str, string *key, ulong str_num = 0, ulong key_num = 0) { return striend( strptr(str, str_num), strptr(key, key_num) ); }

/*********************************************************
strltrim(str, key) : striltrim(str, key)
  if key matches the beginning of str, then key is removed
  from the beginning of str
*********************************************************/
void strltrim(char *str, char *key) {
int i, ssl=strlen(str), ksl=strlen(key);
  if(ksl>ssl)return;
  if(!strbegin(str, key)) {
    for(i=0;i<ssl-ksl;i++)str[i]=str[i+ksl];
    str[i]=0;
  }
}

void strltrim(string *str, char *key, ulong str_num = 0) {
int i, ksl;
string_item *si=str->getsi(str_num);
  if(!strbegin(str, key, str_num)) {
    ksl=strlen(key);
    for(i=0;i<si->length-ksl;i++)si->s[i]=si->s[i+ksl];
    si->s[i]=0;
    si->length-=ksl;
  }
}
void strltrim(string *str, string *key, ulong str_num = 0, ulong key_num = 0) { strltrim(str, strptr(key, key_num), str_num); }

void striltrim(char *str, char *key) {
int i, ssl=strlen(str), ksl=strlen(key);
  if(ksl>ssl)return;
  if(!stribegin(str, key)) {
    for(i=0;i<ssl-ksl;i++)str[i]=str[i+ksl];
    str[i]=0;
  }
}

void striltrim(string *str, char *key, ulong str_num = 0) {
int i, ksl;
string_item *si=str->getsi(str_num);
  if(!stribegin(str, key, str_num)) {
    ksl=strlen(key);
    for(i=0;i<si->length-ksl;i++)si->s[i]=si->s[i+ksl];
    si->s[i]=0;
    si->length-=ksl;
  }
}
void striltrim(string *str, string *key, ulong str_num = 0, ulong key_num = 0) { striltrim(str, strptr(key, key_num), str_num); }

/***************************************************
strrtrim(str, key) : strirtrim(str, key)
  if key matches the end of str, then key is removed
  from the beginning of str
***************************************************/
void strrtrim(char *str, char *key) {
int ssl=strlen(str), ksl=strlen(key);
  if(ksl>ssl)return;
  if(!strend(str, key)) {
    str[ssl-ksl]=0;
    return;
  }
}

void strrtrim(string *str, char *key, ulong str_num = 0) {
int ksl;
string_item *si=str->getsi(str_num);
char *s=si->s;
  if(!strend(str, key, str_num)) {
    ksl=strlen(key);
    s[si->length-ksl]=0;
    si->length-=ksl;
  }
}
void strrtrim(string *str, string *key, ulong str_num = 0, ulong key_num = 0) { strrtrim(str, strptr(key, key_num), str_num); }

void strirtrim(char *str, char *key) {
int ssl=strlen(str), ksl=strlen(key);
  if(ksl>ssl)return;
  if(!striend(str, key)) {
    str[ssl-ksl]=0;
    return;
  }
}

void strirtrim(string *str, char *key, ulong str_num = 0) {
int ksl;
string_item *si=str->getsi(str_num);
char *s=si->s;
  if(!striend(str, key, str_num)) {
    ksl=strlen(key);
    s[si->length-ksl]=0;
    si->length-=ksl;
  }
}
void strirtrim(string *str, string *key, ulong str_num = 0, ulong key_num = 0) { strirtrim(str, strptr(key, key_num), str_num); }

/****************************************************
strhextonum(str)
  scans str to determine how many letters forward are
  hex values, when finished, it will convert this to
  a number and return this value
****************************************************/
ulong strhextonum(char *str) {
ulong r=0, m=0;
int i, ssl=strlen(str);
byte x;
//first, go forward to find the end of the hex string,
//the function will stop if an invalid hex value is found.
  for(i=0;i<ssl;i++) {
    if(str[i]>='0'&&str[i]<='9');
    else if(str[i]>='A'&&str[i]<='F');
    else if(str[i]>='a'&&str[i]<='f');
    else break;
  }
//now convert this value from a string hex value to a
//numerical hex value.
  for(--i;i>=0;i--, m+=4) {
    x=str[i];
    if(x>='0'&&x<='9')x-='0';
    else if(x>='A'&&x<='F')x-='A'-0x0a;
    else if(x>='a'&&x<='f')x-='a'-0x0a;
    else return r;
    r|=x<<m;
  }
  return r;
}
ulong strhextonum(string *str, ulong str_num = 0) { return strhextonum(strptr(str, str_num)); }

/****************************************************
strdectonum(str)
  scans str to determine how many letters forward are
  decimal values, when finished, it will convert this
  to a number and return this value
****************************************************/
ulong strdectonum(char *str) {
ulong r=0, m=1;
int i, ssl=strlen(str);
byte x;
  for(i=0;i<ssl;i++) {
    if(str[i]>='0'&&str[i]<='9');
    else break;
  }
  for(--i;i>=0;i--, m*=10) {
    x=str[i]-'0';
    r+=x*m;
  }
  return r;
}
ulong strdectonum(string *str, ulong str_num = 0) { return strdectonum(strptr(str, str_num)); }

/****************************************************
strbintonum(str)
  scans str to determine how many letters forward are
  binary values, when finished, it will convert this
  to a number and return this value
****************************************************/
ulong strbintonum(char *str) {
ulong r=0, m=0;
int i, ssl=strlen(str);
byte x;
  for(i=0;i<ssl;i++) {
    if(str[i]=='0'||str[i]=='1');
    else break;
  }
  for(--i;i>=0;i--, m++) {
    x=str[i]-'0';
    r|=x<<m;
  }
  return r;
}
ulong strbintonum(string *str, ulong str_num = 0) { return strbintonum(strptr(str, str_num)); }

#include "libstr_math.cpp"
