// maxhpc: Maxim Vorontsov

#include <stdint.h>

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
    uint32_t size;
   };
 };

}
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
