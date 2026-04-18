'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:47 pm'!

MethodFilter subclass: #NegativeFilter
	instanceVariableNames: 'myFilter {MethodFilter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!NegativeFilter methodsFor: 'creation'!

create: filter {MethodFilter}

	super create.
	myFilter _ filter! !

!NegativeFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^nil!

{String} label
	
	^'Not found by ', myFilter label!

{MethodFilter} not

	^myFilter!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^((myFilter passes: cls) and: [myFilter passes: cls with: sel with: code]) not! !