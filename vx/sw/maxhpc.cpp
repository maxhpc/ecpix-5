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
   int write_dcr(uint32_t addr, uint32_t value);
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
  uint32_t rbytes = 0;
  while (rbytes<cmd.sizdat) {
   int n;
   if ((n=read(fd, dest+rbytes, cmd.sizdat-rbytes))<0) {
    printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
    return -1;
   }
   rbytes += n;
  }
  return 0;
 }
 
 int maxhpc::write_dcr(uint32_t addr, uint32_t value) {
  cmd cmd = {{'W','r','c','d'}, addr, value};
  if (write(fd, &cmd, sizeof(cmd)) != sizeof(cmd)) {
   printf("Error %s:%d: %s\n", __FILE__, __LINE__, strerror(errno));
   return -1;
  }
  return 0;
 }
 
 int maxhpc::run() {
 printf("2222222222222222222222222222222222222222222222222222222222222\n");
 sleep(3);
  return 0;
 }

}
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
