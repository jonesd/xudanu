'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:35 pm'!

GenerateMethods subclass: #ClassVarRefs
	instanceVariableNames: '
		myClass {Class}
		myCVName {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!ClassVarRefs methodsFor: 'creation'!

create: cls {Behavior} with: cvName {Symbol}

	super create.
	myClass _ cls nonMeta.
	myCVName _ cvName.! !

!ClassVarRefs methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BlockParsingAction create: [:each {ProgramNode} |
		(each isKindOf: VariableNode) and: [each name = myCVName]]!

{String} label
	
	self topClass = myClass
		ifTrue: [^'Users of ', myClass name, '''s class var ', myCVName].
		
	^'Users of ', myClass name, '(', self topClass name, ')''s class var ', myCVName!

{Collection of: MethodRep} methodReps: filter {MethodFilter}

	| result {Collection of: MethodRep} assoc {Association} |
	result _ OrderedCollection new.
	assoc _ self topClass classPool associationAt: myCVName.
	self behaviorsDo: [:cls {Behavior} |
		(filter passes: cls)
			ifTrue: [cls methodsDo: [:sel {Symbol} :code {CompiledMethod} |
					((code refersToLiteral: assoc) 
					 and: [filter passes: cls with: sel with: code])
							ifTrue: [result add: (MethodRep make: cls with: sel)]]]].
	^result!

{BooleanVar} passes: cls {Behavior} 

	^cls nonMeta = self topClass or: [cls nonMeta inheritsFrom: self topClass]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	| assoc {Association} |
	assoc _ self topClass classPool associationAt: myCVName.
	^code refersToLiteral: assoc! !

!ClassVarRefs methodsFor: 'private:'!

{Class} topClass

	^myClass withAllSuperclasses reverse detect: [:c1 {Class} |
		c1 classPool includesKey: myCVName]! !

!ClassVarRefs methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	self topClass withAllSubclasses do: aBlock.
	self topClass class withAllSubclasses do: aBlock! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClassVarRefs class
	instanceVariableNames: ''!



!ClassVarRefs class methodsFor: 'creation'!

make: cls {Behavior} with: cvName {Symbol}
	"(ClassVarRefs make: Tester with: #Testers) browse"
	
	^self create: cls with: cvName! !

!ClassVarRefs class methodsFor: 'prompting'!

{Symbol | nil} pickAClassVariableOf: cls {Behavior}
	"Show a menu of all class variables of the specified class and its superclasses."

	| association {Association | nil} |
	association _ cls
		showVariableMenu: [:aClass | aClass classPool associations asSortedCollection]
		collectWithClass: [ :aClass :assoc | | cxx |
			cxx _ aClass fetchCxxClassDescription.
			cxx == nil
				ifTrue: [assoc key]
				ifFalse: [assoc key , ' ' , (cxx classVarTypeAt: assoc key)]].
	association == nil 
		ifTrue: [^nil].
	^association key! !