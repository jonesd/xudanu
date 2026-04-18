'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:34 pm'!

MethodFilter subclass: #ClassRefsFilter
	instanceVariableNames: '
		myClass {Behavior}
		myOldName {Symbol | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!ClassRefsFilter methodsFor: 'creation'!

create: cls {Behavior} with: oldName {String default: nil}

	super create.
	myClass _ cls.
	myClass isMeta
		ifTrue: [myClass _ myClass soleInstance].
	myOldName _ oldName! !

!ClassRefsFilter methodsFor: 'smalltalk: defaults'!

create: cls {Behavior}

	self create: cls with: nil! !

!ClassRefsFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	| act |
	myOldName == nil
		ifTrue: [^BlockParsingAction create: [:each {ProgramNode} |
					(each isKindOf: VariableNode)
					 and: [each name = myClass name]]]
		ifFalse: [act _ (MatchingAction create: myOldName).
				act replacement: myClass name.
				^act]!

{String} label
	
	^'Users of ', myClass name!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^code refersToLiteral: self assoc! !

!ClassRefsFilter methodsFor: 'private:'!

{Association of: Symbol with: Behavior} assoc

	^Smalltalk associationAt: myClass name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClassRefsFilter class
	instanceVariableNames: ''!



!ClassRefsFilter class methodsFor: 'creation'!

make: cls {Behavior} with: oldName {String default: nil}
	"((GenerateFromFamily make: Mapping) 
		filteredBy: (ClassRefsFilter make: XuRegion)) browse"
		
	^self create: cls with: oldName! !

!ClassRefsFilter class methodsFor: 'smalltalk: defaults'!

make: cls {Behavior}

	^self make: cls with: nil! !