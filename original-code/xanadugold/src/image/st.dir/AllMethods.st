'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:32 pm'!

GenerateMethods subclass: #AllMethods
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!AllMethods methodsFor: 'accessing'!

{MethodFilter} intersect: other {MethodFilter}

	^other!

{String} label
	
	^'All Methods'!

{BooleanVar} passes: cls {Behavior} 

	^true!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^true!

{MethodFilter} unionWith: other {MethodFilter}

	^self! !

!AllMethods methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	Smalltalk allBehaviorsDo: aBlock! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AllMethods class
	instanceVariableNames: ''!



!AllMethods class methodsFor: 'creation'!

make

	^self create! !