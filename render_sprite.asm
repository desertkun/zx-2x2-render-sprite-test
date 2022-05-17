extern _screen_characters
extern _tiles
extern _tile_colors
extern screen_characters
extern asm_zx_cxy2saddr
extern asm_zx_cxy2aaddr

public _render_sprite

render_sprite_buffer:
    defs 128                            ; 4x4 buffer of 8 bytes characters

    ; data in this buffer is arranged like so (X x Y), left to right top to bottom:
    ;
    ; [byte 0 of tile 0x0] [byte 0 of tile 1x0] [byte 0 of tile 2x0] [byte 0 of tile 3x0]
    ; [byte 1 of tile 0x0] [byte 1 of tile 1x0] [byte 1 of tile 2x0] [byte 1 of tile 3x0]
    ; ...
    ; [byte 7 of tile 0x0] [byte 7 of tile 1x0] [byte 7 of tile 2x0] [byte 7 of tile 3x0]
    ;
    ; [byte 0 of tile 0x1] [byte 0 of tile 1x1] [byte 0 of tile 2x1] [byte 0 of tile 3x1]
    ; [byte 1 of tile 0x1] [byte 1 of tile 1x1] [byte 1 of tile 2x1] [byte 1 of tile 3x1]
    ; ...
    ; [byte 7 of tile 0x1] [byte 7 of tile 1x1] [byte 7 of tile 2x1] [byte 7 of tile 3x1]
    ;
    ; and so on for two more rows

render_sprite_color_buffer:
    defs 16                             ; 4x4 buffer for color info

render_sprite_fn_buffer:
    ; render render_sprite_buffer onto the screen
    ; bc points to screen location (b - y, c - x)
    ; de points on the render_sprite_buffer
    ; affected: hl

    ld hl, bc
    call asm_zx_cxy2saddr               ; hl now holds screen address

    include "client_graphics_inc/render_sprite_fn_buffer.inc"
    include "client_graphics_inc/render_sprite_fn_buffer.inc"
    include "client_graphics_inc/render_sprite_fn_buffer.inc"
    include "client_graphics_inc/render_sprite_fn_buffer.inc"
    include "client_graphics_inc/render_sprite_fn_buffer.inc"
    include "client_graphics_inc/render_sprite_fn_buffer.inc"
    include "client_graphics_inc/render_sprite_fn_buffer.inc"
    include "client_graphics_inc/render_sprite_fn_buffer.inc"

    ret

render_sprite_bake_bg_tile:
    ; bake background of tiles into render_sprite_buffer
    ; bc points to screen location (b - y, c - x)
    ; de points on the render_sprite_buffer
    ; affected: hl

    push bc                             ; preserve screen location
    push de                             ; preserve render_sprite_buffer pointer

    ld h, 0
    ld l, b
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl                          ; multiply by 32
    ld b, 0
    add hl, bc                          ; add "x"
    ld bc, _screen_characters
    add hl, bc                          ; hl now contains _screen_characters at location xy

    ld b, 0
    ld c, (hl)                          ; get the tile index at the coords

    ld hl, bc
    add hl, hl
    add hl, hl
    add hl, hl                          ; multiply ix by 8
    ld bc, _tiles
    add hl, bc                          ; hl now points to tile data

    ld b, 8

render_sprite_bake_backgound_tile_loop:
    ld c, (de)                          ; bake tile line into render_sprite_buffer
    ld a, (hl)
    xor c
    inc hl                              ; next tile data line
    ld (de), a
    inc de                              ; next line
    inc de
    inc de
    inc de

    dec b
    jp nz, render_sprite_bake_backgound_tile_loop

    pop de                              ; restore render_sprite_buffer pointer
    pop bc                              ; restore screen location
    ret

