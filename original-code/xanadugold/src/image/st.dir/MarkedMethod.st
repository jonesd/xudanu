'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:22 pm'!

CompiledMethod subclass: #MarkedMethod
	instanceVariableNames: 'markType '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Methods'!
MarkedMethod comment:
'Class MarkedMethod represents a compiled method which has been marked for special treatment by the exception-handling machinery.  Marked methods should only be created with the message #as{Unwind, Propagate, Handler}From:.

Instance Variables:
	markType	<Symbol>
				One of {#handle, #unwind, #propagate}
				e.g., what sort of handler treatment I imply.'!


!MarkedMethod methodsFor: 'testing'!

isMarked
	"Answer if this is a marked method."

	^true!

isMarkedForHandle
	"Answer true if marked for handle:."

	^markType == #handle!

isMarkedForPropagate
	"Answer true if marked for propagate."

	^markType == #propagate!

isMarkedForUnwind
	"Answer true if method is marked for unwinding."

	^markType == #unwind! !

!MarkedMethod methodsFor: 'printing'!

printSymbolicOn: aStream
	"Print a symbolic representation of my contents on aStream."
	"Add some mark info to super's implementation."

	aStream nextPutAll: (markType notNil ifTrue: [markType, '-marked'] ifFalse: ['?-marked']).
	aStream space.
	^super printSymbolicOn: aStream! !

!MarkedMethod methodsFor: 'comparing'!

= aMethod

	super = aMethod ifFalse: [^false].
	^markType == aMethod markType! !

!MarkedMethod methodsFor: 'private: private'!

markForHandleOrPropagate
	"Set the handle/propagate flag bit known by the VM."

	bytes at: 1 put: ((bytes at: 1) bitOr: 4)!

markForUnwind
	"Set the unwind flag bit known by the VM."

	bytes at: 1 put: ((bytes at: 1) bitOr: 8)!

markType
	"Only for comparing."

	^markType!

markType: aSymbol
	"Set the mark type."

	markType _ aSymbol! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MarkedMethod class
	instanceVariableNames: ''!


!MarkedMethod class methodsFor: 'instance creation'!

asHandlerFrom: method
	"Answer a method marked for handler, initialized from the argument."

	| mm |
	mm _ self fromMethod: method.
	mm markType: #handle.
	mm markForHandleOrPropagate.
	^mm!

asPropagateFrom: method
	"Answer a method marked for propagation, initialized from the argument."

	| mm |
	mm _ self fromMethod: method.
	mm markType: #propagate.
	mm markForHandleOrPropagate.
	^mm!

asUnwindFrom: method
	"Answer a method marked for unwinds, initialized from the argument."

	| mm |
	mm _ self fromMethod: method.
	mm markType: #unwind.
	mm markForUnwind.
	^mm! !

!MarkedMethod class methodsFor: 'private: private'!

fromMethod: cm
	"Answer a new method equivalent to the argument."

	| meth |
	meth _ (super new
		initBytes: cm bytes
		literals: cm literals
		numArgs: cm numArgs
		numTemps: cm numTempsOnly
		maxDepth: cm frameSize
		needsFrame: cm isQuick not
		inBlock: false
		hybrid: cm needsHybridFrame
		forContext: cm usesContextInstVars) forceLong.
	cm hasSource
		ifTrue:	[meth setSourcePosition: cm filePosition inFile: cm fileIndex].
	^meth! !