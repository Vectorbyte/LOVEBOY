/*
======================
    graphics.h
======================
*/

// All data is stored in littl-endian format
struct gfxheader_t
{
    // Magic
    uint32_t magic;
    
    // Palette
    uint16_t palette[256];
    
    // Offsets
    uint16_t ofs_tile;
    uint16_t ofs_sprite;
    uint16_t ofs_animation;
    
    // Counts
    uint16_t num_tile;
    uint16_t num_sprite;
    uint16_t num_animation;
};

// 8x8 tile data
struct tile_t
{
    uint8_t color[4];
    uint8_t data[16];
};

// Sprite index, indexes tiles
struct sprite_t
{
    // Sprite name
    uint8_t name[4];
    
    // Sprite width and height in tiles
    uint8_t width;
    uint8_t height;
    
    // Tile offset
    uint16_t offset;
};

// Animation index, indexes sprites
struct animation_t
{
    // Animation name
    uint8_t name[4];
    
    // Frame offset and count
    uint16_t offset;
    uint16_t frames;
};