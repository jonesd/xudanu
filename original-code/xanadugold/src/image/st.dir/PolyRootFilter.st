'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:49 pm'!

MethodFilter subclass: #PolyRootFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!PolyRootFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	^BlockParsingAction create: [:each {ProgramNode} |
		each isKindOf: MethodNode]!

{String} label
	
	^'Root Polymorphs'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod} 
	
	cls isMeta
		ifTrue: [^true].
	cls allSuperclasses reverse
		detect: [:c1 {Behavior} | 
			c1 includesSelector: sel]
		ifNone: [^true].
	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PolyRootFilter class
	instanceVariableNames: ''!



!PolyRootFilter class methodsFor: 'creation'!

make

	^self create! !