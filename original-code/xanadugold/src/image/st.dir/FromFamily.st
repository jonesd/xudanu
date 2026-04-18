'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:40 pm'!

GenerateMethods subclass: #FromFamily
	instanceVariableNames: 'myClass {Class}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!FromFamily methodsFor: 'accessing'!

{String} label
	
	^myClass name, '''s family'!

{BooleanVar} passes: cls {Behavior}
	
	| c {Class} |
	c _ cls nonMeta.
	^myClass == c 
	 or: [(myClass inheritsFrom: c) 
	 or: [c inheritsFrom: myClass]]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^true! !

!FromFamily methodsFor: 'creation'!

create: cls {Behavior}

	super create.
	myClass _ cls nonMeta! !

!FromFamily methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 
	
	myClass allSuperclasses do: [:cls | 
		aBlock value: cls.
		aBlock value: cls class].
	myClass withAllSubsAndMetasDo: aBlock! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FromFamily class
	instanceVariableNames: ''!



!FromFamily class methodsFor: 'creation'!

make: cls {Behavior}
	"(FromFamily make: FromFamily) browse"
	
	^self create: cls! !