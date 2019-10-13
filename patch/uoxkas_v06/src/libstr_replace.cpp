/*********************************************************
replace(str, key, token) : replace_eq(str, key, token)
  replaces all instances of key with token from within str
*********************************************************/
void replace(string *str, char *key, char *token, ulong str_num = 0) {
string_item *si=str->getsi(str_num);
int i, z, ksl=strlen(key), tsl=strlen(token);
ulong replace_count=0, size=si->length;
char *data;
  if(ksl>si->length)return;
  if(tsl>ksl) {                        //the new string may be longer than the old string...
    for(i=0;i<=si->length-ksl;) {      //so let's find out how big of a string we'll need...
      if(!memcmp(si->s+i, key, ksl)) {
        replace_count++;
        i+=ksl;
      } else i++;
    }
    size=si->length+((tsl-ksl)*replace_count);
    if(size>si->max_length)si->alloc(size);
  }
  data=(char*)malloc(size+1);
  for(i=z=0;i<si->length;) {
    if(i<=si->length-ksl) {
      if(!memcmp(si->s+i, key, ksl)) {
        memcpy(data+z, token, tsl);
        z+=tsl;
        i+=ksl;
      } else data[z++]=si->s[i++];
    } else data[z++]=si->s[i++];
  }
  data[z]=0;
  strcpy(str, data, str_num);
  free(data);
}

void replace_eq(string *str, char *key, char *token, ulong str_num = 0) {
string_item *si=str->getsi(str_num);
int i, l, z, ksl=strlen(key), tsl=strlen(token);
byte x;
ulong replace_count=0, size=si->length;
char *data;
  if(ksl>si->length)return;
  if(tsl>ksl) {
    for(i=0;i<=si->length-ksl;) {
      x=si->s[i];
      if(x=='\"' || x=='\'') {
        l=i;i++;while(si->s[i++]!=x) {
          if(i==si->length) { i=l; break; }
        }
      }
      if(!memcmp(si->s+i, key, ksl)) {
        replace_count++;
        i+=ksl;
      } else i++;
    }
    size=si->length+((tsl-ksl)*replace_count);
    if(size>si->max_length)si->alloc(size);
  }
  data=(char*)malloc(size+1);
  for(i=z=0;i<si->length;) {
    x=si->s[i];
    if(x=='\"' || x=='\'') {
      l=i++;
      while(si->s[i]!=x && i<si->length)i++;
      if(i>=si->length)i=l;
      else {
        memcpy(data+z, si->s+l, i-l);
        z+=i-l;
      }
    }
    if(i<=si->length-ksl) {
      if(!memcmp(si->s+i, key, ksl)) {
        memcpy(data+z, token, tsl);
        z+=tsl;
        i+=ksl;
        replace_count++;
      } else data[z++]=si->s[i++];
    } else data[z++]=si->s[i++];
  }
  data[z]=0;
  strcpy(str, data, str_num);
  free(data);
}
