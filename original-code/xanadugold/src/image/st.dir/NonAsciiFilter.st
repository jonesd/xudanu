'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:47 pm'!

MethodFilter subclass: #NonAsciiFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!

(NonAsciiFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NonAsciiFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^nil!

{String} label
	
	^'contains non-ascii characters'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	(cls sourceCodeStringAt: sel) do: [:c {Character} |
		c asciiValue > 127 ifTrue:
			[^true]].
	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NonAsciiFilter class
	instanceVariableNames: ''!

(NonAsciiFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NonAsciiFilter class methodsFor: 'creation'!

make

	^self create! !