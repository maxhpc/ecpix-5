// maxhpc: Maxim Vorontsov

#include <maxhpc.h>

#include <stdlib.h>
#include <stdint.h>

#include <stdio.h>
#include <string.h>

#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

#include <sys/ioctl.h>
#include <asm/termbits.h>

using namespace vortex;

class maxhpc::Impl {
public:
 bool dev_ok = 0;

 Impl(const char* dev_path) {
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

 ~Impl() {
  close(fd);
 }

 int ddrW(uint32_t addr, const void* src, uint32_t size) {
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

 void write_dcr(uint32_t addr, uint32_t value) {
printf("111111111111111111111111111111111111111111111111111111111111\n");
  return;
 }

 int run() {
printf("2222222222222222222222222222222222222222222222222222222222222\n");
sleep(3);
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

maxhpc::maxhpc(const char* dev_path) : Impl_(new Impl(dev_path)) {
}

maxhpc::~maxhpc() {
 delete Impl_;
}

int maxhpc::ddrW(uint32_t addr, const void* src, uint32_t size) {
 return Impl_->ddrW(addr, src, size);
}

int maxhpc::ddrR(void* dest, uint32_t addr, uint32_t size) {
 return Impl_->ddrR(dest, addr, size);
}

void maxhpc::write_dcr(uint32_t addr, uint32_t value) {
 Impl_->write_dcr(addr, value);
}

int maxhpc::run() {
 return Impl_->run();
}
