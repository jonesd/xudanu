'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:36 pm'!

MethodFilter subclass: #CodeTransformerFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!CodeTransformerFilter methodsFor: 'accessing'!

{String} label
	
	^'Code Transformer'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	
	| changed source i token |
	changed := false.
	source := cls sourceCodeAt: sel.
	i := 0.
	[(i := source indexOfSubCollection: 'ID key: ''' startingAt: i + 1) > 0]
		whileTrue:
			[token := ((source copyFrom: i + 9 to: source size) copyUpTo: $') asSymbol.
			((Smalltalk at: token ifAbsent: [Object]) isEqualOrSubclassOf: Waldo) ifTrue:
				[changed := true.
				source := source copyReplaceFrom: i
					to: i + 9 + token size
					with: 'PackOBits make: ''' , token , '''']].
	changed ifTrue:
		[cls compile: source
			classified: (cls organization categoryOfElement: sel)].
	^false!

{String} pattern
	
	^nil! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CodeTransformerFilter class
	instanceVariableNames: ''!



!CodeTransformerFilter class methodsFor: 'creation'!

make
	^self create! !