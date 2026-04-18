'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:32 pm'!

MethodFilter subclass: #AssociationRefsFilter
	instanceVariableNames: 'myAssoc {Association}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!AssociationRefsFilter methodsFor: 'creation'!

create: assoc {Association}

	super create.
	myAssoc _ assoc! !

!AssociationRefsFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BlockParsingAction create: [:each {ProgramNode} |
		(each isKindOf: VariableNode) and: [each name = myAssoc key]]!

{String} label
	
	^'Users of a Location named ', myAssoc key!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^code refersToLiteral: myAssoc! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AssociationRefsFilter class
	instanceVariableNames: ''!



!AssociationRefsFilter class methodsFor: 'creation'!

make: assoc {Association}

	^self create: assoc! !