#include "sound.h"

#define REG_SOUND (*(volatile uint32_t *)0x80000008)

// -------------------------------------------------------------
// Back in Black (Divider fuer 40.5 MHz / 32 / Frequenz)
// -------------------------------------------------------------
static const uint16_t bib_noten[] = {
    // Takt 1
    7670, 0, 8610, 8610, 8610, 0, 5753, 5753, 5753, 0,
    3835, 4305, 5124, 5753, 6457, 7670, 0,
    // Takt 2
    7670, 0, 8610, 8610, 8610, 0, 5753, 5753, 5753, 0,
    5753, 0, 5432, 0, 5124, 0, 7670};

static const uint16_t bib_zeit[] = {
    260, 180, 140, 140, 180, 180, 140, 140, 180, 220,
    110, 110, 110, 110, 180, 300, 250,
    260, 180, 140, 140, 180, 180, 140, 140, 180, 220,
    130, 40, 130, 40, 130, 40, 450};

// -------------------------------------------------------------
// Doom E1M1 / At Doom's Gate
// -------------------------------------------------------------
static const uint16_t dm_noten[] = {
    15434, 15434, 7670, 15434, 15434, 8610, 15434, 15434, 9105, 15434, 15434, 9661, 0,
    15434, 15434, 7670, 15434, 15434, 8610, 15434, 15434, 9105, 15434, 15434, 8113, 8610};

static const uint16_t dm_zeit[] = {
    90, 90, 140, 90, 90, 140, 90, 90, 140, 90, 90, 180, 60,
    90, 90, 140, 90, 90, 140, 90, 90, 140, 90, 90, 180, 250};

// -------------------------------------------------------------
// Star Wars Main Theme
// -------------------------------------------------------------
static const uint16_t sw_noten[] = {
    2876, 2876, 2876, 3626, 2420, 2876, 3626, 2420, 2876, 0,
    1920, 1920, 1920, 1813, 2420, 3050, 3626, 2420, 2876, 0};

static const uint16_t sw_zeit[] = {
    350, 350, 350, 250, 120, 350, 250, 120, 650, 150,
    350, 350, 350, 250, 120, 350, 250, 120, 750, 200};

// -------------------------------------------------------------
// Dire Straits: Money for Nothing
// -------------------------------------------------------------
static const uint16_t mn_noten[] = {
    6457, 0, 5753, 5124, 5753, 6457, 5753, 0,
    4305, 4305, 5124, 0, 5753, 0, 6457, 7670,
    6457, 5753, 6457, 0, 5124, 5753, 6457, 7670};

static const uint16_t mn_zeit[] = {
    180, 50, 180, 180, 180, 180, 240, 80,
    220, 180, 280, 80, 220, 60, 180, 180,
    180, 180, 280, 80, 180, 180, 220, 400};

static void delay_ms(uint32_t ms)
{
    for (volatile uint32_t i = 0; i < ms * 9000UL; i++)
        ;
}

static void play_track(const uint16_t *notes, const uint16_t *durations, uint8_t count)
{
    for (uint8_t i = 0; i < count; i++)
    {
        uint16_t div = notes[i];
        uint16_t d = durations[i];

        if (div > 0)
        {
            REG_SOUND = (1 << 16) | div;
        }
        else
        {
            REG_SOUND = 0;
        }

        delay_ms(d);
        REG_SOUND = 0;
        delay_ms(25);
    }
    REG_SOUND = 0;
}

void sound_init(void)
{
    REG_SOUND = 0;
}

void bib_intro(void)
{
    play_track(bib_noten, bib_zeit, sizeof(bib_noten) / sizeof(bib_noten[0]));
}

void doom_intro(void)
{
    play_track(dm_noten, dm_zeit, sizeof(dm_noten) / sizeof(dm_noten[0]));
}

void starwars_intro(void)
{
    play_track(sw_noten, sw_zeit, sizeof(sw_noten) / sizeof(sw_noten[0]));
}

void money_intro(void)
{
    play_track(mn_noten, mn_zeit, sizeof(mn_noten) / sizeof(mn_noten[0]));
}