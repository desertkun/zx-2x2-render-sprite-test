#include "client_graphics.h"
#include "tiles.h"
#include <spectrum.h>

unsigned char testing[] = {
    0x00, 0x01, 0x07, 0x0e, 0x0d, 0x12, 0x25, 0x04, // y:0, x:0 (128)
    0x00, 0xb0, 0x48, 0xb0, 0x50, 0xd8, 0xf0, 0xe0, // y:0, x:1 (129)
    0x00, 0x03, 0x05, 0x05, 0x04, 0x09, 0x01, 0x01, // y:1, x:0 (130)
    0x00, 0x40, 0x20, 0xc0, 0x00, 0x80, 0x80, 0xc0, // y:1, x:1 (131)
};

int main()
{
    render_sprite(0x0404, testing, 0x0404);
}