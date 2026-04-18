'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:37 pm'!

MethodFilter subclass: #FilterLabeller
	instanceVariableNames: '
		myFilter {MethodFilter}
		myLabel {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!FilterLabeller methodsFor: 'creation'!

create: filter {MethodFilter} with: label {String}

	super create.
	myFilter _ filter.
	myLabel _ label! !

!FilterLabeller methodsFor: 'accessing'!

{MethodAction | nil} fetchAction

	^myFilter fetchAction!

{String} label
	
	^myLabel!

{BooleanVar} passes: cls {Behavior} 

	^myFilter passes: cls!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	
	^myFilter passes: cls with: sel with: code! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FilterLabeller class
	instanceVariableNames: ''!



!FilterLabeller class methodsFor: 'creation'!

make: filter {MethodFilter} with: label {String}

	^self create: filter with: label! !