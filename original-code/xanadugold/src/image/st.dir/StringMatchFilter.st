'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:52 pm'!

MethodFilter subclass: #StringMatchFilter
	instanceVariableNames: 'myPattern {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!StringMatchFilter methodsFor: 'creation'!

create: pattern {String}

	super create.
	myPattern _ pattern! !

!StringMatchFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^MatchingAction create: myPattern!

{String} label
	
	^'matches ''', myPattern, ''''.!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^('*', myPattern, '*') match: (cls sourceCodeStringAt: sel)
		ignoreCase: true!

{String} requestReplacementString

	^self class requestString: 'Pattern to replace it with...'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StringMatchFilter class
	instanceVariableNames: ''!



!StringMatchFilter class methodsFor: 'creation'!

make: pattern {String}

	^self create: pattern! !