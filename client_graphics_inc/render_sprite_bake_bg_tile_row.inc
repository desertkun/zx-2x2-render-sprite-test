    call render_sprite_bake_bg_tile     ; bake column 0
    inc c
    inc de

    call render_sprite_bake_bg_tile     ; bake column 1
    inc c
    inc de

    call render_sprite_bake_bg_tile     ; bake column 2
    inc c
    inc de

    call render_sprite_bake_bg_tile     ; bake column 3
    inc b                               ; wind y
    dec c                               ; unwind x
    dec c
    dec c