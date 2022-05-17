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

    ; pre-shift the 2x2 sprite onto the buffer
    ; we do this row-by-row, there's 16 of them, each row has 2 bytes worth of data

    ld h, 0                             ; shifting vertically is easy
    ld l, b                             ; just shift hl pointer by B * 4

    add hl, hl
    add hl, hl                          ; multiply ix by 4
    ld de, render_sprite_buffer
    add hl, de                          ; shift hl (render_sprite_buffer pointer)

    pop ix                              ; get pointer to sprite data

    ld a, 16                            ; we need to count 16 rows (two rows of 8 row characters)

render_sprite_tile_loop:
    ex af, af'

    ld d, (ix)                          ; d - tile 0
    inc ix
    ld e, (ix)                          ; e - tile 1
    inc ix
    ld b, 0                             ; b - tile 2

    ld a, c
    cp 0
    jp z, render_sprite_tile_shift_done ; skip if no shifts at all

render_sprite_tile_sh_once:
    srl d                               ; shift right [deb]
    rr e
    rr b
    dec a
    jp nz, render_sprite_tile_sh_once   ; loop C times

render_sprite_tile_shift_done:

    ld (hl), d
    inc hl
    ld (hl), e
    inc hl
    ld (hl), b
    inc hl
    inc hl

    ex af, af'
    dec a
    jp nz, render_sprite_tile_loop      ; loop 8 times

__render_sprite_preshifted:

    ; render_sprite_tile now contains baked pre-shifted tile set
    ; we now need to xor it with "background" of tiles

    pop bc                              ; get xy location

    ; now we have to bake 4x4 onto the buffer
    ld de, render_sprite_buffer

    ; bake 3 rows (3 columns each)
    include "client_graphics_inc/render_sprite_bake_bg_tile_row.inc"
    ld de, render_sprite_buffer + 32
    include "client_graphics_inc/render_sprite_bake_bg_tile_row.inc"
    ld de, render_sprite_buffer + 64
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
