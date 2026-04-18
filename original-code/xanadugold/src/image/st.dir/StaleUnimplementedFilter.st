'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:52 pm'!

MethodFilter subclass: #StaleUnimplementedFilter
	instanceVariableNames: 'myLiteralsTooFlag {Boolean}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!StaleUnimplementedFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction
	
	| mu {MessageUsage} |
	mu _ MessageUsage stale.
	^BlockParsingAction create: [:each {ProgramNode} |
		| sel {Symbol} |
		each 
			cast: SimpleMessageNode into: [:e | sel _ e selector]
			cast: LiteralNode into: [:e | 
				sel _ e value.
				(myLiteralsTooFlag and: [sel isKindOf: Symbol]) ifFalse:
					[sel := nil]]
			others: [sel _ nil].
		sel ~~ nil and: [(mu isImplemented: sel) not]]!

{String} label
	
	^'Probably unimplemented requests'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}

	| mu {MessageUsage} |
	mu _ MessageUsage stale.
	code messages do: [:sent {Symbol} |
		(mu isImplemented: sent) 
			ifFalse: [^true]].
	myLiteralsTooFlag ifTrue:
		[code literalSymbols do: [:sym {Symbol} |
			(mu isImplemented: sym) 
				ifFalse: [^true]]].
	^false! !

!StaleUnimplementedFilter methodsFor: 'creation'!

create: flag {Boolean}

	super create.
	myLiteralsTooFlag := flag! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StaleUnimplementedFilter class
	instanceVariableNames: ''!



!StaleUnimplementedFilter class methodsFor: 'creation'!

make: flag {Boolean default: false}

	^self create: flag! !

!StaleUnimplementedFilter class methodsFor: 'smalltalk: defaults'!

make

	^self make: false! !