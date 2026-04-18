'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:29 pm'!

Object subclass: #ByteCodeStream
	instanceVariableNames: 'bindings nesting class code literals literalCollection depth maxDepth reachable labels returnsNonSelf numArgs numTemps requestor topNode sourceMap mustBeSimple '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Support'!
ByteCodeStream comment:
'I represent a code generator for a generic bytecode machine language.  I keep track of literals, stack depth, and reachability.

The source map, translating code PCs to source positions, is sorted by code PC but not necessarily by source position.

Instance variables:
	bindings	<NameScope>
	nesting	<Integer>
	class	<Behavior>
	code	<ByteCodeReadWriteStream on: ByteArray>  "code being accumulated"
	literals	<IdentityDictionary>  "value -> index"
	literalCollection	<OrderedCollection>
	depth	<Integer>  "current stack depth"
	maxDepth	<Integer>  "max stack depth"
	reachable	<Boolean>
	labels	<OrderedCollection of: CodeLabel>
	returnsNonSelf	<Boolean>  "true if any ^ with value other than self"
	numArgs	<Integer>
	numTemps	<Integer>
	requestor	<>  "object for handling errors"
	topNode	<MethodRep | BlockRep>  "top node generating code"
	sourceMap	<nil | OrderedCollection of: (Association key: Integer value: Interval)>  "map pc to source range"
	mustBeSimple	<Boolean>  "true if generated code must be simple enough to decompile"

Note that there is a binding for ''super'', identical to the binding for ''self''.  ''Super'' is not a variable, but it simplifies code generation slightly to do things this way.

The code generation messages beginning with ''code'' are higher-level operations.  The low-level operations are deliberately chosen to have the same names as those sent by InstructionStream for instruction decoding.'!


!ByteCodeStream methodsFor: 'initialize-release'!

addMethodVars
	bindings receiverName: 'self' withSuper: true.
	bindings pseudoVariable: 'thisContext'!

arguments: args
	depth _ maxDepth _ bindings arguments: args startingAt: 0 from: self.
	numArgs _ args size!

bindRemote: contextNode in: ctxt
	bindings addRemote: contextNode in: ctxt!

class: aClass outerScope: aNameScope
	class _ aClass.
	bindings _ LocalScope new.
	bindings outerScope: aNameScope.
	nesting _ 0!

class: aClass scope: aNameScope nesting: level
	"This is used for inner blocks."
	class _ aClass.
	bindings _ aNameScope.
	nesting _ level!

initialize
	code _ ByteCodeReadWriteStream on: (ByteArray new: 40).
	literals _ IdentityDictionary new.
	literalCollection _ OrderedCollection new.
	depth _ maxDepth _ numTemps _ 0.
	reachable _ true.
	"labels _ OrderedCollection new."  "do when needed"
	returnsNonSelf _ false.
	mustBeSimple _ true  "THIS SHOULD BE CHANGED EVENTUALLY"!

leaveScope
	bindings leaveScope: self!

newBlockScope
	| inner |
	inner _ self class new.
	inner class: class scope: bindings newBlockScope nesting: nesting + 1.
	inner requestor: requestor.
	^inner!

requestor: req
	requestor _ req!

saveSourceMap
	"Initialize the source map so it will
	accumulate entries."
	sourceMap _ OrderedCollection new: 16!

topNode: aNode
	topNode _ aNode! !

!ByteCodeStream methodsFor: 'accessing'!

addTemporaries: temps
	"Bind a collection of temporaries.
	Return a value that can be used to unbind them later."
	| addedCount oldCount |
	addedCount _ temps size.
	addedCount = 0 ifTrue: [^nil].  "nothing to bind or unbind"
	oldCount _ numTemps.
	numTemps _ (bindings temporaries: temps startingAt: numArgs + numTemps from: self) - numArgs.
	depth _ depth + addedCount.
	maxDepth _ maxDepth + addedCount.
	^oldCount to: numTemps - 1!

bindings
	^ bindings.!

generateNames: count
	"Generate a set of new temporary variable names."
	^bindings generateNames: count!

noteSourceNode: node
	"Note the correspondence between the
	current code position, and the source
	position of the node."
	| pos |
	(sourceMap == nil or: [(pos _ node sourcePosition) == nil])
		ifFalse:
			[self noteSourceRange: pos]!

