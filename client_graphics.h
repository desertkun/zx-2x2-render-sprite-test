#ifndef GRAPHICS_H
#define GRAPHICS_H

#include <stdint.h>

extern uint8_t screen_characters[768];

extern void render_sprite(uint16_t xy, void* sprite_data, uint16_t xy_offset) __z88dk_callee;

#endif