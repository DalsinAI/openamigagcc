/* Native libnix strtol end-pointer contract control. */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
struct Case {const char *input; long value; int offset;};
int main(void){
 const struct Case cases[]={{"12 3",12,2},{"",0,0},{" ",0,0},{"x",0,0},{"0",0,1},{"10x",10,2},{"-1",-1,2}};
 long (*volatile convert)(const char*,char**,int)=strtol;
 unsigned long (*volatile uconvert)(const char*,char**,int)=strtoul;int fail=0;
 for(unsigned i=0;i<sizeof cases/sizeof cases[0];i++){
  char buf[64],*end=(char*)0x11111111;strcpy(buf,cases[i].input);errno=0;long value=convert(buf,&end,10);int err=errno;
  int ok=value==cases[i].value&&end==buf+cases[i].offset;fail+=!ok;
  printf("case %u len=%u val=%ld errno=%d end=%p expected=%p %s\n",i,(unsigned)strlen(buf),value,err,(void*)end,(void*)(buf+cases[i].offset),ok?"PASS":"FAIL");
 }
 for(unsigned i=0;i<sizeof cases/sizeof cases[0];i++){
  char buf[64],*end=(char*)0x11111111;strcpy(buf,cases[i].input);errno=0;unsigned long value=uconvert(buf,&end,10);int err=errno;
  int ok=value==(unsigned long)cases[i].value&&end==buf+cases[i].offset;fail+=!ok;
  printf("unsigned case %u val=%lu errno=%d end=%p expected=%p %s\n",i,value,err,(void*)end,(void*)(buf+cases[i].offset),ok?"PASS":"FAIL");
 }
 printf("strtol/strtoul contract: %d failures\n",fail);return fail?20:0;
}
