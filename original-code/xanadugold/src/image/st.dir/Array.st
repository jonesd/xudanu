'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:35 pm'!

ArrayedCollection variableSubclass: #Array
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Arrayed'!
Array comment:
'Class Array represents SequenceableCollections whose elements are any objects. It provides the concrete representation for storing a collection of elements that have integers as external keys.  

Instance Variables: *indexed*'!


!Array methodsFor: 'converting'!

{Array}asArray
	"Answer the receiver itself."

	^self! !

!Array methodsFor: 'printing'!

{BooleanVar}isLiteral
	"Answer whether all the elements of the array are literal."

	self detect: [:element | element isLiteral not] ifNone: [^true].
	^false!

{void}printOn: aStream {ostream reference}
	"Append to the argument, aStream, the elements of the Array 
	enclosed by parentheses."

	| tooMany |
	tooMany _ aStream position + self maxPrint.
	aStream nextPut: $(.
	self do: 
		[:element | 
		aStream position > tooMany
			ifTrue: 
				[aStream nextPutAll: '...etc...)'.
				^self].
		element printOn: aStream.
		aStream space].
	aStream nextPut: $)!

{void}storeOn: aStream{ostream reference} 
	"Append to the argument aStream a sequence of characters that is an
	expression whose evaluation creates an object similar to the receiver.
	Use the literal form if possible."

	self isLiteral
		ifTrue: 
			[aStream nextPut: $#; nextPut: $(.
			self do: 
				[:element | 
				((element isKindOf: Symbol) and: [Scanner isLiteralSymbol: element])
					ifTrue: [element printOn: aStream]
					ifFalse: [element storeOn: aStream].
				aStream space].
			aStream nextPut: $)]
		ifFalse: [super storeOn: aStream]! !

!Array methodsFor: 'testing'!

{BooleanVar} refersTowardsLiteral: aLiteral
	self == aLiteral ifTrue: [^true].
	self do: [:el | 
		(el refersTowardsLiteral: aLiteral)
			ifTrue: [^true]].
	^false.! !

!Array methodsFor: 'literals'!

{Set of: Symbol} literalSymbols
	| result {Set of: Symbol} |
	result _ Set new.
	self do: [:el |
		result addAll: el literalSymbols].
	^result! !

!Array methodsFor: 'smalltalk: passe'!

{void} choose: thing {Heaper} for: aBlock {BlockClosure}
	"'#(Foo Bar) choose: p for: [:q | ... q ...]' translates to
	 'CHOOSE2(Foo,Bar,q,p, { ... q ...});'"
	
	self passe! !