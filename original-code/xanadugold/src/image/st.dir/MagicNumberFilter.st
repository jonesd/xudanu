'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:44 pm'!

MethodFilter subclass: #MagicNumberFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!MagicNumberFilter methodsFor: 'creation'!

create

	super create! !

!MagicNumberFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BlockParsingAction create: [:each {ProgramNode} |
		(each isKindOf: LiteralNode) 
		 and: [(each value isKindOf: Number) 
		 and: [(#(-1 0 1) includes: each value) not]]]!

{String} label
	
	^'Users of a magic number'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	code allLiteralsDo: [:lit |
		((lit isKindOf: Number) and: [(#(-1 0 1) includes: lit) not])
			ifTrue: [^true]].
	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MagicNumberFilter class
	instanceVariableNames: ''!



!MagicNumberFilter class methodsFor: 'creation'!

make

	^self create! !

!MagicNumberFilter class methodsFor: 'examples'!

example1
	"((FromCategory make: #'Tools-Browser-Methods') filteredBy: MagicNumberFilter make) browse"
	"MagicNumberFilter class compiledMethodAt: #example1"

	^400 + 50000000!

example2
	"((FromCategory make: #'Tools-Browser-Methods') filteredBy: MagicNumberFilter make) browse"
	"MagicNumberFilter class compiledMethodAt: #example2"
	
	^#(foo 40 bar 5000000)! !