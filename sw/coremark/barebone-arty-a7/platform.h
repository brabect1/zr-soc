/*
Copyright 2019 Tomas Brabec

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Compiled from code in https://github.com/SI-RISCV/e200_opensource
*/

#ifndef PLATFORM_H
#define PLATFORM_H

#ifdef __ASSEMBLER__
#define _AC(X,Y)        X
#define _AT(T,X)        X
#else
#define _AC(X,Y)        (X##Y)
#define _AT(T,X)        ((T)(X))
#endif /* !__ASSEMBLER__*/

#define IOF0_UART0_MASK         _AC(0x00030000, UL)
#define IOF_UART0_RX   (16u)
#define IOF_UART0_TX (17u)

#define GPIO_CTRL_ADDR _AC(0x10012000,UL)
#define UART0_CTRL_ADDR _AC(0x10013000,UL)

// E300 UART Register offsets
#define UART_REG_TXFIFO         0x00
#define UART_REG_RXFIFO         0x04
#define UART_REG_TXCTRL         0x08
#define UART_REG_RXCTRL         0x0c
#define UART_REG_IE             0x10
#define UART_REG_IP             0x14
#define UART_REG_DIV            0x18

// E300 UART masks and setting values
#define UART_TXEN 0x1
#define UART_RXEN 0x1

// E300 GPIO Register offsets
#define GPIO_INPUT_VAL  (0x00)
#define GPIO_INPUT_EN   (0x04)
#define GPIO_OUTPUT_EN  (0x08)
#define GPIO_OUTPUT_VAL (0x0C)
#define GPIO_PULLUP_EN  (0x10)
#define GPIO_DRIVE      (0x14)
#define GPIO_RISE_IE    (0x18)
#define GPIO_RISE_IP    (0x1C)
#define GPIO_FALL_IE    (0x20)
#define GPIO_FALL_IP    (0x24)
#define GPIO_HIGH_IE    (0x28)
#define GPIO_HIGH_IP    (0x2C)
#define GPIO_LOW_IE     (0x30)
#define GPIO_LOW_IP     (0x34)
#define GPIO_IOF_EN     (0x38)
#define GPIO_IOF_SEL    (0x3C)
#define GPIO_OUTPUT_XOR (0x40)

#define _REG32(p, i) (*(volatile ee_u32 *) ((p) + (i)))

#define UART0_REG(offset) _REG32(UART0_CTRL_ADDR, offset)
#define GPIO_REG(offset)  _REG32(GPIO_CTRL_ADDR, offset)

#endif /* PLATFORM_H */
