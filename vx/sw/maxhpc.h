// maxhpc: Maxim Vorontsov

#include <stdint.h>

namespace vortex {

class maxhpc {
public:
 bool dev_ok;

 maxhpc(const char* dev_path);
 ~maxhpc();

 int ddrW(uint32_t addr, const void* src, uint32_t size);
 int ddrR(void* dest, uint32_t addr, uint32_t size);
 void write_dcr(uint32_t addr, uint32_t value);
 int run();

private:
 class Impl;
 Impl* Impl_;
};

}
