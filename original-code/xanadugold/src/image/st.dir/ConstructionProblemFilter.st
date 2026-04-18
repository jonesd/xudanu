'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:37 pm'!

MethodFilter subclass: #ConstructionProblemFilter
	instanceVariableNames: 'myShortName {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!ConstructionProblemFilter methodsFor: 'creation'!

create: sel {Symbol}

	super create.
	myShortName _ HxxPrintStream mapSelector: sel! !

!ConstructionProblemFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BlockParsingAction create: [:each {ProgramNode} |
		self knownBug. 
		"the use of Object below is totally broken, but where should I get the proper class from?"
		
		self isNodeAProblem: each in: Object]!

{String} label
	
	^myShortName, ' methods with possibly different XTalk/X++ semantics'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	| action {MethodAction} | 
	(HxxPrintStream mapSelector: sel) == myShortName ifFalse:
		[^false].
	action _ self fetchAction. 
	(action parse: (cls sourceCodeStringAt: sel)) properDo: [:each {ProgramNode} |
		(self isNodeAProblem: each in: cls)
			ifTrue: [^true]].
	^false! !

!ConstructionProblemFilter methodsFor: 'private'!

{Boolean} isNodeAProblem: each {ProgramNode} in: cls {Behavior}

	^(each isKindOf: SimpleMessageNode)
		and: [(cls isSelectorOverridden: each selector)
		and: [| rec | rec _ each receiver. (rec isKindOf: VariableNode) 
		and: [rec name = 'self']]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ConstructionProblemFilter class
	instanceVariableNames: ''!



!ConstructionProblemFilter class methodsFor: 'creation'!

make: sel {Symbol}

	^self create: sel! !