render_sprite_preshift_tile:
    ; pre-shift one tile off a sprite to render_sprite_buffer
    ; ix should point to sprite data, it gets shifted as sprite data is consumed
    ; de points on the render_sprite_buffer
    ; bc points to the offsets (8 bits max, b - vertically, c - horisontally)
    ; affected: hl, de, ix

    push bc                             ; preserve bc (pixel offsets)

    push de
    ld h, 0
    ld a, 8
    sub c                               ; 2 pixels means 6 jump skips (__render_sprite_tile_shift)
    add a
    add a
    ld l, a
    ld de, __render_sprite_tile_shift
    add hl, de                          ; store a number of shifts
    pop de

    push hl

    ld h, 0                             ; shifting vertically is easy
    ld l, b                             ; just shift hl pointer by B * 4

    add hl, hl
    add hl, hl                          ; multiply ix by 4
    add hl, de                          ; shift hl (render_sprite_buffer pointer)
    ld bc, hl                           ; by B lines, so hl is now shifted vertically

    pop hl

    ld a, 8                             ; b is now free, we can use it to count 8 times

render_sprite_tile_loop:
    ex af, af'

    ld d, (ix)                          ; (ix) -> d, 0 -> e
    ld e, 0                             ; de now contains 8 bits of pixel data, ready to be shifted right
    inc ix                              ; onto next sprite data byte

    jp (hl)

__render_sprite_tile_shift:
    ; ever shift here take 4 bytes
    ; hl uses that, as it contains address __render_sprite_tile_shift shifted
    ; by 4 times the c
    ; 1
    srl d
    rr  e
    ; 2
    srl d
    rr  e
    ; 3
    srl d
    rr  e
    ; 4
    srl d
    rr  e
    ; 5
    srl d
    rr  e
    ; 6
    srl d
    rr  e
    ; 7
    srl d
    rr  e
    ; 8
    srl d
    rr  e

__render_sprite_tile_shift_done:
    ld a, (bc)                          ; push shifted pixels onto render_sprite_buffer pointer
    or d
    ld (bc), a                          ; put first byte
    inc bc
    ld a, (bc)
    or e
    ld (bc), a                          ; put second byte

    inc bc                              ; onto next render_sprite_buffer row (4 - 1)
    inc bc
    inc bc

    ex af, af'
    dec a
__render_sprite_preshift_tile_bf:
    jp nz, render_sprite_tile_loop      ; loop 8 times

    pop bc                              ; restore bc (pixel offsets)
__render_sprite_preshift_tile_done:
    ret

_render_sprite:
    ; stack arguments:
    ; - xy offset in pixels
    ; - pointer to sprite data (2x2)
    ; - xy in characters

    pop iy                              ; store ret address

    ld hl, render_sprite_buffer
    ld de, render_sprite_buffer + 1
    ld bc, 127
    ld (hl), 0
    ldir                                ; zero out render_sprite_buffer

    pop bc                              ; get xy offset in pixels
    pop ix                              ; get pointer to sprite data

    ld de, render_sprite_buffer        ; pre-shift tile 0x0 into buffer 0x0
    call render_sprite_preshift_tile

    ld de, render_sprite_buffer + 1    ; pre-shift tile 1x0 into buffer 1x0
    call render_sprite_preshift_tile

    ld de, render_sprite_buffer + 32    ; pre-shift tile 0x1 into buffer 0x1
    call render_sprite_preshift_tile

    ld de, render_sprite_buffer + 33    ; pre-shift tile 1x1 into buffer 1x1
    call render_sprite_preshift_tile

__render_sprite_preshifted:

    ; render_sprite_tile now contains baked pre-shifted tile set
    ; we now need to xor it with "background" of tiles

    pop bc                              ; get xy location

    ; now we have to bake 4x4 onto the buffer
    ld de, render_sprite_buffer

    ; bake 4 rows (4 columns each)
    include "client_graphics_inc/render_sprite_bake_bg_tile_row.inc"
    ld de, render_sprite_buffer + 32
    include "client_graphics_inc/render_sprite_bake_bg_tile_row.inc"
    ld de, render_sprite_buffer + 64
    include "client_graphics_inc/render_sprite_bake_bg_tile_row.inc"
    ld de, render_sprite_buffer + 96
    include "client_graphics_inc/render_sprite_bake_bg_tile_row.inc"

    dec b
    dec b
    dec b
    dec b                               ; unwind 4 rows

__render_sprite_baked:

    ; render 16 tiles (4 tiles for each row)

    ld de, render_sprite_buffer
    call render_sprite_fn_buffer
    inc b
    ld de, render_sprite_buffer + 32
    call render_sprite_fn_buffer
    inc b
    ld de, render_sprite_buffer + 64
    call render_sprite_fn_buffer

    push iy
    ret
