#include <stdlib.h>
#include <stdint.h>

#include <stdio.h>
#include <string.h>

#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

#include <sys/ioctl.h>
#include <asm/termbits.h>

class serialOpen{
public:
 int fd;

 serialOpen() {
  fd = open("/dev/ttyUSB1", O_RDWR);
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
  tio.c_lflag = 0;
  //
  tio.c_cflag &= ~CBAUD;
  tio.c_cflag |= BOTHER;
  tio.c_cflag |= CREAD;
  tio.c_cflag &= ~PARENB;
  tio.c_cflag &= ~CSTOPB;
  tio.c_cflag &= ~CSIZE;
  tio.c_cflag |= CS8;
  tio.c_cflag &= ~CRTSCTS;
  tio.c_cflag &= ~HUPCL;
  //
  tio.c_ospeed = 1000000;
  tio.c_ispeed = 1000000;
  if(ioctl(fd, TCSETS2, &tio)) {
   printf("Error from ioctl: %s\n", strerror(errno));
   close(fd);
   exit(1);
  }
 }

 ~serialOpen() {
  close(fd);
 }
};

int main() {
 serialOpen serial;
 //
 //
 unsigned char wmsg[] = {'w', 0x00,0x00,0x00,0x00, 0x04,0x00,0x00,0x00, 'a', 'S', 'd', 'F'
                        ,'r', 0x00,0x00,0x00,0x00, 0x04,0x00,0x00,0x00};
 write(serial.fd, wmsg, sizeof(wmsg));
 //
 char rbuf[256];
 memset(&rbuf, 0x00, sizeof(rbuf));

 int n = read(serial.fd, &rbuf, sizeof(rbuf));
 if (n < 0) {
  printf("Error from read: %s", strerror(errno));
  exit(1);
 }

 printf("Read %i bytes. Received message: %s", n, rbuf);
 if (n>=4) {
  printf("1111111111111111111111111111111111111111111: %x\n", *(uint32_t*)rbuf);
 }
 return 0;
}
