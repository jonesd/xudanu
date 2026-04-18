'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:21 pm'!

Object subclass: #ProgramNodeBuilder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Program Objects'!
ProgramNodeBuilder comment:
'Class ProgramNodebuilder represents an object that knows how to construct instances of program nodes.  This class (ProgramBuilder) constructs instances of the generic node classes; other builders may construct instances of specialized subclasses.

Class ProgramNode could serve equally well as a place to define these messages, but we prefer to make builders a full-fledged class hierarchy in their own right so they can conveniently have instance variables, instance creation messages, etc.'!


!ProgramNodeBuilder methodsFor: 'node creation-basic'!

defaultType
	"Return the default type for a parameter"
	^nil!

newAssignmentVariable: var value: val
	^AssignmentNode new variable: var value: val!

newAssignmentVariable: var value: val leftArrow: bool
	^AssignmentNode new variable: var value: val leftArrow: bool!

newBlockArguments: args body: seq
	^BlockNode new arguments: args body: seq!

newCascadeReceiver: rcvr messages: msgs
	^CascadeNode new receiver: rcvr messages: msgs!

newLiteralValue: lit subLiterals: subLiterals {(OrderedCollection of: LiteralNode) default: nil}

	^LiteralNode new value: lit subLiterals: subLiterals!

newMessageReceiver: rcvr selector: sel arguments: args
	^MessageNode new receiver: rcvr selector: sel arguments: args!

newMethodSelector: sel primitive: prim block: block
	^MethodNode new selector: sel primitive: prim block: block!

newMethodSelector: sel primitive: prim block: block type: returnType
	^MethodNode new selector: sel primitive: prim block: block type: returnType!

newParameterVariable: var type: type
	^ParameterNode new variable: var type: type!

newReturnValue: value
	^ReturnNode new value: value!

newSelectorName: sym
	"Selectors are represented by the symbols themselves."
	^sym!

newSequenceTemporaries: temps statements: stats
	^SequenceNode new temporaries: temps statements: stats!

newVariableName: nameString
	^VariableNode new name: nameString! !

!ProgramNodeBuilder methodsFor: 'node creation-composite-data'!

forFalse
	^self newLiteralValue: false!

forNil
	^self newLiteralValue: nil!

forReturnSelf
	^self newReturnValue: self forSelf!

forSelf
	^self newVariableName: 'self'!

forSuper
	^self newVariableName: 'super'!

forTrue
	^self newLiteralValue: true!

newBlockBody: seq
	^self newBlockArguments: #() body: seq!

newParameterVariable: var
	^self newParameterVariable: var type: self defaultType!

newVariable
	^self newVariableName: 'var', Time millisecondClockValue printString! !

!ProgramNodeBuilder methodsFor: 'node creation-composite-messages'!

newMessageReceiver: rcvr selector: sel
	^self newMessageReceiver: rcvr selector: sel arguments: #()!

newMessageReceiver: rcvr selector: sel argument: arg
	^self newMessageReceiver: rcvr selector: sel arguments: (Array with: arg)!

newSelfMessageSelector: sel
	^self newSelfMessageSelector: sel arguments: #()!

newSelfMessageSelector: sel argument: arg
	^self newSelfMessageSelector: sel arguments: (Array with: arg)!

newSelfMessageSelector: sel arguments: args
	^self newMessageReceiver: self forSelf selector: sel arguments: args! !

!ProgramNodeBuilder methodsFor: 'node creation-composite-control'!

newCondition: cond and: conjunct
	^self condition: cond selector: #and: body: conjunct!

newCondition: cond doWhile: boolean
	^self newMessageReceiver: (self newBlockBody: cond)
		selector: (boolean ifTrue: [#whileTrue] ifFalse: [#whileFalse])
		arguments: #()!

newCondition: cond ifFalse: f
	^self condition: cond selector: #ifFalse: body: f!

newCondition: cond ifFalse: f ifTrue: t
	^self condition: cond selector: #ifFalse:ifTrue: body: f body: t!

newCondition: cond ifTrue: t
	^self condition: cond selector: #ifTrue: body: t!

newCondition: cond ifTrue: t ifFalse: f
	^self condition: cond selector: #ifTrue:ifFalse: body: t body: f!

newCondition: cond or: alternative
	^self condition: cond selector: #or: body: alternative!

newCondition: cond while: boolean do: body
	^self condition: (self newBlockBody: cond)
		selector: (boolean ifTrue: [#whileTrue:] ifFalse: [#whileFalse:])
		body: body!

newMethodSelector: sel arguments: args temporaries: temps statements: stats
	^self
		newMethodSelector: sel
		primitive: nil
		block: (self
			newBlockArguments: args
			body: (self
				newSequenceTemporaries: temps
				statements: stats))!

newSequenceStatements: stats
	^self newSequenceTemporaries: #() statements: stats!

newStatements: stats
	^stats size = 1
		ifTrue: [stats first]
		ifFalse: [self newSequenceStatements: stats]! !

!ProgramNodeBuilder methodsFor: 'private: private'!

condition: cond selector: sel body: bod
	^self newMessageReceiver: cond
		selector: sel
		arguments: (Array with: (self newBlockBody: bod))!

condition: cond selector: sel body: bod1 body: bod2
	^self newMessageReceiver: cond
		selector: sel
		arguments: (Array with: (self newBlockBody: bod1) with: (self newBlockBody: bod2))! !

!ProgramNodeBuilder methodsFor: 'smalltalk: defaults'!

newLiteralValue: lit
	
	^self newLiteralValue: lit subLiterals: nil! !