'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:18 pm'!

SimpleMessageNode subclass: #MessageNode
	instanceVariableNames: 'expanded expansion '
	classVariableNames: 'MacroSelectors '
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
MessageNode comment:
'Class MessageNode represents a message appearing in source code - possibly to be expanded for code generation.

Instance Variables:
	expanded	<Boolean | nil>  nil means haven''t checked yet
	expansion	<nil | ValueNode>

Class Variables:
	MacroSelectors 	<IdentityDictionary> special messages in-lined by the compiler
'!


!MessageNode methodsFor: 'initialize-release'!

receiver: rcvr selector: sel arguments: args
	super receiver: rcvr selector: sel arguments: args.
	expanded _ false! !

!MessageNode methodsFor: 'code generation'!

emitBranch: codeStream to: label if: boolean
	self isExpanded
		ifTrue: [expansion emitBranch: codeStream to: label if: boolean]
		ifFalse: [super emitBranch: codeStream to: label if: boolean]!

emitEffect: codeStream
	self isExpanded
		ifTrue: [expansion emitEffect: codeStream]
		ifFalse: [super emitEffect: codeStream]!

emitLocalReturn: codeStream from: bodyNode
	self isExpanded
		ifTrue: [expansion emitLocalReturn: codeStream from: bodyNode]
		ifFalse: [super emitLocalReturn: codeStream from: bodyNode]!

emitReturn: codeStream from: returnNode
	self isExpanded
		ifTrue: [expansion emitReturn: codeStream from: returnNode]
		ifFalse: [super emitReturn: codeStream from: returnNode]!

emitSend: codeStream selector: sel arguments: args
	self isExpanded
		ifTrue: [expansion emitSend: codeStream selector: sel arguments: args]
		ifFalse: [super emitSend: codeStream selector: sel arguments: args]!

emitValue: codeStream
	self isExpanded
		ifTrue: [expansion emitValue: codeStream]
		ifFalse: [super emitValue: codeStream]! !

!MessageNode methodsFor: 'transforming'!

transformAlmostToByDo
	^((arguments last isBlockWithNumArgs: 1) and: [(arguments at: 2) numberValue notNil])
		ifTrue: [arguments last
				arithmeticLoopFrom: receiver
				by: (arguments at: 2)
				almostTo: arguments first]
		ifFalse: [nil]!

transformAlmostToDo
	^(arguments last isBlockWithNumArgs: 1)
		ifTrue: [arguments last
				arithmeticLoopFrom: receiver
				by: (LiteralNode new value: 1)
				almostTo: arguments first]
		ifFalse: [nil]!

transformAnd
	^(arguments first isBlockWithNumArgs: 0)
		ifTrue: [self makeIfTrue: arguments first ifFalse: (BlockNode new body: (LiteralNode new value: false))]
		ifFalse: [nil]!

transformDownToDo
	^(arguments last isBlockWithNumArgs: 1)
		ifTrue: [arguments last
				arithmeticLoopFrom: receiver
				by: (LiteralNode new value: (1 negated))
				to: arguments first]
		ifFalse: [nil]!

transformForEach
	^(arguments first isBlockWithNumArgs: 1)
		ifTrue: [arguments first forEachLoopFrom: receiver]
		ifFalse: [nil]!

transformForKeyValues
	^(arguments first isBlockWithNumArgs: 2)
		ifTrue: [arguments first forKeyValuesLoopFrom: receiver]
		ifFalse: [nil]!

transformIfFalse
	^(arguments first isBlockWithNumArgs: 0)
		ifTrue: [self makeIfTrue: (BlockNode new body: (LiteralNode new value: nil)) ifFalse: arguments first]
		ifFalse: [nil]!

transformIfFalseIfTrue
	^((arguments first isBlockWithNumArgs: 0) and: [arguments last isBlockWithNumArgs: 0])
		ifTrue: [self makeIfTrue: arguments last ifFalse: arguments first]
		ifFalse: [nil]!

transformIfTrue
	^(arguments first isBlockWithNumArgs: 0)
		ifTrue: [self makeIfTrue: arguments first ifFalse: (BlockNode new body: (LiteralNode new value: nil))]
		ifFalse: [nil]!

