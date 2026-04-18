'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:50 pm'!

MethodFilter subclass: #Replacer
	instanceVariableNames: '
		myFilter {MethodFilter}
		myActionBlock {BlockClosure of: MethodAction | nil}
		myLabel {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!Replacer methodsFor: 'creation'!

create: filter {MethodFilter} 
	with: actionBlock {BlockClosure of: MethodAction | nil}
	with: label {String}

	super create.
	myFilter _ filter.
	myActionBlock _ actionBlock.
	myLabel _ label! !

!Replacer methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^myActionBlock value!

{String} label
	
	^myLabel!

{BooleanVar} passes: cls {Behavior} 

	^myFilter passes: cls!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	
	^myFilter passes: cls with: sel with: code! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Replacer class
	instanceVariableNames: ''!



!Replacer class methodsFor: 'creation'!

make: filter {MethodFilter} 
	with: actionBlock {BlockClosure of: MethodAction | nil}
	with: label {String}

	^self create: filter with: actionBlock with: label! !