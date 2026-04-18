'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:53 pm'!

MethodFilter subclass: #UndeclaredFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!UndeclaredFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^nil!

{String} label
	
	^'Users of an Undeclared symbol (try recompiling)'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^(code literals 
		detect: [:lit {Symbol | Association | Array} |
					Undeclared includesAssociation: lit]
		ifNone: [nil]) ~~ nil! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UndeclaredFilter class
	instanceVariableNames: ''!



!UndeclaredFilter class methodsFor: 'creation'!

make

	^self create! !