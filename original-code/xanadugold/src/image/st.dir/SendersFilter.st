'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:50 pm'!

MethodFilter subclass: #SendersFilter
	instanceVariableNames: '
		myLiteral {Symbol}
		mySpecialIndex {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!SendersFilter methodsFor: 'creation'!

create: literal {Symbol}

	super create.
	myLiteral _ literal.
	mySpecialIndex _ Smalltalk specialSelectorIndexOf: literal! !

!SendersFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	| desc {SequenceableCollection of: (Array of: Symbol with: Symbol)} |
	desc _ Array with: (Array with: myLiteral with: myLiteral).
	^MethodAction
		combine: (SendersAction make: desc)
		with: (LiteralsAction make: desc)!

{String} label
	
	^'Senders of ', myLiteral!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^(code refersTowardsLiteral: myLiteral)
	or: [mySpecialIndex > 0 and: [code sendsSpecialSelector: mySpecialIndex]]!

{String} requestReplacementString

	^self class requestString: 'Selector to replace it with...'!

testit

	^#(foo passes:with:with: pattern bar 'pattern' #'pattern'), (Array with: #pattern)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SendersFilter class
	instanceVariableNames: ''!



!SendersFilter class methodsFor: 'creation'!

make: literal {Symbol}

	^self create: literal! !