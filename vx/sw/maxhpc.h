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
   int dcrW(uint32_t addr, uint32_t value);
   int rstW(bool value);
   int tapR(void* dest, uint8_t tap_i);
   int run();
  
  private:
   bool dev_ok = 0;
   int fd;
 };

}
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
