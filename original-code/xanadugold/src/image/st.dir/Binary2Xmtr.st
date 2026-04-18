'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:08 pm'!

SpecialistXmtr subclass: #Binary2Xmtr
	instanceVariableNames: '
		myStream {XnWriteStream}
		myDepth {IntegerVar}'
	classVariableNames: '
		MaxNumberLength {Int32} 
		NumberBuffer {UInt8 star} 
		SomeXmtrs {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(Binary2Xmtr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!Binary2Xmtr methodsFor: 'sending'!

{void} sendBooleanVar: b {BooleanVar}
	b ifTrue: [myStream putByte: 1] ifFalse: [myStream putByte: Int0].
	self endThing!

{void} sendCategory: cat {Category} 
	self putIntegerVar: (self specialist numberOfCategory: cat) + 1.
	self endThing!

{void} sendIEEEDoubleVar: x {IEEEDoubleVar} 
	"Sending the normal decimal approximation doesn't work because it introduces 
	roundoff error. What we need to do instead is send a hex encoding of the IEEE 
	double precision (64-bit) representation of the number. For clarity in the 
	textual protocol, we also include the decimal approximation in a comment."

	self unimplemented.
	"self putIntegerVar: x DOTmantissa.
	self putIntegerVar: x DOTexponent."
	self endThing!

{void} sendInt32: n {Int32}
	self putIntegerVar: n.
	self endThing!

{void} sendInt8: n {Int8}
	myStream putByte: (n \\ 256).
	self endThing!

{void} sendIntegerVar: n {IntegerVar}
	self putIntegerVar: n.
	self endThing!

{void} sendString: s {char star}

	self putIntegerVar: (Integer IntegerVar: (String strlen: s)).
	myStream putStr: s.
	self endThing!

{void} sendUInt32: n {UInt32}
	self putIntegerVar: n.
	self endThing!

{void} sendUInt4: n {UInt4}
	self putIntegerVar: n.
	self endThing!

{void} sendUInt8: n {UInt8}
	myStream putByte: n.
	self endThing!

{void} sendUInt8Data: array {UInt8Array}

	myStream putData: array.
	self endThing! !

!Binary2Xmtr methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '( ' << myStream << ')'! !

!Binary2Xmtr methodsFor: 'protected: sending'!

{void} endPacket
	"Put in a separator pattern so we can detect the packets visually."
	myStream putByte: $!! uint8.
	myStream putByte: $!! uint8.
	myStream flush.
	super endPacket!

{void} endThing
	myDepth <= IntegerVar0 ifTrue: [self endPacket]!

{void} putIntegerVar: num {IntegerVar}
	"Send a Dean style humber.  Like Drexler style, except all the tag bits go into the first byte."
	 
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
	| abs {IntegerVar} stream {XnWriteStream wimpy} val {Int32} |
	stream _ self stream.
	val _ num DOTasLong.
	val < Int32Zero ifTrue: [abs _ val negated] ifFalse: [abs _ val].
	abs < "2**6" 64 ifTrue: [stream putByte: (val bitAnd: 127).  ^VOID].
	abs < "2**13"  8192 ifTrue: 
		[stream putByte: (((val bitShiftRight: 8) bitAnd: 2r0111111) bitOr: 2r10000000).
		stream putByte: (val  bitAnd: 255).
		^VOID].
	abs < "2**20"  1048576 ifTrue: 
		[stream putByte: (((val  bitShiftRight: 16) bitAnd: 2r011111) bitOr: 2r11000000).
		stream putByte: ((val  bitShiftRight: 8) bitAnd: 255).
		stream putByte: (val  bitAnd: 255).
		^VOID].
	abs < "2**27"  134217728 ifTrue: 
		[stream putByte: (((val  bitShiftRight: 24) bitAnd: 2r00001111) bitOr: 2r11100000).
		stream putByte: ((val  bitShiftRight: 16) bitAnd: 255).
		stream putByte: ((val  bitShiftRight: 8) bitAnd: 255).
		stream putByte: (val  bitAnd: 255).
		^VOID].
	"abs < (2**34)" true ifTrue: 
		[stream putByte: (((val bitShiftRight: 32) bitAnd: 2r0111) bitOr: 2r11110000).
		stream putByte: ((val bitShiftRight: 24) bitAnd: 255).
		stream putByte: ((val bitShiftRight: 16) bitAnd: 255).
		stream putByte: ((val bitShiftRight: 8) bitAnd: 255).
		stream putByte: (val bitAnd: 255).
		^VOID].
	Eric thingToDo. "humber case"!

{void} sendNULL

	myStream putByte: Int0.
	self endThing!

{void} startNewInstance: cat {Category} 
	"start sending an instance of a particular class. Add one because 0 means NULL"
	
	myDepth _ myDepth + 1.
	self sendCategory: cat!

{XnWriteStream INLINE} stream
	^myStream! !

!Binary2Xmtr methodsFor: 'creation'!

create: specialist {TransferSpecialist} with: stream {XnWriteStream}
	super create: specialist.
	myStream _ stream.
	myDepth _ IntegerVar0!

{void} destroy
	(SomeXmtrs store: self) ifFalse: [super destroy]! !

!Binary2Xmtr methodsFor: 'specialist sending'!

{void} endInstance
	"end sending an instance"
	myDepth _ myDepth - 1.
	self endThing! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Binary2Xmtr class
	instanceVariableNames: ''!

(Binary2Xmtr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!Binary2Xmtr class methodsFor: 'creation'!

{SpecialistXmtr} make: specialist {TransferSpecialist} with: stream {XnWriteStream}
	| result {Heaper} |
	result := SomeXmtrs fetch.
	result == NULL
		ifTrue: [^ self create: specialist with: stream]
		ifFalse: [^ (self new.Become: result) create: specialist with: stream]! !

!Binary2Xmtr class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeXmtrs := InstanceCache make: 8!

linkTimeNonInherited
	MaxNumberLength _ 400.
	NumberBuffer _ UInt8 vector create: MaxNumberLength.
	[NumberBuffer _ UInt8Array make: MaxNumberLength] smalltalkOnly.
	SomeXmtrs := NULL! !