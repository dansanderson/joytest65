# joytest65

A joystick and paddle tester for the MEGA65.

This demonstrates how to read joysticks and paddles using assembly language. It displays the raw register values, as well as several common interpretations of these values.

joytest65 is written using the [Acme cross-assembler](https://sourceforge.net/projects/acme-crossass/). It currently doesn't work with [EasyAsm](https://github.com/dansanderson/easyasm65) because it uses macros.

If you are writing a game in BASIC 65, see the [User's Guide](https://files.mega65.org/?id=a5081244-a976-4a21-9153-27cca13fd613) for information about the `JOY()` and `POT()` functions.

## One-button joysticks

A one-button joystick contains five buttons: up, down, left, right, and fire. The joystick is built such that pressing the stick in a diagonal direction presses two buttons simultaneously, such as up and left, for a total of eight possible directions. All five buttons can be read independently by the computer.

Each button connects an assigned joystick port pin to the ground pin. This causes bits 0 through 4 of the CIA data register for the port to go from 1 to 0. The CIA data register for port 1 is $DC01, and the data register for port 2 is $DC00.

| Pin | Function | CIA bit (0=pressed) |
|-----|----------|---------|
| 1 | Up | 0 |
| 2 | Down | 1 |
| 3 | Left | 2 |
| 4 | Right | 3 |
| 6 | Fire | 4 |
| 8 | Ground | - |

For best results, use this procedure:

1. Disable interrupts.
2. Write $FF to $DC00 to disconnect the keyboard.
3. Read the joystick values from $DC01 and $DC00.
4. Write $7F to $DC00 to reconnect the keyboard.
5. Re-enable interrupts.

This avoids conflicts with the KERNAL IRQ handler's use of the CIA to read the keyboard.

## Paddles

A paddle consists of a dial that turns almost a complete rotation, and a single fire button. Each joystick port supports two paddles, and most paddle controllers come in pairs. The computer can report a value for the dial from 0 to 255, though the actual range and how it corresponds to the dial position varies based on the paddle.

The fire button on each paddle is assigned to a pin, and it connects that pin to a ground pin, similar to a joystick button. This causes the corresponding bit of the CIA data register to go from 1 to 0.

Each paddle dial is also assigned to a pin. The dial is a *potentiometer,* an electronic component that connects the pin to the +5V pin with an amount of electronic resistance that corresponds to the position of the dial. The computer detects the amount of resistance on the line, and converts this to a number value between 0 and 255.

| Pin | Function | CIA bit (0=pressed) |
|-----|----------|---------|
| 2 | Paddle A fire | 1 |
| 3 | Paddle B fire | 2 |
| 5 | Paddle A dial (POTX) | - |
| 7 | +5V | - |
| 8 | Ground | - |
| 9 | Paddle B dial (POTY) | - |

To read the paddle fire buttons, use the same procedure as with joysticks.

To read the paddle dials:

1. Select the joystick port by writing to $DC00 bits 6-7: %01000000 for port 1, and %10000000 for port 2.
2. Wait 512 machine cycles at 1 MHz so that the computer can read the resistance value.
3. Read the paddle values. For paddle A, read $D419. For paddle B, read $D41A.
4. Read the paddle values a second time. If the reading differs, go back to step 3. (This "debounces" the signal for a more reliable reading.)

The delay in step 2 is necessary because the computer uses a multi-step electronic procedure to read the dial position. The program can do other things during this delay. It must perform delay the full amount each time the port is selected, as in step 1. To read paddles from both joystick ports in a game loop, the program must perform two delays.

On the MEGA65, if the CPU is running at 40 MHz, the program must take care that the delay is 512 cycles at 1 MHz. It can wait 40 x 512 CPU cycles, or it can down-clock the CPU to 1 MHz (clear the FAST bit $D030.6) and perform a simple 256-count loop, then restore the CPU speed (set the FAST bit).

Note: Paddles designed for Atari game consoles use a different range of resistance values than paddles designed for Commodores. This causes the dial to traverse 0 to 255 in only a partial turn (short "throw," more "sensitive"), and stay at 255 for the rest of the turn (a "dead zone"). Some players consider this an advantage for some games. Some paddles intended for Ataris (especially the Hyperkin Ranger) have a throw distance too short to be usable. Commodore-brand paddles may have differing resistance values, but tend to be more usable for Commodore games.

## Three-button joysticks

The Commodore 64 Game System (C64GS) established a method for a Commodore-compatible game controller to have two or three fire buttons, using a combination of the joystick and paddle pins. Buttons 2 and 3 use the paddle dial pins 5 (POTX) and 9 (POTY), respectively, connected to +5V with a fixed current-limiting resistor when pressed. To the program, buttons 2 and 3 appear to be paddle dials that jump between the maximum value (not pressed) and a lower value (pressed). Though games for three-button controllers for the Commodore are rare, this standard is widely accepted.

To read buttons 2 and 3, use the paddle procedure. This must include the port select and the delay, even though it's a button value being read.

Everything else about a three-button joystick is the same as a one-button joystick, including button 1.

| Pin | Function | CIA bit (0=pressed) |
|-----|----------|---------|
| 1 | Up | 0 |
| 2 | Down | 1 |
| 3 | Left | 2 |
| 4 | Right | 3 |
| 5 | Button 2 (POTX, to +5V) | - |
| 6 | Button 1 | 4 |
| 7 | +5V | - |
| 8 | Ground | - |
| 9 | Button 3 (POTY, to +5V) | - |

## Five-button joysticks

[5plusbuttonsJoystick](https://github.com/crystalct/5plusbuttonsJoystick) by crystalct defines a protocol for a game controller with up to five buttons. Buttons 1, 2, and 3 are as with the three-button protocol. Button 4 triggers "up" and "down" simultaneously, and button 5 triggers "left" and "right" simultaneously. This takes advantage of the fact that joysticks and directional pads cannot activate these opposing directions simultaneously on their own.

This protocol has the disadvantage that buttons 4 and 5 cannot reliably be used simultaneously with the joystick or directional pad. These are mostly useful for menu buttons, such as the Nintendo-style Start and Select buttons, which aren't pressed simultaneously with a direction.

To read buttons 4 and 5, detect the up+down or left+right signal combinations with the CIA data register, as above.

## Building joytest65

To build joytest65, use Acme assembler:

```
acme joytest65.asm
```

## TODO

* Add support for the [MEGA65 4-player joystick adapter](https://www.bit-zeal.com/product/4PlayerMEGA65/6).
* Enable the mouse pointer, or otherwise visualize how mouse movement uses the paddle registers. (Cf. [Joyride](https://github.com/T-Pau/Joyride?tab=readme-ov-file).)
