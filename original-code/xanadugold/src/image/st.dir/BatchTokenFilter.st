'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:33 pm'!

MethodFilter subclass: #BatchTokenFilter
	instanceVariableNames: 'myChangeTable {Dictionary of: Symbol with: Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!BatchTokenFilter methodsFor: 'creation'!

create: renames {Dictionary of: Symbol with: Symbol}

	super create.
	myChangeTable := renames! !

!BatchTokenFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BatchLexingAction create: myChangeTable!

{String} label
	
	^'Batch Token Renamer'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^((cls sourceCodeStringAt: sel) 
		findToken: [:tok {String} |
			myChangeTable includesKey: tok asSymbol] 
		separators: String defaultTokenTable
		starting: 1) ~= 0! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BatchTokenFilter class
	instanceVariableNames: ''!



!BatchTokenFilter class methodsFor: 'creation'!

make: renames {Dictionary of: Symbol with: Symbol}

	^self create: renames! !