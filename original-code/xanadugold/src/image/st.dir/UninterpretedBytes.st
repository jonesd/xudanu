'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:09 pm'!

Object variableByteSubclass: #UninterpretedBytes
	instanceVariableNames: ''
	classVariableNames: 'EndianDependentClasses WasBigEndian '
	poolDictionaries: ''
	category: 'Kernel-Objects'!
UninterpretedBytes comment:
'Class UninterpretedBytes is a common superclass for non-pointer-containing objects that are not Collections.  Since instances have no semantically-meaningful substructure, they are not indexable with #at: and #at:put:.  Examples of such objects are bitmaps, network packets, and record structures to be shared with C routines. The main function of this class is to define a set of access primitives that hide the platform byte ordering.

Class Variables:
	EndianDependentClasses <IdentitySet of: Symbols> the names of classes that care if the memory layout changes
	WasBigEndian	<Boolean> indicating the memory layout of the platform on which the snapshot image was created'!


!UninterpretedBytes methodsFor: 'accessing'!

at: index 
	"Override implementation in Object since UninterpretedBytes
	instances are not element indexable."

	^self shouldNotImplement!

at: index put: value 
	"Override implementation in Object since UninterpretedBytes
	instances are not element indexable."

	^self shouldNotImplement!

byteAt: index 
	"Answer the byte at the given index."
	^self basicAt: index!

byteAt: index put: aByte
	"Store a byte at the given index."
	^self basicAt: index put: aByte!

floatAt: byteIndex
	"Answer a single-precision (32 bit)
	floating point quantity
	starting at the given byteIndex."
	<primitive: 548>
	"The only way we can do this is by
	constructing the Float byte-by-byte."
	| f |
	f _ 0.0 + 0.0.  "make a Float"
	f basicAt: 1 put: (self byteAt: byteIndex).
	f basicAt: 2 put: (self byteAt: byteIndex+1).
	f basicAt: 3 put: (self byteAt: byteIndex+2).
	f basicAt: 4 put: (self byteAt: byteIndex+3).
	^f!

floatAt: byteIndex put: aFloat 
	"Store a single-precision (32 bit) 
	floating point quantity 
	starting at the given byteIndex."

	<primitive: 549>
	"The only way we can do this is by 
	storing the Float byte-by-byte."
	| float |
	float _ aFloat asFloat.
	self byteAt: byteIndex put: (float basicAt: 1).
	self byteAt: byteIndex + 1 put: (float basicAt: 2).
	self byteAt: byteIndex + 2 put: (float basicAt: 3).
	self byteAt: byteIndex + 3 put: (float basicAt: 4).
	^float!

longAt: byteIndex
	"Answer a signed long (32 bit) quantity
	starting at the given byteIndex."
	<primitive: 546>
	^self longAt: byteIndex bigEndian: self class isBigEndian!

longAt: byteIndex put: aLong
	"Store a signed long (32 bit) quantity
	starting at the given byteIndex."
	<primitive: 547>
	^self longAt: byteIndex put: aLong bigEndian: self class isBigEndian!

longFloatAt: byteIndex
	"Answer a double-precision (64 bit)
	floating point quantity
	starting at the given byteIndex."
	<primitive: 550>
	"The only way we can do this is by
	constructing the Double byte-by-byte."
	| f |
	f := 0 asDouble.  "make a Double"
	1 to: f basicSize do:
		[ :i |	f basicAt: i put: (self byteAt: byteIndex+i-1)].
	^f!

longFloatAt: byteIndex put: aLongFloat
	"Store a double-precision (64 bit)
	floating point quantity
	starting at the given byteIndex."
	<primitive: 551>
	"The only way we can do this is by
	decomposing the long float byte-by-byte."
	| f |
	f := aLongFloat asDouble.
	1 to: f basicSize do:
		[ :i |	self byteAt: byteIndex+i-1 put: (f basicAt: i)].
	^f!

shortAt: byteIndex
	"Answer a signed short (16 bit) quantity
	starting at the given byteIndex."
	<primitive: 542>
	| word |
	word _ self unsignedShortAt: byteIndex.
	^(word bitAnd: 16r7FFF) - (word bitAnd: 16r8000)!

shortAt: byteIndex put: aShort
	"Store a signed short (16 bit) quantity
	starting at the given byteIndex."
	<primitive: 543>
	self unsignedShortAt: byteIndex put:
		(aShort bitAnd: 16r7FFF) - (aShort bitAnd: -16r8000).
	^aShort!

