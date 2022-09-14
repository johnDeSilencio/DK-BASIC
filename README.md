# BDASIC - Bongo Drums Application Specific Integrated Circuit

The world's first hardware accelerated Donkey Kong Bongo Drums - PS2 Keyboard adapter

---

Have you ever felt like assembly was too abstract? Do you believe that there's no such thing as "too close" to the metal? Have you ever fantasized about programming in raw voltage? If so, a binary keyboard is right for you!

Calling all operating system developers: using your Donkey Kong Jungle Beat bongos and this chip, you can start writing raw x86 instructions in your favorite text editor to feel what the system is really doing.

Are you learning a network protocol, but can't seem to keep track of all the bit fields? Look no further than your Donkey Kong Jungle Beat bongo keyboard. Write a packet bit-for-bit in a profoundly tactile way and engage both your body and your mind.

The Donkey Kong Jungle Beat bongos have been a passion of mine for over a year now. It all started with a question and a joke between my housemates: what makes a programmer a real programmer? The truth is, we surmised, that a program is just a very specific ordering of ones and zeros. A real programmer truly only needs two things to write software: a one and a zero. And so was born the binary keyboard, made possible by Nintendo's obscure controller.

In all seriousness, I have found this hobby project to be an incredible tool for learning binary, hexadecimal, and becoming familiar with machine code. There have been hurdles, however.

The Donkey Kong Jungle Beat bongos utilize a Nintendo GameCube controller pinout. To interface with a computer, fellow bongo enthusiasts are forced to purchase an adapter, usually to USB. While there is software to read the USB input and bind it to certain actions or keys, it is often clunky and not compatible with all operating systems. When I first started playing around with the bongos, I opted to handle reading inputs in software and to use a custom text editor I wrote. I could not use the bongos in any other program, however.

This ASIC converts the serial input of the Donkey Kong Jungle Beat bongos to a PS2 output. By using a hardware adapter, the bongos become like any PS2 keyboard (albeit limited to a handful of pre-chosen characters), agnostic to both the software and the operating system within which the hobbyist uses them. A hardware adapter frees the hobbyist to use the bongos in ways and applications which were not possible before.

With this ASIC, I hope to make more accessible to the world the learning tool and hilarious gag that has been dear to my heart for so long now.

