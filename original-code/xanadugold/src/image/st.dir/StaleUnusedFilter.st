'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:52 pm'!

MethodFilter subclass: #StaleUnusedFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!StaleUnusedFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^nil!

{String} label
	
	^'Probably unused'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^(MessageUsage stale isUsed: sel) not! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StaleUnusedFilter class
	instanceVariableNames: ''!



!StaleUnusedFilter class methodsFor: 'creation'!

make

	^self create! !