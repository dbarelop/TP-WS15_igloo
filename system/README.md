# Firmware working parts / protocol
Path to flash-file:

igloo/system/teamprojekt/designer/impl2/top.pdb

Config:
* 9600 Baudrate
* 8 data bits
* 1 stop bit
* no parity
* no handshake

## Master
Device ID: 0b0000
### get firmware version
* can be used for connection pinging
* better distinction between firmware versions

#### TX
|              |
|--------------|
| 0b00000000   |
| get firmware version command |

#### RX
|         |                     |
|---------|---------------------|
| 0xAA    | 0bHHHHLLLL          |
| OK-byte | H-4 high-bits, L-4 low-bits, eg. 0b10000100 = version 8.4 |

## EEPROM
Device ID: 0b0001
### read
* 8 bit reading only so far

#### TX
|              |            |            |
|--------------|------------|------------|
| 0b00010000   | 0bxxxxxxxA | 0bAAAAAAAA |
| read command | x-don't care, A-address MSB  | A-address  |

#### RX
|         |                     |
|---------|---------------------|
| 0xAA    | 0bDDDDDDDD          |
| OK-byte | D-byte at address A |

### write
* 8 bit writing only so far
* finished message missing!!! (OK-byte is send before writing is finished!)

#### TX
|              |            |            |          |
|--------------|------------|------------|----------|
| 0b00010001   | 0bxxxxxxxA | 0bAAAAAAAA |0bDDDDDDDD|
| write command | x-don't care, A-address MSB | A-address  | D-byte   |

#### RX
|         |
|---------|
| 0xAA    |
| OK-byte |

### erase all
* erases complete memory (all bits set to 1)
* must be handled with care: only 1 000 000 cycles endurance (should only be called by user, not automatically)
* finished message missing!!! (OK-byte is send before erasing is finished!)

#### TX
|              |
|--------------|
| 0b00010010   |
| erase all command |

#### RX
|         |
|---------|
| 0xAA    |
| OK-byte |