noteSourceNodeEnd: node
	"Note the correspondence between the
	current code position, and the source
	position of the end of the node."
	| pos |
	(sourceMap == nil or: [(pos _ node sourcePosition) == nil])
		ifFalse:
			[self noteSourceRange: (pos last + 1 to: pos last)]!

noteSourceRange: pos
	"Note the correspondence between the
	current code position, and a range of
	character positions in the source."
	sourceMap == nil
		ifFalse:
			[sourceMap addLast: (Association key: code position + 1 value: pos)]!

noteStore: varNode
	| def |
	def _ bindings variableAt: varNode name from: varNode.
	def notNil ifTrue: [def noteStore]!

removeTemporaries: oldRange
	"Unbind a collection of temporaries.
	oldRange is the range of old temporary indices
	that was returned as the value of addTemporaries:."

	oldRange notNil ifTrue:  "don't bother if nothing to unbind"
		[bindings
			leaveScope: self
			between: numArgs + oldRange first
			and: numArgs + oldRange last
			remove: true]!

variableAt: name from: varNode

	^bindings variableAt: name from: varNode! !

!ByteCodeStream methodsFor: 'testing'!

inBlock
	"Return true if we are compiling
	the code for a block."
	^self subclassResponsibility!

isForNonImmediate
	"Return true if this class is definitely not
	an immediate class or a superclass of one,
	and false otherwise."
	^self subclassResponsibility!

mustBeSimple
	^mustBeSimple!

reachable
	"so code generator can decide whether
	to generate default ^self at the end of
	a method"
	^reachable!

returnsNonSelf
	"so code generator can decide whether
	default ^self at the end of a method
	is acceptable"
	^returnsNonSelf!

variableIsInvariant: name
	"Answer true iff name is the name of
	an invariant (argument or receiver) variable."
	| var |
	var _ bindings variableAt: name from: nil.
	var isNil ifTrue: [^false].  "name is not bound"
	^var isInvariant! !

!ByteCodeStream methodsFor: 'enumerating'!

bindingsDo: aBlock
	bindings associationsDo: aBlock! !

!ByteCodeStream methodsFor: 'code generation-loads and stores'!

codeLoad: name from: varNode
	| var |
	(var _ bindings variableAt: name from: varNode) == nil
		ifTrue: [var _ bindings undeclared: name from: varNode].
	var emitLoad: self from: varNode!

codeStore: name value: value from: varNode in: assignNode
	| var |
	(var _ bindings variableAt: name from: varNode) == nil
		ifTrue: [var _ bindings undeclared: name from: varNode].
	var emitStore: self value: value from: assignNode!

codeStorePop: name value: value from: varNode in: assignNode
	| var |
	(var _ bindings variableAt: name from: varNode) == nil
		ifTrue: [var _ bindings undeclared: name from: varNode].
	var emitStorePop: self value: value from: assignNode! !

!ByteCodeStream methodsFor: 'code generation-branches and labels'!

branch: label with: op
	label reference: code position opcode: op.
	code nextPut: op with: 0!

define: label test: testBlock long: minLongJump shorten: shortenBlock
	| pos refs disp op ref |
	pos _ code labelPosition.
	refs _ label references.
	refs == nil ifTrue:  "no reference"
		[label definition: pos.  ^self].
	reachable _ true.
	refs size > 1 ifTrue:  "too complicated to optimize"
		[refs do: [:fix | self putLongBranchFrom: fix key].
		label definition: pos.
		^self].
	"See if the reference is within short branch range."
	ref _ refs first key.
	disp _ pos - (ref + 2).
	(testBlock value: refs first value "op" value: disp)
		ifTrue:
			["Can use a short branch.  Adjust any
			branches into the intervening code.
			Note: this depends on the minimum short
			jump distances all being 1, because
			it assumes that a short jump can't
			become long if the displacement decreases.
			Also adjust any labels within this code."
			labels do: [:l | l fixAcross: ref in: code long: minLongJump].
			"Scrunch the intervening code.
			There may be references OUT of it
			that have to be adjusted."
			op _ shortenBlock value: (code removeIndex: ref).
			code at: ref put: op + disp - 1.  "MinShortJump = 1"
			label definition: pos - 1.  "fix up our own definition"
			"Fix up any entries in the pc map."
			self noteScrunch: 1 at: ref.
			^self].
	"Fix up the long branch."
	label definition: pos.
	self putLongBranchFrom: ref!

