'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:51 pm'!

MethodFilter subclass: #SmalltalkVProblemFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!
SmalltalkVProblemFilter comment:
'Looks for code that is not compatible with Smalltalk/V'!



!SmalltalkVProblemFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction

	| names duplicates |
	^BlockParsingAction create: [:each {ProgramNode} |
		(each isKindOf: MethodNode)
			ifTrue: [names := IdentitySet new.
					duplicates := IdentitySet new.
					each properDo: [:node |
						| name |
						(name := self fetchName: node) ~~ nil ifTrue:
							[(names includes: name)
								ifTrue: [duplicates add: name]
								ifFalse: [names add: name]]].
					false]
			ifFalse: [| name |
					((name := self fetchName: each) ~~ nil and: [duplicates includes: name])]]!

{String} label
	
	^'Incompatible with Smalltalk/V'!

{BooleanVar} passes: cls {Behavior} with: meth {Symbol} with: code {CompiledMethod}

	| node names name |
	node := SmalltalkCompiler parse: (cls sourceCodeAt: meth) class: cls.
	names := IdentitySet new.
	node do: [ :each |
		(name := self fetchName: each) ~~ nil ifTrue:
			[(names includes: name) ifTrue:
				[^true].
			names add: name]].
	^false! !

!SmalltalkVProblemFilter methodsFor: 'private: private'!

{Symbol | nil} fetchName: node {ParseNode}
	"The name of the variable if the parse node represents a variable with a type"
	(node isKindOf: ParameterNode)
		ifTrue: [^node variable name asSymbol]
		ifFalse: [^nil]! !

!SmalltalkVProblemFilter methodsFor: 'smalltalk: passe'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SmalltalkVProblemFilter class
	instanceVariableNames: ''!



!SmalltalkVProblemFilter class methodsFor: 'create'!

make
	^self create! !

!SmalltalkVProblemFilter class methodsFor: 'testing'!

badMethod

	#(1 2 3) do: [ :a | | b c | ].
	#(x y z) do: [ :x | | a b | ].! !