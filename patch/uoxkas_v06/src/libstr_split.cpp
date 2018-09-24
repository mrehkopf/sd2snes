/***********************************************
split(dest, key, src)
  splits src by instances of key, and creates
  an array inside dest
  example: split(dest, ",", "1,2,3") will create
  array "1", "2", "3" within dest
***********************************************/
ulong split(string *dest, char *key, char *src) {
int i, z, ssl=strlen(src), ksl=strlen(key);
byte x;
ulong lp=0, split_count=0, adv_sc=0;
string_item *si=(string_item*)dest->str_list[0];
  for(i=0;i<=ssl-ksl;) {
    if(!memcmp(src+i, key, ksl)) {
      i += ksl;
      adv_sc++;
    } else i++;
  }
  if(dest->list_size < adv_sc + 1)dest->alloclist(adv_sc + 1);

  for(i=0;i<=ssl-ksl;) {
    if(!memcmp(src+i, key, ksl)) {
      x=src[i];
      src[i]=0;
      strcpy(dest, src+lp, split_count++);
      src[i]=x;
      i+=ksl;
      lp=i;
    } else i++;
  }
  strcpy(dest, src+lp, split_count++);
  dest->str_count=split_count;
  return 0;
}
ulong split_eq(string *dest, char *key, char *src) {
int i, z, ssl=strlen(src), ksl=strlen(key);
byte x;
ulong lp=0, split_count=0, adv_sc=0;
string_item *si=(string_item*)dest->str_list[0];
  for(i=0;i<=ssl-ksl;) {
    x=src[i];
    if( x=='\"' || x=='\'' ) {
      z=i++;
      while(src[i]!=x && i<ssl)i++;
      if(i>=ssl)i=z;
    }
    if(!memcmp(src+i, key, ksl)) {
      i += ksl;
      adv_sc++;
    } else i++;
  }
  if(dest->list_size < adv_sc + 1)dest->alloclist(adv_sc + 1);

  for(i=0;i<=ssl-ksl;) {
    x=src[i];
    if( x=='\"' || x=='\'' ) {
      z=i++;
      while(src[i]!=x && i<ssl)i++;
      if(i>=ssl)i=z;
    }
    if(!memcmp(src+i, key, ksl)) {
      x=src[i];
      src[i]=0;
      strcpy(dest, src+lp, split_count++);
      src[i]=x;
      i+=ksl;
      lp=i;
    } else i++;
  }
  strcpy(dest, src+lp, split_count++);
  dest->str_count=split_count;
  return 0;
}
ulong split   (string *dest, char *key, string *src, ulong str_num = 0) { return split   (dest, key, strptr(src, str_num)); }
ulong split_eq(string *dest, char *key, string *src, ulong str_num = 0) { return split_eq(dest, key, strptr(src, str_num)); }

ulong split(string *dest, char *key, ulong str_num = 0) {
string_item *si=dest->getsi(str_num);
char *src;
ulong r;
  src=(char*)malloc(si->length+1);
  memcpy(src, si->s, si->length+1);
  r=split(dest, key, src);
  free(src);
  return r;
}

ulong split_eq(string *dest, char *key, ulong str_num = 0) {
string_item *si=dest->getsi(str_num);
char *src;
ulong r;
  src=(char*)malloc(si->length+1);
  memcpy(src, si->s, si->length+1);
  r=split_eq(dest, key, src);
  free(src);
  return r;
}
