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

namespace vortex {

 class maxhpc {
  public:
   maxhpc(const char* dev_path);
   ~maxhpc();
   int dev_stat();

   int ddrW(uint32_t addr, const void* src, uint32_t size);
   int ddrR(void* dest, uint32_t addr, uint32_t size);
   int dcrW(uint32_t addr, uint32_t value);
   int rstW(bool value);
   int tapR(uint32_t* value, uint8_t tap_i);
   int tapW(uint8_t tap_i, uint32_t value);
   int run();

  private:
   bool dev_ok = 0;
   int fd;
   struct __attribute__((__packed__)) cmd {
    char opcode[4];
    uint32_t addr;
    uint32_t sizdat;
   };
 };
 
 maxhpc::maxhpc(const char* dev_path) {
  fd = open(dev_path, O_RDWR);
   if (fd < 0) {
    printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
    return;
   }
  //
  //
  struct termios2 tio;
  if(ioctl(fd, TCGETS2, &tio)) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   close(fd);
   return;
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
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   close(fd);
   return;
  }
  dev_ok = 1;
 }
 
 maxhpc::~maxhpc() {
  close(fd);
 }
 
 int maxhpc::dev_stat() {
  return (dev_ok)? 0 : -1;
 }

 ssize_t my_readn(int fd, void *buf, size_t nbyte) {
  ssize_t rbytes = 0;
  while (rbytes<nbyte) {
   ssize_t n;
   if ((n=read(fd, buf+rbytes, nbyte-rbytes))<0) {
    return n;
   }
   rbytes += n;
  }
  return rbytes;
 }

 int maxhpc::ddrW(uint32_t addr, const void* src, uint32_t size) {
  cmd cmd = {{'W','r','d','d'}, addr, size};
  if (write(fd, &cmd, sizeof(cmd)) != sizeof(cmd)) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  //
  if (write(fd, src, cmd.sizdat) != cmd.sizdat) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  return 0;
 }
 
 int maxhpc::ddrR(void* dest, uint32_t addr, uint32_t size) {
  cmd cmd = {{'R','r','d','d'}, addr, size};
  if (write(fd, &cmd, sizeof(cmd)) != sizeof(cmd)) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  //
  if (my_readn(fd, dest, cmd.sizdat)!=cmd.sizdat) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  return 0;
 }
 
 int maxhpc::dcrW(uint32_t addr, uint32_t value) {
  cmd cmd = {{'W','r','c','d'}, addr, value};
  if (write(fd, &cmd, sizeof(cmd)) != sizeof(cmd)) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  return 0;
 }
 
 int maxhpc::rstW(bool value) {
  cmd cmd = {{'W','t','s','r'}, 0, value};
  if (write(fd, &cmd, sizeof(cmd)) != sizeof(cmd)) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  return 0;
 }
 
 int maxhpc::tapR(uint32_t* dest, uint8_t tap_i) {
  cmd cmd = {{'R','p','a','t'}, tap_i, 0};
  if (write(fd, &cmd, sizeof(cmd)) != sizeof(cmd)) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  //
  if (my_readn(fd, dest, 4)!=4) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  return 0;
 }
 
 int maxhpc::tapW(uint8_t tap_i, uint32_t value) {
  cmd cmd = {{'W','p','a','t'}, tap_i, value};
  if (write(fd, &cmd, sizeof(cmd)) != sizeof(cmd)) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  return 0;
 }
 
 int maxhpc::run() {
printf("%s:%d: write garbage to 0x100280\n", __FUNCTION__, __LINE__);
  uint8_t* wbuf = (uint8_t*)malloc(0x100);
   if (wbuf==NULL) {
    printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
    return -1;
   }
   for (uint32_t i=0; i<0x100; i++) {
    wbuf[i] = random();
   }
  if (ddrW(0x100280, wbuf, 0x100)) {
   return -1;
  }
printf("%s:%d: set reset=0\n", __FUNCTION__, __LINE__);
  rstW(0);
printf("%s:%d: sleep(3)\n", __FUNCTION__, __LINE__);
sleep(3);
printf("%s:%d: set reset=1\n", __FUNCTION__, __LINE__);
  rstW(1);
  return 0;
 }

}
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
