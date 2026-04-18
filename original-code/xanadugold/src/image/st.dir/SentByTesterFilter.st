'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:51 pm'!

MethodFilter subclass: #SentByTesterFilter
	instanceVariableNames: '
		myModuleCache {CxxModule | nil}
		myTestedSelectorsCache {(Set of: Symbol)
	| nil}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!SentByTesterFilter methodsFor: 'creation'!

create
	
	super create.
	myModuleCache _ nil.
	myTestedSelectorsCache _ nil! !

!SentByTesterFilter methodsFor: 'private:'!

{BooleanVar} doTestersOf: mod {CxxModule} send: sel {Symbol}

	mod ~= myModuleCache
		ifTrue: [self updateCache: mod].
	^myTestedSelectorsCache includes: sel!

{void} updateCache: mod {CxxModule}

	myModuleCache _ nil.
	myTestedSelectorsCache _ IdentitySet new.
	mod testClasses do: [:cxc {CxxClassDescription} |
		(Array with: cxc classDescription with: cxc classDescription class) do: [:b {Behavior} |
			b selectorsDo: [:sel {Symbol} |
				myTestedSelectorsCache addAll: (b compiledMethodAt: sel) messages]]].
	myModuleCache _ mod! !

!SentByTesterFilter methodsFor: 'accessing'!

{String} label
	
	^'Sent by their Module''s Testers'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	| cxc {CxxClassDescription | nil} mod {CxxModule | nil} |
	cxc _ cls fetchCxxClassDescription.
	(cxc == nil or: [(mod _ cxc fetchCxxModule) == nil])
		ifTrue: [^false]
		ifFalse: [^self doTestersOf: mod send: sel]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SentByTesterFilter class
	instanceVariableNames: ''!



!SentByTesterFilter class methodsFor: 'creation'!

make

	^self create! !