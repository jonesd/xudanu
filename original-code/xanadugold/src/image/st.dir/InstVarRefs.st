'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:44 pm'!

GenerateMethods subclass: #InstVarRefs
	instanceVariableNames: '
		myClass {Behavior}
		myIVName {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!InstVarRefs methodsFor: 'private:'!

{Behavior} topClass

	^myClass withAllSuperclasses reverse detect: [:c1 {Behavior} |
		c1 instVarNames includes: myIVName]! !

!InstVarRefs methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BlockParsingAction create: [:each {ProgramNode} |
		(each isKindOf: VariableNode) and: [each name = myIVName]]!

{String} label
	
	self topClass = myClass
		ifTrue: [^'Users of ', myClass name, '''s ', myIVName].
		
	^'Users of ', myClass name, '(', self topClass name, ')''s ', myIVName!

{Collection of: MethodRep} methodReps: filter {MethodFilter}

	| result {Collection of: MethodRep} instVarIndex {IntegerVar} |
	result _ OrderedCollection new.
	instVarIndex _ self topClass allInstVarNames indexOf: myIVName.
	self behaviorsDo: [:cls {Behavior} |
		(filter passes: cls)
			ifTrue: [cls methodsDo: [:sel {Symbol} :code {CompiledMethod} |
					(((code readsField: instVarIndex) or: [code writesField: instVarIndex]) 
					 and: [filter passes: cls with: sel with: code])
						ifTrue: [result add: (MethodRep make: cls with: sel)]]]].
	^result!

{BooleanVar} passes: cls {Behavior}
	
	^cls = self topClass or: [cls inheritsFrom: self topClass]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	| instVarIndex {IntegerVar} |
	instVarIndex _ self topClass allInstVarNames indexOf: myIVName.
	^(code readsField: instVarIndex) or: [code writesField: instVarIndex]! !

!InstVarRefs methodsFor: 'creation'!

create: cls {Behavior} with: ivName {String}

	super create.
	myClass _ cls.
	myIVName _ ivName.! !

!InstVarRefs methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	self topClass withAllSubclasses do: aBlock! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InstVarRefs class
	instanceVariableNames: ''!



!InstVarRefs class methodsFor: 'creation'!

make: cls {Behavior} with: ivName {String}
	"(InstVarRefs make: Set with: 'tally') browse"
	
	^self create: cls with: ivName! !

!InstVarRefs class methodsFor: 'prompting'!

{Symbol | nil} pickAnInstVariableOf: cls {Behavior} with: generatorBlock {BlockClosure}
	"Show a menu of all instance variables of the specified class and its superclasses."

	| nm {Association | nil} |
	nm _ cls
		showVariableMenu: generatorBlock
		collectWithClass: [ :aClass :cname | | cxx |
			cxx _ aClass fetchCxxClassDescription.
			cxx == nil
				ifTrue: [cname]
				ifFalse: [cname , ' ' , (aClass isMeta
					ifTrue: [cxx classInstVarTypeAt: cname]
					ifFalse: [cxx instVarTypeAt: cname])]].
	^nm! !