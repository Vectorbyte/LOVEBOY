/*
======================
    graphics.h
======================
*/
// All data is stored in littl-endian format
struct gfxheader_t
{
    // Magic and Palette
    uint32_t magic;
    uint16_t palette[64];
    
    // Offsets and counts
    uint16_t ofs_tile, ofs_sprite, ofs_animation;
    uint16_t num_tile, num_sprite, num_animation;
};

// 8x8 tile data
struct tile_t
{
    uint8_t color[4], data[16];
};

// Sprite index, indexes tiles
struct sprite_t
{
    uint8_t name[4], width, height; // Sprite name with width and height in tiles
    uint16_t offset;                // Tile offset
};

// Animation index, indexes sprites
struct animation_t
{
    uint8_t name[4], sprite[4]; // Animation and first frame name
    uint16_t frames;            // Frame count
};