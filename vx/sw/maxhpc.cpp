#include <stdlib.h>
#include <stdint.h>

#include <stdio.h>
#include <string.h>

#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

#include <sys/ioctl.h>
#include <asm/termbits.h>

class maxhpc {
public:
 bool dev_ok = 0;

 maxhpc(const char* dev_path) {
  fd = open(dev_path, O_RDWR);
   if (fd < 0) {
    printf("Error from open: %s\n", strerror(errno));
    exit(1);
   }
  //
  //
  struct termios2 tio;
  if(ioctl(fd, TCGETS2, &tio)) {
   printf("Error from ioctl: %s\n", strerror(errno));
   close(fd);
   exit(1);
  }
  tio.c_iflag = 0;
  tio.c_oflag = 0;
  tio.c_cflag = 0;
  tio.c_lflag = 0;
  //
  tio.c_cflag |= BOTHER;
  tio.c_cflag |= CREAD;
  tio.c_cflag |= CS8;
  //
  tio.c_ospeed = 1000000;
  tio.c_ispeed = 1000000;
  if(ioctl(fd, TCSETS2, &tio)) {
   printf("Error from ioctl: %s\n", strerror(errno));
   close(fd);
   exit(1);
  }
  dev_ok = 1;
 }

 ~maxhpc() {
  close(fd);
 }

 int ddrW(const void* src, uint32_t addr, uint32_t size) {
  cmd cmd = {{'W','r','d','d'}, addr, size};
  if (write(fd, &cmd, sizeof(cmd)) != sizeof(cmd)) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  //
  if (write(fd, src, cmd.size) != cmd.size) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  return 0;
 }

 int ddrR(void* dest, uint32_t addr, uint32_t size) {
  cmd cmd = {{'R','r','d','d'}, addr, size};
  if (write(fd, &cmd, sizeof(cmd)) != sizeof(cmd)) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  //
  uint32_t rbytes = 0;
  while (rbytes<cmd.size) {
   int n;
   if ((n=read(fd, dest+rbytes, cmd.size-rbytes))<0) {
    printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
    return -1;
   }
   rbytes += n;
  }
  return 0;
 }

private:
 int fd;
 struct __attribute__((__packed__)) cmd {
  char opcode[4];
  uint32_t addr;
  uint32_t size;
 };
};

int main() {
 maxhpc maxhpc("/dev/ttyUSB1");
  if (!maxhpc.dev_ok) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
 //
 //
 uint32_t addr = 0x80000000;
 uint32_t size = 0x00010000;
 //
 uint8_t* wbuf = (uint8_t*)malloc(size);
  if (wbuf==NULL) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  for (uint32_t i=0; i<size; i++) {
   wbuf[i] = i;
  }
 if (maxhpc.ddrW(wbuf, addr, size)) {
  return -1;
 }
 //
 uint8_t* rbuf = (uint8_t*)malloc(size);
  if (wbuf==NULL) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
 if (maxhpc.ddrR(rbuf, addr, size)) {
  return -1;
 }
 for (uint32_t i=0; i<size; i++) {
  if (rbuf[i]!=wbuf[i]) {
   printf("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee %x: %x != %x\n", i, rbuf[i], wbuf[i]);
  }
 }
 free(rbuf);
 free(wbuf);
 return 0;
}
