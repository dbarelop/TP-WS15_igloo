-- lesen mit startadresse mit bytes
-- schreiben 
-- adress leitung
-- daten leitung
-- busy
-- ready


-- addresse 7 oder 8 bit (8 oder 9?)
-- kommando (lesen, schreiben, löschen)
-- daten 


-- eeprom schreiben, 8 byte
-- 8 mal schreiben,
-- we need a buffer limit
-- wenn controller buffer geleert hat, ready message an pc client
-- controller sagt nur lesen, schreiben, löschen



CMD

IF CMD = READ THEN
	
	
ELSIF CMD = WRITE THEN

ELSIF CMD = ERASE THEN

END IF;