labelHere
	"Create a new label for backward references"
	| l |
	l _ CodeLabel new.
	l definition: code labelPosition.
	labels == nil ifTrue: [labels _ OrderedCollection new].
	labels add: l.
	reachable _ true.
	^l!

newLabel
	"Create a new label for forward references"
	| l |
	l _ CodeLabel new.
	labels == nil ifTrue: [labels _ OrderedCollection new].
	labels add: l.
	^l! !

!ByteCodeStream methodsFor: 'code generation-utilities'!

assignLiteralIndex
	"Assign a literal index for a literal to be filled in later.
	(This is a 0-origin index.)"
	literalCollection addLast: 'a dummy literal'.
	^literalCollection size - 1!

literalIndex: lit
	"Find the index of an existing literal,
	or add it to the collection."
	^literals at: lit ifAbsent: [self newLiteralIndex: lit]!

newLiteralIndex: lit
	"Add a literal to the collection and
	return the index."
	literalCollection addLast: lit.
	^literals at: lit put: literalCollection size - 1!

noteScrunch: amount at: pos
	"Note that some code has been removed
	just after pos, by decrementing all subsequent
	PCs in the source map (if any).  pos is 0-origin."
	| i assoc |
	sourceMap notNil
		ifTrue:
			[i _ sourceMap size.
			[i > 0 and: [(assoc _ sourceMap at: i) key - 1 > pos  "keys are 1-origin"]]
				whileTrue:
					[assoc key: assoc key - amount.
					i _ i - 1]]!

pop: n
	depth _ depth - n!

push
	depth _ depth + 1.
	depth > maxDepth ifTrue: [maxDepth _ depth]!

putIndex: index count: count short: op2 long: op3
	"Put out an opcode with an index and a second
	parameter (numArgs for sends, level count for
	outer block references.)  The short form takes
	a single extension byte with a 3-bit count and
	a 5-bit index; the long form takes two extension
	bytes."
	(index <= 31 and: [count <= 7 and: [op2 notNil]])
		ifTrue: [code nextPut: op2 with: count * 32 + index]
		ifFalse: [code nextPut: op3 with: count with: index]!

putIndex: index short: op1 max: max long: op2
	"Put out either a short or long opcode,
	depending on the value of the index."
	index <= max
		ifTrue: [code nextPut: op1 + index]
		ifFalse: [code nextPut: op2 with: index]!

putLongBranch: op to: pos
	| disp | 
	disp _ pos - (code position + 2).
	code nextPut: op + (disp bitShift: -8)
		with: (disp bitAnd: 255)!

putLongBranchFrom: jump
	code
		fixBranchAt: jump
		with: code position - (jump + 2)!

selectorIndex: selector allowSpecial: allowSpecial
	| index |
	allowSpecial
		ifTrue:
			[index _ self specialSelectors at: selector ifAbsent: [nil].
			index == nil ifFalse: [^index]].
	^literals at: selector ifAbsent:
		[literalCollection addLast: selector.
		literals at: selector put: literalCollection size - 1]! !

!ByteCodeStream methodsFor: 'error handling'!

error: type with: message at: position
	requestor error: type with: message at: position!

error: type with: message from: node
	requestor error: type with: message in: node from: self!

redeclaredArg: argNode
	"An argument is being redeclared.
	The error is different if this is a block argument."

	self
		error: (self inBlock ifTrue: [#redeclaredBlockArg] ifFalse: [#redeclared])
		with: argNode name
		from: argNode.
	^true  "Allow the redeclaration if the user proceeds"!

redeclaredTemp: tempNode
	"A local variable is being redeclared.
	Signal an error."

	self error: #redeclared with: tempNode name from: tempNode.
	^true  "Allow the redeclaration if the user proceeds"!

topNode
	"Return the top node, for
	automatically pasting in temps."
	^topNode! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ByteCodeStream class
	instanceVariableNames: ''!


!ByteCodeStream class methodsFor: 'instance creation'!

new
	^super new initialize! !