transformIfTrueIfFalse
	^((arguments first isBlockWithNumArgs: 0) and: [arguments last isBlockWithNumArgs: 0])
		ifTrue: [self makeIfTrue: arguments first ifFalse: arguments last]
		ifFalse: [nil]!

transformOr
	^(arguments first isBlockWithNumArgs: 0)
		ifTrue: [self makeIfTrue: (BlockNode new body: (LiteralNode new value: true)) ifFalse: arguments first]
		ifFalse: [nil]!

transformRepeat
	^(receiver isBlockWithNumArgs: 0)
		ifTrue:
			[self
				makeWhile: (BlockNode new body: (LiteralNode new value: true))
				negated: false
				do: receiver]
		ifFalse: [nil]!

transformTimesRepeat
	^(arguments last isBlockWithNumArgs: 0)
		ifTrue: [^ArithmeticLoopNode new
				variable: (VariableNode new name: 'Counting_Var')
				initialValue: (LiteralNode new value: 1)
				increment: (LiteralNode new value: 1)
				limit: receiver
				body: arguments last body]
		ifFalse: [nil]!

transformToByDo
	^((arguments last isBlockWithNumArgs: 1) and: [(arguments at: 2) numberValue notNil])
		ifTrue: [arguments last
				arithmeticLoopFrom: receiver
				by: (arguments at: 2)
				to: arguments first]
		ifFalse: [nil]!

transformToDo
	^(arguments last isBlockWithNumArgs: 1)
		ifTrue: [arguments last
				arithmeticLoopFrom: receiver
				by: (LiteralNode new value: 1)
				to: arguments first]
		ifFalse: [nil]!

transformWhileFalse
	^(receiver isBlockWithNumArgs: 0)
		ifTrue:
			[self
				makeWhile: receiver
				negated: true
				do: (BlockNode new body: (SequenceNode new statements: #()))]
		ifFalse: [nil]!

transformWhileFalseDo
	^((receiver isBlockWithNumArgs: 0)
	  and: [arguments first isBlockWithNumArgs: 0])
		ifTrue:
			[self
				makeWhile: receiver
				negated: true
				do: arguments first]
		ifFalse: [nil]!

transformWhileTrue
	^(receiver isBlockWithNumArgs: 0)
		ifTrue:
			[self
				makeWhile: receiver
				negated: false
				do: (BlockNode new body: (SequenceNode new statements: #()))]
		ifFalse: [nil]!

transformWhileTrueDo
	^((receiver isBlockWithNumArgs: 0)
	  and: [arguments first isBlockWithNumArgs: 0])
		ifTrue:
			[self
				makeWhile: receiver
				negated: false
				do: arguments first]
		ifFalse: [nil]! !

!MessageNode methodsFor: 'private: private'!

isExpanded
	expanded ifFalse:
		[expanded _ true.
		expansion _ self perform: (MacroSelectors at: selector ifAbsent: [expansion _ nil.  ^false])].
	^expansion notNil!

makeIfTrue: trueBlock ifFalse: falseBlock
	^ConditionalNode new
		condition: receiver
		trueBlock: trueBlock
		falseBlock: falseBlock!

makeWhile: condBlock negated: neg do: bodyBlock
	^LoopNode new
		condition: condBlock
		negated: neg
		body: bodyBlock! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MessageNode class
	instanceVariableNames: ''!


!MessageNode class methodsFor: 'class initialization'!

initialize
	"MessageNode initialize. "
	| mac |
	mac _ IdentityDictionary new: 32.
		#(	ifTrue: ifFalse:
			ifTrue:ifFalse: ifFalse:ifTrue:
			and: or:
			whileFalse: whileTrue:
			whileFalse whileTrue
			repeat
			to:do: to:by:do: almostTo:do: almostTo:by:do: timesRepeat:
			downTo:do:
			forEach: forKeyValues: forPositions:)
	with:
		#(	transformIfTrue transformIfFalse
			transformIfTrueIfFalse transformIfFalseIfTrue
			transformAnd transformOr
			transformWhileFalseDo transformWhileTrueDo
			transformWhileFalse transformWhileTrue
			transformRepeat
			transformToDo transformToByDo transformAlmostToDo transformAlmostToByDo transformTimesRepeat
			transformDownToDo
			transformForEach transformForKeyValues transformForKeyValues)
	do:
		[:selector :message | mac at: selector put: message].
	MacroSelectors _ mac! !

MessageNode initialize!
