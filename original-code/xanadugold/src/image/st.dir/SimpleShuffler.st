'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:24 pm'!

ByteShuffler subclass: #SimpleShuffler
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!
SimpleShuffler comment:
'shuffle big-endian to little-endian transformation.'!

(SimpleShuffler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SimpleShuffler methodsFor: 'shuffle'!

{void} shuffle16: buffer {void star} with: count {Int32}
	" shuffle alternating bytes. "

	[0 almostTo: count * 2 by: 2 do:
		[:index | | temp {Uint8} | 
		temp _ buffer at: index.
		buffer at: index storeUInt: (buffer at: index + 1).
		buffer at: index + 1 storeUInt: temp]] smalltalkOnly.

	'UInt8 temp;
	UInt8 * base = (UInt8 *) buffer;
	for (Int32 index = 0 ; index < count * 2 ; index += 2)
		{
		temp = base[index];
		base[index] = base[index + 1];
		base[index + 1] = temp;
		}
' translateOnly.!

{void} shuffle32: buffer {void star} with: count {Int32}
	" shuffle alternating words. "
	[0 almostTo: count * 4 by: 4 do:
		[:index | | temp {UInt8} | 
		temp _ buffer at: index.
		buffer at: index storeUInt: (buffer at: index + 3).
		buffer at: index + 3 storeUInt: temp.
		temp _ buffer at: index + 1.
		buffer at: index + 1 storeUInt: (buffer at: index + 2).
		buffer at: index + 2 storeUInt: temp.
		]] smalltalkOnly.

	'UInt8 temp;
	UInt8 * base = (UInt8 *) buffer;
	for (Int32 index = 0 ; index < count * 4; index += 4)
		{
		temp = base[index];
		base[index] = base[index + 3];
		base[index + 3] = temp;
		temp = base[index + 1];
		base[index + 1] = base[index + 2];
		base[index + 2] = temp;
		}' translateOnly.!

{void} shuffle64: buffer {void star} with: count {Int32}
	self unimplemented.! !