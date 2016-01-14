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
| 0x00   |
| get firmware version command |

#### RX
|         |                     |
|---------|---------------------|
| 0xAA    | 0bHHHHLLLL          |
| OK-byte | H-4 high-bits, L-4 low-bits, eg. 0b10000100 = version 8.4 |

## EEPROM
Device ID: 0b0001
### read

#### TX
|              |            |            |
|--------------|------------|------------|
| 0x10   | 0bxxxxxxxA | 0bAAAAAAAA |
| read command | x-don't care, A-address MSB  | A-address  |

#### RX
|         |                     |
|---------|---------------------|
| 0xAA    | 0bDDDDDDDD          |
| OK-byte | D-byte at address A |

### read 16bit

#### TX
|         |                     |
|---------|---------------------|
| 0x17    | 0bAAAAAAAA          |
| read 16bit command | A-address |

#### RX
|              |            |            |
|--------------|------------|------------|
| 0xAA   | 0bDDDDDDDD | 0bdddddddd |
| OK-byte | D-byte at address A  | d-byte at address A+1  |

### write
* must be handled with care: only 1 000 000 cycles endurance (should only be called by user, not automatically)

#### TX
|              |            |            |          |
|--------------|------------|------------|----------|
| 0x11         | 0bxxxxxxxA | 0bAAAAAAAA |0bDDDDDDDD|
| write command | x-don't care, A-address MSB | A-address  | D-byte   |

#### RX
|         |         |
|---------|---------|
| 0xAA    | 0xBB    |
| OK-byte | Done-byte |

### write 16bit
* must be handled with care: only 1 000 000 cycles endurance (should only be called by user, not automatically)

#### TX
|              |            |            |          |
|--------------|------------|------------|----------|
| 0x18         | 0bAAAAAAAA | 0bDDDDDDDD | 0bdddddddd |
| write 16bit command | A-address | D-byte  | d-byte for address A+1   |

#### RX
|         |         |
|---------|---------|
| 0xAA    | 0xBB    |
| OK-byte | Done-byte |

### erase all
* erases complete memory (all bits set to 1)
* must be handled with care: only 1 000 000 cycles endurance (should only be called by user, not automatically)

#### TX
|              |
|--------------|
| 0x12   |
| erase all command |

#### RX
|         |         |
|---------|---------|
| 0xAA    | 0xBB    |
| OK-byte | Done-byte |