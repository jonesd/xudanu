'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:19 pm'!

CompiledCode subclass: #CompiledMethod
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Methods'!
CompiledMethod comment:
'Class CompiledMethod represents the compiled code for a method.
'!


!CompiledMethod methodsFor: 'accessing'!

homeMethod
	^self!

primitiveNumber
	"Return the primitive number in the
	head of this method, or nil if none."
	^(self byteAt: 1) = OpPrimitive
		ifTrue: [(self byteAt: 2) * 256 + (self byteAt: 3)]
		ifFalse: [nil]!

withAllBlockMethods
	"Answer an ordered collection including this method
	and all related block methods."
	| result |
	result _ OrderedCollection new.
	self withAllBlockMethodsDo: [:meth | result addLast: meth].
	^result!

withPrimitiveNumber: anInteger
	"This method must already invoke a primitive.
	Return a copy of it with the primitive number
	changed.  This is only used by the simulator."

	self primitiveNumber isNil
		ifTrue:
			[self error: 'This method has no primitive'.
			^self].
	(anInteger isInteger and: [anInteger noMask: 16r-10000])
		ifFalse:
			[self error: 'Invalid primitive number'.
			^self].
	^self shallowCopy forcePrimitiveNumber: anInteger! !

!CompiledMethod methodsFor: 'testing'!

isBlockMethod
	^false! !

!CompiledMethod methodsFor: 'copying'!

asHandlerMethod
	"Answer a copy of me as a handler method."

	^MarkedMethod asHandlerFrom: self!

asPropagateMethod
	"Answer a copy of me as a propagate method."

	^MarkedMethod asPropagateFrom: self!

asUnwindMethod
	"Answer a copy of me as a unwind method."

	^MarkedMethod asUnwindFrom: self! !

!CompiledMethod methodsFor: 'private: private'!

forcePrimitiveNumber: anInteger 
	"This is only called after a shallowCopy. 
	anInteger has been checked already."

	self isShort
		ifTrue: [bytes _ (bytes bitAnd: 16r3FFFC0 bitInvert) + (anInteger bitShift: 6)]
		ifFalse: 
			[| byte0 newBytes |
			byte0 _ self isLong ifTrue: [4] ifFalse: [1].
			newBytes _ bytes copy.
			"Byte 1 is the 'primitive' op-code"
			newBytes at: byte0 + 2 put: (anInteger bitShift: -8).
			newBytes at: byte0 + 3 put: (anInteger bitAnd: 255).
			bytes _ newBytes]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CompiledMethod class
	instanceVariableNames: ''!


!CompiledMethod class methodsFor: 'instance creation'!

bytes: b literals: l numArgs: na numTemps: nt maxDepth: m needsFrame: nf hybrid: hf forContext: cf
	^self new
		initBytes: b
		literals: l
		numArgs: na
		numTemps: nt
		maxDepth: m
		needsFrame: nf
		inBlock: false
		hybrid: hf
		forContext: cf! !