// maxhpc: Maxim Vorontsov

#include <stdlib.h>
#include <stdint.h>

#include <stdio.h>
#include <string.h>

#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

#include <sys/ioctl.h>
#include <asm/termbits.h>

#include <maxhpc.h>

using namespace vortex;

int main() {
 maxhpc maxhpc_("/dev/ttyUSB1");
  if (maxhpc_.dev_stat()) {
   return -1;
  }
uint32_t tap[4];
 //
 //
//if (maxhpc_.tapW(2, 0)) {
// return -1;
//}
if (maxhpc_.tapR(&tap[0], 0)) {
 return -1;
}
printf("ttttttttttttttttttttttttttttttttttttttap0: %08x\n", tap[0]);
/* if (maxhpc_.rstW(0)) {
  return -1;
 }
 sleep(1);
 if (maxhpc_.rstW(1)) {
  return -1;
 }*/
/*if (maxhpc_.tapR(&tap[2], 2)) {
 return -1;
}
printf("ttttttttttttttttttttttttttttttttttttttap2: %08x\n", tap[2]);
if (maxhpc_.tapW(0x3, 0x3FF&(tap[2]-0x200))) {
 return -1;
}
for (uint32_t i=0; i<0x400; i++) {
 if (maxhpc_.tapR(&tap[3], 3)) {
  return -1;
 }
 printf("%03x: %08x\n", i, tap[3]);
}*/
 /////////////////////////////////////////////////////
 uint32_t addr = 0x00100280;
 uint32_t size = 0x00000100;
 //
 uint8_t* wbuf = (uint8_t*)malloc(size);
  if (wbuf==NULL) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  for (uint32_t i=0; i<size; i++) {
   wbuf[i] = i;
  }
 if (maxhpc_.ddrW(addr, wbuf, size)) {
  return -1;
 }
 //
 uint8_t* rbuf = (uint8_t*)malloc(size);
  if (wbuf==NULL) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
 if (maxhpc_.ddrR(rbuf, addr, size)) {
  return -1;
 }
 for (uint32_t i=0; i<size; i++) {
  if (rbuf[i]!=wbuf[i]) {
   printf("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee %x: %x != %x\n", i, rbuf[i], wbuf[i]);
  }
//printf("%x: %x\n", i, rbuf[i]);
 }
 free(rbuf);
 free(wbuf);
 return 0;
}
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