size
	"Override implementation in Object since UninterpretedBytes
	instances are not element indexable."

	^self shouldNotImplement!

sizeInBytes
	"Answer the number of byte fields in the receiver.  This value is the 
	same as the largest legal subscript."

	^super size!

unsignedLongAt: byteIndex
	"Answer an unsigned long (32 bit) quantity
	starting at the given byteIndex."

	<primitive: 544>
	^self unsignedLongAt: byteIndex bigEndian: self class isBigEndian!

unsignedLongAt: byteIndex put: anUnsignedLong
	"Store an unsigned long (32 bit) quantity
	starting at the given byteIndex."

	<primitive: 545>
	^self unsignedLongAt: byteIndex put: anUnsignedLong bigEndian: self class isBigEndian!

unsignedShortAt: byteIndex
	"Answer an unsigned short (16 bit) quantity
	starting at the given byteIndex."
	<primitive: 540>
	^self unsignedShortAt: byteIndex bigEndian: self class isBigEndian!

unsignedShortAt: byteIndex put: anUnsignedShort
	"Store an unsigned short (16 bit) quantity
	starting at the given byteIndex."
	<primitive: 541>
	^self unsignedShortAt: byteIndex put: anUnsignedShort bigEndian: self class isBigEndian! !

!UninterpretedBytes methodsFor: 'accessing-platform independent'!

longAt: byteIndex bigEndian: isBE
	"Answer a signed long (32 bit) quantity starting at the given byteIndex."

	| b0 b1 b2 w h |
	isBE
		ifTrue:
			[b0 _ self byteAt: byteIndex.  
			b1 _ self byteAt: byteIndex+1.  
			b2 _ self byteAt: byteIndex+2.  
			w _ self byteAt: byteIndex+3]
		ifFalse:
			[b0 _ self byteAt: byteIndex+3.  
			b1 _ self byteAt: byteIndex+2.  
			b2 _ self byteAt: byteIndex+1.  
			w _ self byteAt: byteIndex].
	"Following sequence minimizes LargeInteger arithmetic for small results."
	h _ ((b0 bitAnd: 16r7F) - (b0 bitAnd: 16r80) bitShift: 8) + b1.
	b2=0 ifFalse: [w _ (b2 bitShift: 8) + w].
	h=0 ifFalse: [w _ (h bitShift: 16) + w].
	^w!

longAt: byteIndex put: aLong bigEndian: isBE
	"Store a signed long (32 bit) quantity starting at the given byteIndex."

	| b0 b1 b2 b3 |
	b0 _ aLong bitShift: -24.
	  b0 _ (b0 bitAnd: 16r7F) - (b0 bitAnd: -16r80).
	b1 _ (aLong bitShift: -16) bitAnd: 16rFF.
	b2 _ (aLong bitShift: -8) bitAnd: 16rFF.
	b3 _ aLong bitAnd: 16rFF.
	isBE
		ifTrue:
			["Only the first store can fail."
			self byteAt: byteIndex put: b0.  
			self byteAt: byteIndex+1 put: b1.
			self byteAt: byteIndex+2 put: b2.  
			self byteAt: byteIndex+3 put: b3]
		ifFalse:
			["Only the first store can fail."
			self byteAt: byteIndex+3 put: b0.  
			self byteAt: byteIndex+2 put: b1.
			self byteAt: byteIndex+1 put: b2.  
			self byteAt: byteIndex put: b3].
	^aLong!

replaceBytesFrom: start to: stop with: replacement startingAt: repStart 
	"This destructively replaces bytes from start to stop in the 
	receiver starting at index, repStart, from the byte-object, 
	replacement. Answer the receiver."

	<primitive: 559>
	| repOff |
	repOff _ repStart - start.
	(self == replacement and: [repStart < start])
		ifTrue:	["Replacement would be overwritten; use reverse order"
				stop to: start by: -1 do:
					[ :i |	self byteAt: i put: (replacement byteAt: repOff + i)]]
		ifFalse:	[start to: stop do:
					[ :i |	self byteAt: i put: (replacement byteAt: repOff + i)]]!

shortAt: byteIndex bigEndian: isBE
	| word |
	word _ self unsignedShortAt: byteIndex bigEndian: isBE.
	^(word bitAnd: 16r7FFF) - (word bitAnd: 16r8000)!

