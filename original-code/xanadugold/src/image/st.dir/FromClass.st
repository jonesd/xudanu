'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:38 pm'!

GenerateMethods subclass: #FromClass
	instanceVariableNames: 'myClass {Class}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!FromClass methodsFor: 'creation'!

create: cls {Behavior}

	super create.
	myClass _ cls nonMeta! !

!FromClass methodsFor: 'accessing'!

{String} label
	
	^myClass name!

{BooleanVar} passes: cls {Behavior}
	
	^myClass == cls nonMeta!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^true! !

!FromClass methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 
	
	aBlock value: myClass.
	aBlock value: myClass class! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FromClass class
	instanceVariableNames: ''!



!FromClass class methodsFor: 'creation'!

make: cls {Behavior}
	"(FromClass make: FromClass) browse"
	
	^self create: cls! !