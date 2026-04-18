'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:40 pm'!

GenerateMethods subclass: #FromProtocol
	instanceVariableNames: '
		myClass {Behavior}
		myProtocol {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!FromProtocol methodsFor: 'creation'!

create: cls {Behavior} with: protocol {Symbol}

	super create.
	myClass _ cls.
	myProtocol _ protocol! !

!FromProtocol methodsFor: 'accessing'!

{String} label
	
	^myProtocol, ' of ', myClass name!

{Collection of: MethodRep} methodReps: filter {MethodFilter}

	| result {Collection of: MethodRep} |
	result _ OrderedCollection new.
	(filter passes: myClass)
		ifTrue: [(myClass organization listAtCategoryNamed: myProtocol) 
				do: [:sel {Symbol} |
					(filter passes: myClass with: sel)
						ifTrue: [result add: (MethodRep make: myClass with: sel)]]].
	^result!

{BooleanVar} passes: cls {Behavior}
	
	^cls = myClass!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	 
	^(cls organization listAtCategoryNamed: myProtocol) includes: sel! !

!FromProtocol methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	self doesntNeedToBeImplemented! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FromProtocol class
	instanceVariableNames: ''!



!FromProtocol class methodsFor: 'creation'!

make: cls {Behavior} with: protocol {Symbol}

	^self create: cls with: protocol! !