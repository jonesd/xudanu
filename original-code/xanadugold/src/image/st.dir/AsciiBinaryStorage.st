'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:48 pm'!

BinaryStorage subclass: #AsciiBinaryStorage
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Binary Storage'!
AsciiBinaryStorage comment:
'The class AsciiBinaryStorage implements an alternative BinaryStorage encoding, an ASCII representation more convenient for debugging.'!


!AsciiBinaryStorage methodsFor: 'initialize-release'!

on: aStream
	" Don't set to binary. "
	stream _ aStream.
	self initialize! !

!AsciiBinaryStorage methodsFor: 'private: private-encoding'!

encodeBytes: bytes
	" Append the bytes to the output. "

	bytes do: [:b | stream nextPut: (Character value: b)]!

encodeOpByte: byte
	stream
		nextPut: $<; print: (byte bitShift: OpcodeShift negated);
		nextPut: $,; print: (byte bitAnd: OperandMask);
		nextPut: $>!

encodeString: aByteString
	" Append the characters of
	aByteString to the output. "
	stream nextPutAll: aByteString! !

!AsciiBinaryStorage methodsFor: 'private: private-decoding'!

decodeBytes: bytesClass size: size
	| bytes |
	bytes _ bytesClass new: size.
	1 to: bytes size do: [:i | bytes at: i put: stream next asInteger].
	^bytes!

decodeOpByte
	" Answer the next opcode/operand
	byte from the stream. "
	| op int |
	stream next = $< ifFalse: [self error: 'expected <'.  ^-1].
	op _ Integer readFrom: stream.
	stream next = $, ifFalse: [self error: 'expected ,'.  ^-1].
	int _ Integer readFrom: stream.
	stream next = $> ifFalse: [self error: 'expected >'.  ^-1].
	^(op bitShift: OpcodeShift) + int!

decodeString: size
	" Read and answer a String
	of the given size. "

	^stream next: size! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AsciiBinaryStorage class
	instanceVariableNames: ''!


!AsciiBinaryStorage class methodsFor: 'private: private'!

streamContentsClass
	^String! !