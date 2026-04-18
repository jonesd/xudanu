'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:43 pm'!

MethodFilter subclass: #ImplementorsMatchFilter
	instanceVariableNames: 'myPattern {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!ImplementorsMatchFilter methodsFor: 'accessing'!

{String} label
	
	^'Implementors matching ''', myPattern, ''''!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^myPattern match: sel!

{String | BlockClosure} pattern
	
	^self fetchFromPattern: myPattern asSymbol keywords first.! !

!ImplementorsMatchFilter methodsFor: 'creation'!

create: pattern {String}
	
	super create.
	myPattern _ pattern! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ImplementorsMatchFilter class
	instanceVariableNames: ''!



!ImplementorsMatchFilter class methodsFor: 'creation'!

make: pattern {String}

	^self create: pattern! !