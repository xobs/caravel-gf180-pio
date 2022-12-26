/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
#include <defs.h>
#include <stub.c>

#define PIO_BASE 0x30000000

#include <stdint.h>
static inline void pio_writeb(uint8_t value, uint32_t addr)
{
        *((volatile uint8_t *)(addr + PIO_BASE)) = value;
}

static inline uint8_t pio_readb(uint32_t addr)
{
        return *(volatile uint8_t *)(addr + PIO_BASE);
}

static inline void pio_writew(uint16_t value, uint32_t addr)
{
        *((volatile uint16_t *)(addr + PIO_BASE)) = value;
}

static inline uint16_t pio_readw(uint32_t addr)
{
        return *(volatile uint16_t *)(addr + PIO_BASE);
}

static inline void pio_writel(uint32_t value, uint32_t addr)
{
        *((volatile uint32_t *)(addr + PIO_BASE)) = value;
}

static inline uint32_t pio_readl(uint32_t addr)
{
        return *(volatile uint32_t *)(addr + PIO_BASE);
}

struct config {
    uint8_t offset;
    uint32_t value;
};

uint32_t pwm_program[] = {
    0x9080,
    0xa027,
    0xa046,
    0x00a5,
    0x1806,
    0xa042,
    0x0083,
};

struct config pwm_config[] = {
    {.offset = 2, .value = 0x40006000}, // Set wrap
    {.offset = 7, .value = 0x00000280}, // Set divider to get 10MHz frequency
    {.offset = 5, .value = 0x40000000}, // Set side pin group to pin 0
    {.offset = 4, .value = 0x00000010}, // Set period to 16
    {.offset = 0, .value = 0x00000010}, // Maintain din for extra clock cycle
    {.offset = 9, .value = 0x00008080}, // Execute pull
    {.offset = 0, .value = 0x00008080}, // Maintain din
    {.offset = 9, .value = 0x0000a0c7}, // Execute  mov isr, osr
    {.offset = 0, .value = 0x0000a0c7}, // Maintain din
    {.offset = 6, .value = 0x00000001}, // Enable machine 1
};

uint32_t square_program[] = {
    0xe001,
    0xe000,
};

struct config square_config[] = {
    {.offset = 2, .value = 0x00001000}, // Set wrap
    // {.offset = 7, .value = 0x00000C80}, // Set divider
    {.offset = 7, .value = 0x00000001}, // Set divider
    {.offset = 5, .value = 0x04000000}, // Set pin groups, SET pin 0
    {.offset = 6, .value = 0x00000001}, // Enable machine 1

    {.offset = 2 + 16, .value = 0x00001000}, // Set wrap
    {.offset = 7 + 16, .value = 0x00000001}, // Set divider
    {.offset = 5 + 16, .value = 0x04000081}, // Set machine 2 to have an OUT offset of 1
    {.offset = 6, .value = 0x00000003}, // Enable machine 1 and 2

    {.offset = 2 + 32, .value = 0x00001000}, // Set wrap
    {.offset = 7 + 32, .value = 0x00000004}, // Set divider
    {.offset = 5 + 32, .value = 0x04000081}, // Set machine 2 to have an OUT offset of 1
    {.offset = 6, .value = 0x00000007}, // Enable machine 1 and 2
};

/*
	Wishbone Test:
		- Configures MPRJ lower 8-IO pins as outputs
		- Checks counter value through the wishbone port
*/

void main()
{

	/* 
	IO Control Registers
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 3-bits | 1-bit | 1-bit | 1-bit  | 1-bit  | 1-bit | 1-bit   | 1-bit   | 1-bit | 1-bit | 1-bit   |
	Output: 0000_0110_0000_1110  (0x1808) = GPIO_MODE_USER_STD_OUTPUT
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 110    | 0     | 0     | 0      | 0      | 0     | 0       | 1       | 0     | 0     | 0       |
	
	 
	Input: 0000_0001_0000_1111 (0x0402) = GPIO_MODE_USER_STD_INPUT_NOPULL
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 001    | 0     | 0     | 0      | 0      | 0     | 0       | 0       | 0     | 1     | 0       |
	*/

	/* Set up the housekeeping SPI to be connected internally so	*/
	/* that external pin changes don't affect it.			*/

    reg_spi_enable = 1;
    reg_wb_enable = 1;
	// reg_spimaster_config = 0xa002;	// Enable, prescaler = 2,
                                        // connect to housekeeping SPI

    // These pins are unused
    reg_mprj_io_0 = GPIO_MODE_MGMT_STD_BIDIRECTIONAL;
    reg_mprj_io_1 = GPIO_MODE_MGMT_STD_BIDIRECTIONAL;
    reg_mprj_io_2 = GPIO_MODE_MGMT_STD_BIDIRECTIONAL;
    reg_mprj_io_3 = GPIO_MODE_MGMT_STD_BIDIRECTIONAL;
    reg_mprj_io_4 = GPIO_MODE_MGMT_STD_BIDIRECTIONAL;

    // Connect these pins up to the design so that the PIO block
    // can drive them.
    reg_mprj_io_5 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_6 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_7 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_8 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_9 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_10 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_11 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_12 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_13 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_14 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_15 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    //
    reg_mprj_io_32 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_33 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_34 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_35 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_36 = GPIO_MODE_USER_STD_BIDIRECTIONAL;

    // This pin is unused
    reg_mprj_io_37 = GPIO_MODE_USER_STD_BIDIRECTIONAL;

    // Set these pins up as management mode. This is used by the reg_mprj_datal commands
    // in order to send status out the output pins in order for the test harness to
    // know when the test has finished.
    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

     /* Apply configuration */
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

	reg_la2_oenb = reg_la2_iena = 0x00000000;    // [95:64]

    // Flag start of the test
    reg_mprj_datal = 0xA0000000;

    // Write NONE
    pio_writel(0x1234abcd, 0);

    // Read VERSION
    (void)pio_readl(0);

    // Initiate a manual reset
    pio_writel(0x80000000, 0);

    // Write PWM program
    unsigned int i;
    for (i = 0; i < sizeof(square_program) / sizeof(*square_program); i++) {
        pio_writel(square_program[i], 4);
    }

    // Write PWM config
    for (i = 0; i < sizeof(square_config) / sizeof(*square_config); i++) {
        pio_writel(square_config[i].value, square_config[i].offset * 4);
    }

    for (i = 0; i < 50; i++) {
        asm("");
    }

    // End test
    reg_mprj_datal = 0xab000000;

    while (1) {}
}
