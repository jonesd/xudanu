'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:43 pm'!

GenerateMethods subclass: #InstVarAssignments
	instanceVariableNames: '
		myClass {Behavior}
		myIVName {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!InstVarAssignments methodsFor: 'creation'!

create: cls {Behavior} with: ivName {String}

	super create.
	myClass _ cls.
	myIVName _ ivName.! !

!InstVarAssignments methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BlockParsingAction create: [:each {ProgramNode} |
		| var {VariableNode} |
		(each isKindOf: AssignmentNode) 
		 and: [((var _ each variable) isKindOf: VariableNode) 
		 and: [var name = myIVName]]]!

{String} label
	
	self topClass = myClass
		ifTrue: [^'Setters of ', myClass name, '''s ', myIVName].
		
	^'Setters of ', myClass name, '(', self topClass name, ')''s ', myIVName!

{Collection of: MethodRep} methodReps: filter {MethodFilter}

	| result {Collection of: MethodRep} instVarIndex {IntegerVar} |
	result _ OrderedCollection new.
	instVarIndex _ self topClass allInstVarNames indexOf: myIVName.
	self behaviorsDo: [:cls {Behavior} |
		(filter passes: cls)
			ifTrue: [cls methodsDo: [:sel {Symbol} :code {CompiledMethod} |
					((code writesField: instVarIndex) 
					 and: [filter passes: cls with: sel with: code])
						ifTrue: [result add: (MethodRep make: cls with: sel)]]]].
	^result!

{BooleanVar} passes: cls {Behavior}
	
	^cls = self topClass or: [cls inheritsFrom: self topClass]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	| instVarIndex {IntegerVar} |
	instVarIndex _ self topClass allInstVarNames indexOf: myIVName.
	^code writesField: instVarIndex! !

!InstVarAssignments methodsFor: 'private:'!

{Behavior} topClass

	^myClass withAllSuperclasses reverse detect: [:c1 {Behavior} |
		c1 instVarNames includes: myIVName]! !

!InstVarAssignments methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	self topClass withAllSubclasses do: aBlock! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InstVarAssignments class
	instanceVariableNames: ''!



!InstVarAssignments class methodsFor: 'creation'!

make: cls {Behavior} with: ivName {String}
	"(InstVarAssignments make: Set with: 'tally') browse"
	
	^self create: cls with: ivName! !