shortAt: byteIndex put: aShort bigEndian: isBE
	"Store a signed short (16 bit) quantity starting at the given byteIndex."

	self unsignedShortAt: byteIndex put:
		(aShort bitAnd: 16r7FFF) - (aShort bitAnd: -16r8000) bigEndian: isBE.
	^aShort!

unsignedLongAt: byteIndex bigEndian: isBE
	"Answer an unsigned long (32 bit) quantity starting at the given byteIndex."

	| b0 b1 b2 w |
	isBE
		ifTrue:
			[b0 _ self byteAt: byteIndex.  
			b1 _ self byteAt: byteIndex+1.  
			b2 _ self byteAt: byteIndex+2.  
			w _ self byteAt: byteIndex+3]
		ifFalse:
			[b0 _ self byteAt: byteIndex+3.  
			b1 _ self byteAt: byteIndex+2.  
			b2 _ self byteAt: byteIndex+1.  
			w _ self byteAt: byteIndex].
	"Following sequence minimizes LargeInteger arithmetic for small results."
	b2=0 ifFalse: [w _ (b2 bitShift: 8) + w].
	b1=0 ifFalse: [w _ (b1 bitShift: 16) + w].
	b0=0 ifFalse: [w _ (b0 bitShift: 24) + w].
	^w!

unsignedLongAt: byteIndex put: anUnsignedLong bigEndian: isBE
	"Store an unsigned long (32 bit) quantity starting at the given byteIndex."

	| b0 b1 b2 b3 |
	b0 _ anUnsignedLong bitShift: -24.
	b1 _ (anUnsignedLong bitShift: -16) bitAnd: 16rFF.
	b2 _ (anUnsignedLong bitShift: -8) bitAnd: 16rFF.
	b3 _ anUnsignedLong bitAnd: 16rFF.
	isBE
		ifTrue:
			["Only the first store can fail."
			self byteAt: byteIndex put: b0.  
			self byteAt: byteIndex+1 put: b1.
			self byteAt: byteIndex+2 put: b2.  
			self byteAt: byteIndex+3 put: b3]
		ifFalse:
			["Only the first store can fail."
			self byteAt: byteIndex+3 put: b0.  
			self byteAt: byteIndex+2 put: b1.
			self byteAt: byteIndex+1 put: b2.  
			self byteAt: byteIndex put: b3].
	^anUnsignedLong!

unsignedShortAt: byteIndex bigEndian: isBE
	"Answer an unsigned short (16 bit) quantity starting at the given byteIndex."

	^isBE
		ifTrue: [((self byteAt: byteIndex) bitShift: 8) + (self byteAt: byteIndex + 1)]
		ifFalse: [((self byteAt: byteIndex + 1) bitShift: 8) + (self byteAt: byteIndex)]!

unsignedShortAt: byteIndex put: anUnsignedShort bigEndian: isBE
	"Store an unsigned short (16 bit) quantity starting at the given byteIndex."

	isBE
		ifTrue:
			["Just shifting, without masking, will cause byteAt:put:
			to fail if anUnsignedShort doesn't fit in 16 bits."
			self byteAt: byteIndex put: (anUnsignedShort bitShift: -8).
			self byteAt: byteIndex + 1 put: (anUnsignedShort bitAnd: 16rFF)]
		ifFalse:
			[self byteAt: byteIndex + 1 put: (anUnsignedShort bitShift: -8).
			self byteAt: byteIndex put: (anUnsignedShort bitAnd: 16rFF)].
	^anUnsignedShort! !

!UninterpretedBytes methodsFor: 'byte order reversal'!

reverseByteOrder
	"Only subclasses know what their byte interpretation is.
	Default is no interpretation."
	^self!

swapLongAt: index 
	"Used in migrating the receiver onto a new host platform"

	| tmp |
	tmp _ self byteAt: index.
	self byteAt: index put: (self byteAt: index + 3).
	self byteAt: index + 3 put: tmp.
	tmp _ self byteAt: index + 1.
	self byteAt: index + 1 put: (self byteAt: index + 2).
	self byteAt: index + 2 put: tmp!

swapShortAt: index 
	"Used in migrating the receiver onto a new host platform"

	| tmp |
	tmp _ self byteAt: index.
	self byteAt: index put: (self byteAt: index + 1).
	self byteAt: index + 1 put: tmp! !

!UninterpretedBytes methodsFor: 'comparing'!

