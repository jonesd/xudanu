'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:34 pm'!

MethodFilter subclass: #CallersFilter
	instanceVariableNames: '
		myFunc {MethodRep}
		mySpecialIndex {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!CallersFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BlockParsingAction create: [:each {ProgramNode} |
		(each isKindOf: SimpleMessageNode)
		and: [each selector == myFunc selector
		and: [| rec | rec _ each receiver. ((rec isKindOf: VariableNode)
				and: [rec name = myFunc methodClass soleInstance name or: [rec name = 'self']])
			or: [(rec isKindOf: SimpleMessageNode) 
				and: [rec selector == #class
				and: [(rec receiver isKindOf: VariableNode)
				and: [rec receiver name = 'self']]]]]]]!

{String} label
	
	^'Callers of ', myFunc printString!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	| action | 

	(((code refersToLiteral: (Smalltalk associationAt: myFunc methodClass soleInstance name))
		or: [cls = myFunc methodClass or: [cls class = myFunc methodClass]])
	 and: [(code refersTowardsLiteral: myFunc selector)
	 	or: [mySpecialIndex > 0 and: [code sendsSpecialSelector: mySpecialIndex]]])
	 	ifFalse: [^false].
	 	
	action _ self fetchAction. 
	(action parse: (cls sourceCodeStringAt: sel)) properDo: [:each {ProgramNode} |
		(action passes: each)
			ifTrue: [^true]].
	^false!

{String} requestReplacementString

	^self class requestString: 'Selector to replace it with...'! !

!CallersFilter methodsFor: 'creation'!

create: func {MethodRep}

	super create.
	myFunc _ func.
	mySpecialIndex _ Smalltalk specialSelectorIndexOf: myFunc selector! !

!CallersFilter methodsFor: 'testing'!

test1

	self make: #foo!

test2

	self class make: #foo! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CallersFilter class
	instanceVariableNames: ''!



!CallersFilter class methodsFor: 'testing'!

test1

	self make: #foo!

test2

	self class make: #foo! !

!CallersFilter class methodsFor: 'creation'!

make: func {MethodRep}

	^self create: func! !