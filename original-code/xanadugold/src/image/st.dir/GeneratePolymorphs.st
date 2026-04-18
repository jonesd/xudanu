'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:41 pm'!

GenerateMethods subclass: #GeneratePolymorphs
	instanceVariableNames: 'myRep {MethodRep}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!GeneratePolymorphs methodsFor: 'creation'!

create: rep {MethodRep}

	super create.
	myRep _ rep.! !

!GeneratePolymorphs methodsFor: 'private:'!

{Behavior} topClass

	^myRep methodClass withAllSuperclasses reverse detect: [:c1 {Behavior} |
		c1 includesSelector: myRep selector]! !

!GeneratePolymorphs methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BlockParsingAction create: [:each {ProgramNode} |
		each isKindOf: MethodNode]!

{String} label
	
	self topClass = myRep methodClass
		ifTrue: [^'Polymorphs of ', myRep methodClass name, '>>', myRep selector].
		
	^'Polymorphs of ', myRep methodClass name, '(', self topClass name, ')>>', myRep selector!

{Collection of: MethodRep} methodReps: filter {MethodFilter}

	| result {Collection of: MethodRep} |
	result _ OrderedCollection new.
	self behaviorsDo: [:cls {Behavior} |
		((filter passes: cls) 
		 and: [filter passes: cls with: myRep selector])
			ifTrue: [result addLast: (MethodRep make: cls with: myRep selector)]].
	^result.!

{BooleanVar} passes: cls {Behavior}
	
	^(cls = self topClass or: [cls inheritsFrom: self topClass])
	 and: [cls includesSelector: myRep selector]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^sel == myRep selector! !

!GeneratePolymorphs methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	self topClass withAllSubclasses do: [:cls {Behavior} |
		(cls includesSelector: myRep selector)
			ifTrue: [aBlock value: cls]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GeneratePolymorphs class
	instanceVariableNames: ''!



!GeneratePolymorphs class methodsFor: 'creation'!

make: rep {MethodRep}
	
	^self create: rep! !

!GeneratePolymorphs class methodsFor: 'examples'!

{NOWAIT} example
	"GeneratePolymorphs example"

	| rep {MethodRep} |
	rep _ MethodRep make: GeneratePolymorphs with: #label.
	(GeneratePolymorphs make: rep) browse: rep.! !