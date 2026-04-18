'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:17 pm'!

CompiledCode subclass: #CompiledBlock
	instanceVariableNames: 'outerMethod '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Methods'!
CompiledBlock comment:
'Class CompiledBlock represents the compiled code for a block.

Instance Variables:
	outerMethod	<CompiledMethod | CompiledBlock>  the code for the enclosing scope
'!


!CompiledBlock methodsFor: 'initialize-release'!

outerMethod: code
	"This is only used by the compiler."

	outerMethod _ code! !

!CompiledBlock methodsFor: 'source code management'!

fileIndex
	source == nil ifTrue: [^outerMethod fileIndex].
	^super fileIndex!

filePosition
	source == nil ifTrue: [^outerMethod filePosition].
	^super filePosition! !

!CompiledBlock methodsFor: 'accessing'!

homeMethod
	"Answer the context in which the receiver was defined."

	^outerMethod homeMethod!

numCopiedValues
	"Answer the number of values of the receiver that were copied."

	^(self byteAt: 1) = OpCopyValues
		ifTrue: [self byteAt: 2]
		ifFalse: [0]!

outerMethod
	^outerMethod! !

!CompiledBlock methodsFor: 'comparing'!

= aMethod

	outerMethod == aMethod ifFalse: [^false].
	^super = aMethod! !

!CompiledBlock methodsFor: 'testing'!

isBlockMethod
	^true! !

!CompiledBlock methodsFor: 'private: private'!

methodWithSource
	source == nil ifFalse: [^self].
	^outerMethod methodWithSource! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CompiledBlock class
	instanceVariableNames: ''!


!CompiledBlock class methodsFor: 'instance creation'!

bytes: b literals: l numArgs: na numTemps: nt maxDepth: m needsFrame: nf hybrid: hf forContext: cf
	"Answer a new instance of the receiver."

	^self new
		initBytes: b
		literals: l
		numArgs: na
		numTemps: nt
		maxDepth: m
		needsFrame: nf
		inBlock: true
		hybrid: hf
		forContext: cf! !