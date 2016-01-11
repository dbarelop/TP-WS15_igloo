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
* highest (9th) bit of internal addressing in eeprom always 0, addresses 0b0 00000000 to 0b0 11111111 accessable, has to be fixed

#### TX
|              |            |
|--------------|------------|
| 0b00010000   | 0bAAAAAAAA |
| read command | A-address  |

#### RX
|         |                     |
|---------|---------------------|
| 0xAA    | 0bDDDDDDDD          |
| OK-byte | D-byte at address A |

### write
* 8 bit writing only so far
* highest (9th) bit of internal addressing in eeprom always 0, addresses 0b0 00000000 to 0b0 11111111 accessable, has to be fixed
* finished message missing!!! (OK-byte is send before writing is finished!)

#### TX
|              |            |          |
|--------------|------------|----------|
| 0b00010001   | 0bAAAAAAAA |0bDDDDDDDD|
| write command | A-address  | D-byte   |

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

## AD Converter
Device ID: 0b0010

### read
* Reads all 24 bit seperated in three Bytes (from lowes to highest velued Byte(bit)).
* The 24 bit value is Signed!
* Highest bit '1': Indicates a zero or positive full-scale voltage.
* Highest bit '0': Indicates a negative full-scale voltage.

#### TX
|  	|
|-----|
|0x20|
|read command|

#### RX
|	 |   |
|---|---|
|0xAA|3x 0xD|
|OK-byte|3 Data Bytes|

### CH1
* Set the Chanal for the next AD Conversion on CH1.
* Dont sends any OK Message untill now...

#### TX
|   |
|---|
|0x23|
|chanel select command|

### CH2
* Set the Chanal for the next AD Conversion on CH2.
* Dont sends any OK Message untill now...

#### TX
|   |
|---|
|0x24|
|chanel select command|

### RNG1
* Set the range for the next AD Conversion on +- 2.56V
* Dont sends any OK Message untill now...

#### TX
|   |
|---|
|0x25|
|range select command|

### RNG2
* Set the range for the next AD Conversion on +- 0.16V
* Dont sends any OK Message untill now...

#### TX
|   |
|---|
|0x26|
|range select command|