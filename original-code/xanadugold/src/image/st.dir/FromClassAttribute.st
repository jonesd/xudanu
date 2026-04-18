'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:39 pm'!

GenerateMethods subclass: #FromClassAttribute
	instanceVariableNames: 'myAttribute {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!FromClassAttribute methodsFor: 'creation'!

create: attribute {Symbol}

	super create.
	myAttribute := attribute! !

!FromClassAttribute methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	Smalltalk allBehaviorsDo: [:cls {Behavior} |
		(cls hasAttribute: myAttribute)
			ifTrue: [aBlock value: cls]]! !

!FromClassAttribute methodsFor: 'accessing'!

{String} label
	
	^'From class attribute ', myAttribute!

{BooleanVar} passes: cls {Behavior} 

	^cls hasAttribute: myAttribute!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FromClassAttribute class
	instanceVariableNames: ''!



!FromClassAttribute class methodsFor: 'creation'!

make: attribute {Symbol}

	^self create: attribute! !