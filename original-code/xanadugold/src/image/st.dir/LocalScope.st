'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:25 pm'!

NameScope subclass: #LocalScope
	instanceVariableNames: 'variables nesting variableList '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Names and Scopes'!
LocalScope comment:
'I represent a non-static name scope -- instance variables (of a class or class hierarchy) or local (argument / temporary, of a method or block).

Instance variables:
	variables	<IdentityDictionary | nil>  "name string -> VariableDefinition"
	nesting	<Integer>  "depth of nesting in blocks"
	variableList	<OrderedCollection | nil>  "name strings in order"
'!


!LocalScope methodsFor: 'initialize-release'!

addCopied: name
	| var |
	var _ LocalVariable new.  "should be CopiedVariable?"
	var scope: nesting index: variableList size from: nil.
	variables at: name put: var.
	variableList addLast: name.
	^var!

addRemote: contextNode in: ctxt
	"Record remote temporaries (bound in a
	context supplied as an argument when
	evaluating an expression)."

	| temps |
	variables == nil ifTrue: [self initVariables].
	temps _ ctxt tempNames.
	1 to: temps size do:
		[:i | variables at: (temps at: i)
			put: (RemoteVariable new contextNode: contextNode index: i)]!

arguments: args startingAt: startIndex from: codeStream
	"Record arguments in a local variable dictionary.
	If any variable is redeclared, send the message
	codeStream redeclaredArg: argNode.
	If the result of sending this message is true,
	redeclare the variable, otherwise ignore the
	redeclaration."
	| index name var |
	index _ startIndex.
	variables == nil ifTrue: [self initVariables].
	args do: [:arg |
		name _ arg name.
		((self variableAt: name from: arg) == nil or: [codeStream redeclaredArg: arg])
			ifTrue:
				[var _ ArgumentVariable new scope: nesting index: index from: arg.
				variables at: name put: var.
				variableList addLast: name.
				index _ index + 1]].
	^index!

generateNames: count
	"Generate a collection of unique temporary names,
	but do not bind them.  The client is responsible for
	calling addTemporaries: to actually bind the variables.
	Note that the names generated here are not
	syntactically legal: this is deliberate, so they can be
	hidden by the debugger."
	| name index |
	index _ variables size.
	^(1 to: count) collect:
		[:i |
		[index _ index + 1.
		name _ '.t', nesting printString, 'i', index printString.
		(self variableAt: name from: nil) notNil]
			whileTrue.
		name]!

initialize
	"Initialize the instance"
	variables _ nil.
	nesting _ 0!

instanceVariables: vars startingAt: startIndex
	"Record instance variables in a local variable dictionary.
	We know there cannot be any name conflicts,
	since this is checked when the class is defined."
	| index |
	index _ startIndex.
	variables == nil ifTrue: [self initVariables].
	vars do: [:var |
		variables at: var name put: (InstanceVariable new scope: nesting index: index).
		index _ index + 1].
	^index!

leaveScope: codeStream between: minIndex and: maxIndex remove: removeFlag
	| rem |
	removeFlag
		ifTrue:
			[rem _ OrderedCollection new.
			variables associationsDo: [:var | (var value leaveScope: codeStream between: minIndex and: maxIndex) ifTrue: [rem add: var key]].
			rem do: [:name | variables removeKey: name]]
		ifFalse:
			[variables do: [:def | def leaveScope: codeStream between: minIndex and: maxIndex]]!

newBlockScope
	"Make an appropriate scope
	for an inner block."
	| inner |
	inner _ self class new.
	inner outerScope: self.
	inner setLevel: nesting + 1.
	^inner!

pseudoVariable: sym
	variables == nil ifTrue: [self initVariables].
	variables at: sym put: (PseudoVariable new scope: nesting name: sym)!

receiverName: name withSuper: superFlag
	"For the method scope, or block scopes that
	can name their receiver (not in the language right now)."
	| var |
	variables == nil ifTrue: [self initVariables].
	var _ ReceiverVariable new scope: nesting.
	variables at: name put: var.
	superFlag ifTrue: [variables at: 'super' put: var]!

temporaries: temps startingAt: startIndex from: codeStream
	"Record temporaries in a local variable dictionary.
	If any variable is redeclared, send the message
	codeStream redeclaredTemp: tempNode.
	If the result of sending this message is true,
	redeclare the variable, otherwise ignore the
	redeclaration."
	| index name var |
	index _ startIndex.
	variables == nil ifTrue: [self initVariables].
	temps do: [:temp |
		name _ temp name.
		((self variableAt: name from: temp) == nil or: [codeStream redeclaredTemp: temp])
			ifTrue:
				[var _ TemporaryVariable new scope: nesting index: index from: temp.
				variables at: name put: var.
				variableList addLast: name.
				index _ index + 1]].
	^index! !

!LocalScope methodsFor: 'accessing'!

variableAt: name from: varNode
	^variables at: name ifAbsent: [outerScope variableAt: name from: varNode]! !

!LocalScope methodsFor: 'accessing-debugger'!

localTempNames
	"Answer the local variable names
	in this scope."

	^variables == nil
		ifTrue: [#()]
		ifFalse: [variableList]!

tempNames
	"This LocalScope is in a chain containing only
	LocalScopes.  Answer the concatenation of
	all the local variable names."

	| names |
	nesting = 0
		ifTrue: [names _ OrderedCollection new]
		ifFalse: [names _ outerScope tempNames].
	variables == nil ifFalse: [names addAll: variableList].
	^names! !

!LocalScope methodsFor: 'enumerating'!

associationsDo: aBlock
	variables associationsDo: aBlock.
	outerScope associationsDo: aBlock!

keysDo: aBlock
	variables keysDo: aBlock.
	outerScope keysDo: aBlock.! !

!LocalScope methodsFor: 'printing'!

printOn: aStream
	super printOn: aStream.
	aStream nextPutAll: ' with '.
	variables printOn: aStream! !

!LocalScope methodsFor: 'private: private'!

initVariables
	variables _ Dictionary new: 32.
	variableList _ OrderedCollection new: 20!

setLevel: level
	nesting _ level! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LocalScope class
	instanceVariableNames: ''!


!LocalScope class methodsFor: 'instance creation'!

new
	^super new initialize! !