'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:16 pm'!

Heaper subclass: #FilterStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filters'!
FilterStream comment:
'XuFilterStream represents a filter (or set thereof) on waldos.  A filter stream accepts input waldos (through a stream) and produces an output stream of waldos.  The stream protocol used is the stepper protocol.  All filter streams are zero to many input and one output.'!

(FilterStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!FilterStream methodsFor: 'streaming'!

{ID} fetch

	"This method returns the current Waldo on the stream, or NULL if hasValue is FALSE.  The fetch does NOT affect the state of the stream."
	
	self subclassResponsibility!

{Waldo} get

	"This method returns the current Waldo on the stream.  This method will BLAST if hasValue is FALSE.  The get does NOT affect the state of the stream."
	
	self fetch == NULL ifTrue: [Heaper BLAST: #EmptyFilterStream].
	^ self fetch!

{BooleanVar} hasValue

	"This method returns TRUE iff a fetch on the stream will produce a Waldo"
	
	self subclassResponsibility!

{void} step

	"This method advances the stream to the next Waldo.  This is a valid operation iff hasValue is TRUE, it will blast otherwise."
	
	self subclassResponsibility! !

!FilterStream methodsFor: 'accessing'!

{PackOBits} pattern

	"This method returns a 'signature' for the filter stream that identifies it for the purpose of combining filter streams into more efficient, code-supported filters (primitive filters)."
	
	self subclassResponsibility! !

!FilterStream methodsFor: 'creation'!

{FilterStream} copy

	"This method returns a copy of the stream in its current state.  A stream and it's copy should return the same sequence of ids regardless of the order they are stepped over."
	
	self subclassResponsibility! !

!FilterStream methodsFor: 'protected: patterns'!

{PackOBits} concat: first {MuWordArray} with: rest {MuWordArray}

	| nuPart  {MuWordArray} |
	nuPart _ first copy.
	nuPart introduceAll: rest 
				with: (IntegerMapping make: nuPart count) 
				with: NULL.
	^ Sequence string: nuPart asString!

{MuWordArray} wrap: middle {PackOBits}

	| middleStr {MuWordArray} concatted {MuWordArray} |
	middleStr _ (middle convert: MuWordArray) cast: MuWordArray.
	concatted _ MuWordArray make.charVector: '('.
	concatted introduceAll: middleStr 
					with: (IntegerMapping make: concatted count) 
					with: NULL.
	concatted introduceAll: (MuWordArray make.charVector: ')') 
					with: (IntegerMapping make: concatted count) 
					with: NULL.
	middleStr destroy.
	^ Sequence string: concatted asString! !

!FilterStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !