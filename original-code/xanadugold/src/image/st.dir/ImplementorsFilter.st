'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:42 pm'!

MethodFilter subclass: #ImplementorsFilter
	instanceVariableNames: 'mySelector {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!ImplementorsFilter methodsFor: 'creation'!

create: selector {Symbol}
	
	super create.
	mySelector _ selector! !

!ImplementorsFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^ImplementorsAction make: (Array with: (Array with: mySelector with: mySelector))!

{String} label
	
	^'Implementors of ', mySelector!

{BooleanVar} passes: cls {Behavior}
	
	^cls includesSelector: mySelector!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^sel == mySelector!

{String} requestReplacementString

	^self class requestString: 'Selector to replace it with...'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ImplementorsFilter class
	instanceVariableNames: ''!



!ImplementorsFilter class methodsFor: 'creation'!

make: selector {Symbol}

	^self create: selector! !