#include "sound.h"

#define FB_WIDTH 640
#define FB_HEIGHT 480
#define NUM_CORES 6

#define REG_LEDS (*(volatile uint32_t *)0x80000000)
#define REG_PS2_KBD (*(volatile uint32_t *)0x80000004)
#define REG_CORE_ID (*(volatile uint32_t *)0x80000010)
#define FRAMEBUFFER ((volatile uint16_t *)0x00000000)

#define COLOR_BLACK 0x0000
#define COLOR_WHITE 0xFFFF

static inline uint16_t make_rgb565(uint8_t r, uint8_t g, uint8_t b)
{
    return ((r & 0x1F) << 11) | ((g & 0x3F) << 5) | (b & 0x1F);
}

void render_slice(uint32_t core_id, uint32_t frame, uint8_t key)
{
    uint32_t slice_h = FB_HEIGHT / NUM_CORES;
    uint32_t y_start = core_id * slice_h;
    uint32_t y_end = y_start + slice_h;

    for (uint32_t y = y_start; y < y_end; y++)
    {
        uint32_t offset = y * FB_WIDTH;
        for (uint32_t x = 0; x < FB_WIDTH; x++)
        {
            uint8_t r = (x + frame + (core_id * 8)) & 0x1F;
            uint8_t g = (y + (frame >> 1) + key) & 0x3F;
            uint8_t b = (x ^ y ^ (core_id * 4)) & 0x1F;

            if (x == (FB_WIDTH / 2) || y == (FB_HEIGHT / 2))
            {
                FRAMEBUFFER[offset + x] = COLOR_WHITE;
            }
            else
            {
                FRAMEBUFFER[offset + x] = make_rgb565(r, g, b);
            }
        }
    }
}

void main(void)
{
    uint32_t core_id = REG_CORE_ID;
    uint32_t frame = 0;
    uint8_t key = 0;

    if (core_id == 0)
    {
        REG_LEDS = 0x3F;
        sound_init();
        bib_intro(); // Begruessungs-Riff
    }

    while (1)
    {
        if (core_id == 0)
        {
            uint32_t ps2 = REG_PS2_KBD;
            if (ps2 & 0x0100)
            { // Neuer Tastendruck
                key = (uint8_t)(ps2 & 0xFF);
                REG_LEDS = (uint32_t)(~key & 0x3F);

                // PS/2 Tastatur Scancodes: Zifferntasten 1 bis 4
                if (key == 0x16)
                    bib_intro(); // Taste '1'
                else if (key == 0x1E)
                    doom_intro(); // Taste '2'
                else if (key == 0x26)
                    starwars_intro(); // Taste '3'
                else if (key == 0x25)
                    money_intro(); // Taste '4'
            }
        }

        render_slice(core_id, frame, key);
        frame++;

        for (volatile int d = 0; d < 1500; d++)
            ;
    }
}