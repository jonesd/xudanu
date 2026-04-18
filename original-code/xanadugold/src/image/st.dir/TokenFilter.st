'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:53 pm'!

MethodFilter subclass: #TokenFilter
	instanceVariableNames: 'myToken {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!TokenFilter methodsFor: 'creation'!

create: token {String}

	super create.
	myToken _ token! !

!TokenFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^LexingAction create: myToken!

{String} label
	
	^'token ''', myToken, ''''.!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^((cls sourceCodeStringAt: sel) findToken: myToken startingAt: 1) ~= 0! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TokenFilter class
	instanceVariableNames: ''!



!TokenFilter class methodsFor: 'creation'!

make: token {String}

	^self create: token! !