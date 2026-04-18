'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:34 pm'!

MethodFilter subclass: #ChangedFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!ChangedFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^nil!

{String} label
	
	^'Changed since baseline'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^ChangeLog hasChangesFor: sel in: cls! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ChangedFilter class
	instanceVariableNames: ''!



!ChangedFilter class methodsFor: 'creation'!

make
	
	^self create! !