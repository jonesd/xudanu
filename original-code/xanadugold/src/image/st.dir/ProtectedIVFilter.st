'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:49 pm'!

MethodFilter subclass: #ProtectedIVFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!ProtectedIVFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^nil!

{String} label
	
	^'Methods which access non-local inst vars'!

{BooleanVar} passes: cls {Behavior}
	
	^cls isMeta not!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}

	| ivNames {Set of: String} ivsTouched {Set of: String} |
	ivNames _ cls instVarNames.
	ivsTouched _ cls instVarNamesTouchedBy: sel.
	^(ivsTouched detect: [:ivName {String} | (ivNames includes: ivName) not]
			ifNone: [nil])
		~~ nil! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ProtectedIVFilter class
	instanceVariableNames: ''!



!ProtectedIVFilter class methodsFor: 'creation'!

make

	^self create! !