'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:07 pm'!

SpecialistRcvr subclass: #Binary2Rcvr
	instanceVariableNames: '
		myStream {XnReadStream}
		myDepth {IntegerVar}'
	classVariableNames: 'SomeRcvrs {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(Binary2Rcvr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!Binary2Rcvr methodsFor: 'receiving'!

{BooleanVar} receiveBooleanVar
	| result {BooleanVar} |
	self startThing.
	result _ myStream getByte.
	self endThing.
	result == 1 ifTrue: [^true] ifFalse: [result == Int0 ifTrue: [^false] ifFalse: [Heaper BLAST: #InvalidRequest]].
	^false "fodder"!

{Category | NULL} receiveCategory

	| num {IntegerVar} |
	num _ self getIntegerVar.
	num == IntegerVar0
		ifTrue:
			[myDepth _ myDepth - 1.
			self endThing.
			^NULL]
		ifFalse: [^self specialist getCategoryFor: num-1]!

{void} receiveData: array {UInt8Array}
	"Fill the array with data from the stream."
	
	self startThing.
	Int32Zero to: array count - 1 do: [ :i {Int32} |
		array at: i storeUInt: myStream getByte].
	self endThing!

{IEEEDoubleVar} receiveIEEEDoubleVar
	"| result {IEEEDoubleVar} |
	self startThing.
	result _ Double make: self getIntegerVar with: self getIntegerVar.
	self endThing.
	^result"
	
	self unimplemented.
	^NULL!

{Int32} receiveInt32 
	| result {Int32} |
	self startThing.
	result _ self getIntegerVar DOTasLong.
	self endThing.
	^result!

{Int8} receiveInt8
	| result {Int8} | 
	self startThing.
	result _ myStream getByte.
	[result > 127 ifTrue: [result _ result - 256]] smalltalkOnly.
	self endThing.
	^result!

{IntegerVar} receiveIntegerVar
	| result {IntegerVar} |
	self startThing. 
	result _ self getIntegerVar.
	self endThing.
	^result!

{char star} receiveString
	| size {Int32} result {char star} |
	size _ self getIntegerVar DOTasLong.
	self startThing.
	[result _ String streamContents: [ :stream |
		1 to: size do: [:ignore {IntegerVar} |
			stream nextPut: (Character char: myStream getByte)]]] smalltalkOnly.
	'
	result = new char[size+1];
	char c;
	for (int soFar = 0; soFar < size ; soFar++) {
		c = myStream->getByte();
		result[soFar] = c;
	}
	result[soFar] = ''\0'';' translateOnly.

	self endThing.
	^result!

{UInt32} receiveUInt32
	| result {UInt32} | 
	self startThing.
	result _ self getIntegerVar DOTasLong.
	self endThing.
	^result!

{UInt8} receiveUInt8
	| result {UInt8} | 
	self startThing.
	result _ myStream getByte.
	self endThing.
	^result! !

!Binary2Rcvr methodsFor: 'protected: specialist'!

{void} endOfInstance
	myDepth _ myDepth - 1.
	self endThing!

{void} endPacket
	myStream getByte == $!! uint8 assert: 'End of packet marker required'.
	myStream getByte == $!! uint8 assert: 'End of packet marker required'.
	super endPacket!

{Category | NULL} fetchStartOfInstance

	self startThing.
	myDepth _ myDepth + 1.
	^self receiveCategory!

{IntegerVar} getIntegerVar
	"A new representation that requires less shifting (eventually)."
"
7/1 		0<7>
14/2	10<6>		<8>
21/3	110<5>		<16>
28/4	1110<4>		<24>
35/5	11110<3>	<32>
42/6	111110<2>	<40>
49/7	1111110<1>	<48>
56/8	11111110 	<56>
?/?	11111111  <humber count>
"
	| byte {UInt8} stream {XnReadStream wimpy} mask {UInt8} count {Int32} num {Int32} |
	"count is bytes following first word or -1 if bignum meaning next byte is humber for actual count"
	stream _ self stream.
	byte _  stream getByte.
	byte <= 2r00111111 ifTrue: [^byte]. 
	byte <= 2r01111111 ifTrue: [^byte-128].
	byte <= 2r10111111
		ifTrue: [mask _ 2r00111111.  count _ 1]
		ifFalse: [byte <= 2r11011111
					ifTrue: [mask _ 2r00011111.  count _ 2]
					ifFalse: [byte <= 2r11101111
								ifTrue: [mask _ 2r00001111.  count _ 3]
								ifFalse: [byte <= 2r11110111
											ifTrue: [mask _ 2r00000111.  count _ 4]
											ifFalse: [self unimplemented]]]].
	byte _ byte bitAnd: mask.
	(byte bitAnd: ((mask bitInvert bitShiftRight: 1) bitAnd: mask)) ~= Int32Zero
		ifTrue:
			[byte _ byte bitOr: mask bitInvert.
			num _ -1]
		ifFalse: [num _ Int32Zero.
				((count > 3) and: [(byte ~= (byte bitAnd: mask))]) ifTrue: [self unimplemented]].
	num _ (num bitShift: 8) + byte.
	1 to: count do: [:i {Int32} | num _ (num bitShift: 8) + stream getByte].
	^ num! !

!Binary2Rcvr methodsFor: 'private:'!

{void} endThing
	myDepth == IntegerVar0 ifTrue: [self endPacket]!

{void} startThing
	myDepth == IntegerVar0 ifTrue: [myStream refill]! !

!Binary2Rcvr methodsFor: 'creation'!

create: specialist {TransferSpecialist} with: stream {XnReadStream}

	super create: specialist.
	myStream _ stream.
	myDepth _ IntegerVar0!

{void} destroy
	(SomeRcvrs store: self) ifFalse: [super destroy]! !

!Binary2Rcvr methodsFor: 'smalltalk: deja vu'!

{void} getIdentifier: buf {UInt8Array}
	"get an identifier from the stream into a pre-allocated buffer"

	| c {char} nextPos {UInt32} limit {UInt32} |
	[limit _ buf count - 1    "For the NULL at the end."] translateOnly.
	[limit _ buf count] smalltalkOnly.
	nextPos _ UInt32Zero.
	c _ myStream getByte.
	[(Character isalnum: c) or: [c == $_]] whileTrue:
		[nextPos >= limit ifTrue: [TextyRcvr blast.IdentifierTooLong raise].
		buf at: nextPos store: c uint8.
		nextPos _ nextPos + 1.
		c _ Character char: myStream getByte].
	myStream putBack: c uint8.
	[buf at: nextPos store: Int32Zero] translateOnly.
	[buf become: (PrimSpec uInt8 arrayFromBuffer: nextPos with: buf)] smalltalkOnly.!

{void} receiveString: array {UInt8Array}
	self startThing.
	[^String streamContents: [ :stream | | c {char} |
		self getCharToken: $".
		[$" ~~ (c _ myStream getByte)] whileTrue:
			[c ~~ $\ ifTrue:
				[stream nextPut: c]
			ifFalse:
				[c _ myStream getByte.
				c == $' ifTrue:
					[stream nextPut: $']
				ifFalse: [c == $" ifTrue:
					[stream nextPut: $"]
				ifFalse: [c == $n ifTrue:
					[stream nextPut: Character cr]
				ifFalse: [c == $t ifTrue:
					[stream nextPut: Character tab]
				ifFalse: [c == $b ifTrue:
					[stream nextPut: Character backspace]
				ifFalse:
					[self class blast.InvalidCharacter raise]]]]]]]]] smalltalkOnly.
	[self unimplemented] translateOnly.
	self endThing! !

!Binary2Rcvr methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '( ' << myStream << ')'! !

!Binary2Rcvr methodsFor: 'protected: accessing'!

{XnReadStream INLINE} stream
	^ myStream! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Binary2Rcvr class
	instanceVariableNames: ''!

(Binary2Rcvr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!Binary2Rcvr class methodsFor: 'creation'!

{SpecialistRcvr} make: specialist {TransferSpecialist} with: stream {XnReadStream}
	| result {Heaper} |
	result := SomeRcvrs fetch.
	result == NULL
		ifTrue: [^ self create: specialist with: stream]
		ifFalse: [^ (self new.Become: result) create: specialist with: stream]! !

!Binary2Rcvr class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeRcvrs := InstanceCache make: 8!

linkTimeNonInherited
	SomeRcvrs := NULL! !