= anObject
	"Answer whether the bytes of the receiver and argument are the same."

	(anObject class isBits and: [self sizeInBytes = anObject basicSize])
		ifFalse: [^false].
	1 to: self sizeInBytes do: [:i | (self byteAt: i)
			= (anObject basicAt: i) ifFalse: [^false]].
	^true!

hash
	"Answer a SmallInteger unique to the receiver."

	self sizeInBytes = 0 ifTrue: [^17171].
	^(self byteAt: 1) hash + (self byteAt: self sizeInBytes) hash + self sizeInBytes hash! !

!UninterpretedBytes methodsFor: 'copying'!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance 
	variable. Object>>deepCopy would do much unneeded work; since
	the instance contains only bits, just do a copy."

	^self copy! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UninterpretedBytes class
	instanceVariableNames: ''!


!UninterpretedBytes class methodsFor: 'class initialization'!

initialize
	"UninterpretedBytes initialize."

	"Protect against multiple initialize's; but I sure wish that dependents had set semantics."
	EndianDependentClasses _ IdentitySet new.
	Smalltalk removeDependent: self.
	Smalltalk addDependent: self.
	self checkByteOrder!

obsolete
	Smalltalk removeDependent: self.
	^super obsolete! !

!UninterpretedBytes class methodsFor: 'instance creation'!

from: aByteArray
	"Make a new UninterpretedBytes instance which copies the
	contents of aByteArray.  Answer the new instance."
	| ub len |
	len _ aByteArray size.
	ub _ self new: len.
	ub replaceBytesFrom: 1 to: len with: aByteArray startingAt: 1.
	^ub!

with: aByteArray from: start to: stop
	"Make a new UninterpretedBytes instance which copies the
	contents of aByteArray beginning at index start and ending at
	index stop.  Answer the new instance."
	| ub len |
	len _ stop - start + 1.
	ub _ self new: len.
	ub replaceBytesFrom: 1 to: len with: aByteArray startingAt: start.
	^ub! !

!UninterpretedBytes class methodsFor: 'testing'!

isBigEndian
	"Return true if this platform uses big-endian
	order for multi-byte scalars (e.g., MC680xx,
	SPARC), false if it uses little-endian order
	(e.g., Intel 80x86, VAX)."
	<primitive: 534>
	"For debugging only, we assume big-endian.
	This should be self primitiveFailed."
	^true! !

!UninterpretedBytes class methodsFor: 'system initialization'!

checkByteOrder
	"Check to see if current platform byte-endianness is the 
	same as it was before. If not (e.g. returning from a snapshot 
	on a different platform), inform all subclasses."

	| cbe |
	cbe _ self isBigEndian.
	WasBigEndian notNil
		ifTrue: [(WasBigEndian eqv: cbe)
			ifFalse: 
				[self allSubclassesDo: [:c | c reverseByteOrder].
				EndianDependentClasses do: [:clName | (Smalltalk at: clName)
						allInstancesDo: [:obj | obj reverseByteOrder]]]].
	WasBigEndian _ cbe!

deregister: aClass
	"Record that aClass's instances need to be mutated when
	the image is put on a machine with a different endian convention"

	EndianDependentClasses remove: aClass name ifAbsent: []!

register: aClass
	"Record that aClass's instances need to be mutated when
	the image is put on a machine with a different endian convention"

	(aClass isKindOf: UninterpretedBytes)
		ifFalse:	[EndianDependentClasses add: aClass name]!

reverseByteOrder
	"Inform all instances that they need to reverse their byte-order."

	self allInstancesDo: [:o | o reverseByteOrder]! !

!UninterpretedBytes class methodsFor: 'examples'!

example
	"UninterpretedBytes example"
	| ex |
	ex _ self new: 5.
	ex byteAt: 2 put: 16r81.
	ex byteAt: 3 put: 16r83.
	ex byteAt: 4 put: 16r5.
	ex byteAt: 5 put: 16r87.
	#(shortAt: unsignedShortAt: longAt: unsignedLongAt:)
	with: (self isBigEndian
		ifTrue: [#(-16r7E7D 16r8183 -16r7E7CFA79 16r81830587)]
		ifFalse: [#(-16r7C7F 16r8381 -16r78FA7C7F 16r87058381)])
	do: [:msg :result |
		(ex perform: msg with: 2) = result ifFalse: [self error: 'accessing error']].! !

UninterpretedBytes initialize!
