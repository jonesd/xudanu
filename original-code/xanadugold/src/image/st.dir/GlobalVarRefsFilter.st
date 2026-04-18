'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:42 pm'!

MethodFilter subclass: #GlobalVarRefsFilter
	instanceVariableNames: 'myName {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!GlobalVarRefsFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BlockParsingAction create: [:each {ProgramNode} |
		(each isKindOf: VariableNode) and: [each name = myName]]!

{String} label
	
	^'Users of global ', myName!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^code refersToLiteral: self assoc! !

!GlobalVarRefsFilter methodsFor: 'creation'!

create: name {Symbol}

	super create.
	myName _ name! !

!GlobalVarRefsFilter methodsFor: 'private:'!

{Association of: Symbol with: Behavior} assoc

	^Smalltalk associationAt: myName! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GlobalVarRefsFilter class
	instanceVariableNames: ''!



!GlobalVarRefsFilter class methodsFor: 'creation'!

make: aName {Symbol}

	^self create: aName! !