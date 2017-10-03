# ws2812-i2s library

This a library to be used in firmware for the ESP8266.

## What is this

This library is a I2S Interface to drive WS2811/WS2812 and SK6812 LED strips.
The code is lifted out of the [esp-open-rtos](https://github.com/SuperHouse/esp-open-rtos) project and
has been modified to work with SK6812 LEDs and compile with the original Espressif RTOS SDK.

The communication with the LEDs is over I2S and uses DMA to offload timing critical stuff off the CPU.
You will need a framebuffer (8bit per color) for each of your LEDs and the library internally needs
DMA buffers which are 4 bytes per LED per color.

The I2S pin is shared with UART0 RxD so you will not be able to send anything to the ESP over serial anymore.

## API

### Hardware selection

To select which type of LED you want to connect to your ESP module you may have to edit the Makefile:

```make
CFLAGS      += -DLED_TYPE=LED_TYPE_WS2812 -DLED_MODE=LED_MODE_RGB
```

#### LED_TYPE

There are two possible values for `LED_TYPE`:

- `LED_TYPE_WS2812` use this one for WS2811 or WS2812 LEDs
- `LED_TYPE_SK6812` use this one for the SK6812 types (mostly used by RGBW strips)

#### LED_MODE

This setting defines how many color components are in your LEDs

- `LED_MODE_RGB` this is the usual default, 3 colors. They are sent in GRB order.
- `LED_MODE_RGBW` use this if your LEDs have 4 color components, like the RGBW strips
  with a dedicated white LED in addition to the red, green and blue ones.

### C API

```c
void ws2812_i2s_init(uint32_t pixels_number);
```

Call this one with the pixel count before starting to send out data. This will initalize
all needed buffers and set the IOMUX for GPIO 3 from the default UART0 RxD to I2S.

```c
void ws2812_i2s_update(ws2812_pixel_t *pixels);
```

Update the LED strip with new pixel data. The library assumes the number of pixels in this
array are the same as with the init call.

One pixel looks like this:

```c
typedef struct {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
#if LED_MODE == LED_MODE_RGBW
    uint8_t white;
#endif
} ws2812_pixel_t;
```

so as you can see the `white` component is only available when configured for a RGBW strip.

## Usage instructions

This library is built with the [esp8266-setup](http://github.com/esp8266-setup/esp8266-setup) tool in mind.

If you are already using the `esp8266-setup` build system just issue the following command in your project dir:

```bash
esp8266-setup add-library git+https://github.com/esp8266-setup/ws2812_i2s.git@master
```

If you do not want to use the `esp8266-setup` build system just grab the files from the `src` and `include` directories and add them to your project.

Be aware that most libraries built with this build system use the `C99` standard, so you may have to add `--std=c99` to your `CFLAGS`.

## Build instructions

- Install the ESP8266 Toolchain
- Download the ESP8266 RTOS SDK
- Compile the library: 
```bash
    make \
      XTENSA_TOOLS_ROOT=/path/to/compiler/bin \
      SDK_PATH=/path/to/ESP8266_RTOS_SDK
```

- The finished library will be placed in the current directory under the name
  of `libws2812-i2s.a`
- Corresponding include files are in `include/`

If you installed the ESP SDK and toolchain to a default location (see below) you may just type `make` to build.

### Default locations

#### Windows

- **XTENSA\_TOOLS\_ROOT**: `c:\ESP8266\xtensa-lx106-elf\bin`
- **SDK_PATH**: `c:\ESP8266\ESP8266_RTOS_SDK`

#### MacOS X

We assume that your default file system is not case sensitive so you will have created a sparse bundle with a case sensitive filesystem which is named `ESP8266`:

- **XTENSA\_TOOLS\_ROOT**: `/Volumes/ESP8266/esp-open-sdk/xtensa-lx106-elf/bin`
- **SDK_PATH**: `/Volumes/ESP8266/ESP8266_RTOS_SDK`

#### Linux

- **XTENSA\_TOOLS\_ROOT**: `/opt/Espressif/crosstool-NG/builds/xtensa-lx106-elf/bin`
- **SDK_PATH**: `/opt/Espressif/ESP8266_RTOS_SDK`
