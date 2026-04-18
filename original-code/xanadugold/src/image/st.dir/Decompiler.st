'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:36 pm'!

InstructionStream subclass: #Decompiler
	instanceVariableNames: 'builder instVars localVars copiedVars tempCount stack statements limit primitive lastPc exit lastJumpPc hasValue openCondition openSign openPc openDepth loopDepth lastAssignment lastAssignVar lastAssignPc '
	classVariableNames: 'CascadeFlag CascadeLastFlag '
	poolDictionaries: ''
	category: 'System-Compiler-Public Access'!
Decompiler comment:
'Class Decompiler is a translator of CompiledMethods into parse trees.

IMPORTANT NOTE: the Decompiler will not be supported indefinitely.  For this reason, we have chosen to provide the Compiler with a switch that controls whether it will produce code that can be decompiled.  Decompilable code is simpler but slower than the more optimized code that the Compiler is capable of producing: specifically, it does not optimize conditional branches where the condition is itself conditional (e.g. an and: or an or:) or a constant.  While the Decompiler is supported, the default setting of this switch will be to produce decompilable code.

Because this decision was made after a good deal of work had been expended on getting the Decompiler to decompile optimized code, the Decompiler''s handling of control structures is needlessly complicated.  In particular, it attempts to (but does not correctly) handle arbitrarily complex and:/or: branching structures.  The Compiler will never generate such structures when producing decompilable code.

The instance variables builder, instVars, localVars, and tempCount are set at instance creation time, and may be shared with the subordinate Decompilers created for blocks.  copiedVars is set at instance creation time.  The remaining instance variables are used dynamically.

Instance Variables:
	builder	<ProgramBuilder>
	instVars	<OrderedCollection of: VariableNode>
	localVars	<OrderedCollection of: (Array of: VariableNode)>
	copiedVars	<Array of: VariableNode>
	tempCount	<Association value: Integer>
	stack	<OrderedCollection of: ProgramNode>
	statements	<OrderedCollection of: ProgramNode>
	limit	<Integer>
	primitive	<Integer | nil>
	lastPc	<Integer>
	exit	<Integer>
	lastJumpPc	<Integer>
	hasValue	<Boolean>
	openCondition	<ValueNode | nil>
	openSign	<Boolean | nil>
	openPc	<Integer | nil>
	openDepth	<Integer | nil>
	loopDepth	<OrderedCollection of: Integer>
	lastAssignment	<AssignmentNode | nil>
	lastAssignVar	<VariableNode>
	lastAssignPc	<Integer>

Class Variables:
	CascadeFlag 		<ByteString>
	CascadeLastFlag	<ByteString>'!


!Decompiler methodsFor: 'public access'!

decompile: aSelector in: aClass
	"Answer with a parse tree for this method."
	^self
		decompile: aSelector
		in: aClass
		method: (aClass compiledMethodAt: aSelector)!

decompile: aSelector in: aClass method: aMethod
	"Answer with a parse tree (root is a MethodNode) for this method."
	^self
		decompile: aSelector
		in: aClass
		method: aMethod
		using: ProgramNodeBuilder new!

decompileBlock: aMethod in: aClass
	"Answer with a parse tree (root is a BlockNode) for this block method."
	^self
		decompileBlock: aMethod
		in: aClass
		using: ProgramNodeBuilder new! !

!Decompiler methodsFor: 'opcodes-data movement'!

dupFirst
	stack addLast: OrderedCollection new.  "accumulate cascade elements"
	stack addLast: CascadeFlag!

dupLast
	| msg |
	msg _ stack removeLast.
	stack last addLast: msg.
	stack addLast: CascadeLastFlag!

dupNext
	| msg |
	msg _ stack removeLast.
	stack last addLast: msg.
	stack addLast: CascadeFlag!

pop
	statements addLast: stack removeLast.
	lastAssignPc = lastPc ifTrue: [lastAssignPc _ pc]  "store followed by pop"!

pushConstant: value
	(value isMemberOf: BlockClosure)
		ifTrue: [self codeBlock: value method copied: #()]
		ifFalse: [stack addLast: (builder newLiteralValue: value)]!

pushContext
	self pushVarNamed: 'thisContext'!

pushCopiedValues: count
	localVars addFirst: (localVars removeFirst , copiedVars)!

pushInst: index
	self pushVarNamed: (instVars at: index + 1)!

pushInst: index outer: level
	"Since we can only refer to instance variables
	in the outermost scope, we disregard level."
	self pushInst: index!

pushInstAny: index
	"We know this is only generated for
	instance variables of the outer receiver."
	stack removeLast.  "pop receiver object"
	self pushInst: index!

pushLocal: index
	self pushLocal: index outer: 0!

pushLocal: index outer: level
	self pushVariable: ((localVars at: level + 1) at: index + 1)!

pushReceiver
	stack addLast: builder forSelf!

pushReceiverOuter: level
	"We can only refer to the receiver
	in the outermost scope."
	self pushReceiver!

pushStatic: assoc
	self pushVarNamed: assoc key asString!

storeInst: index
	self pushInst: index; doStore: stack!

storeInstAny: index
	"We know this is only generated for
	instance variables of the outer receiver."
	stack removeLast.  "pop receiver object"
	self storeInst: index!

storeLocal: index
	self pushLocal: index; doStore: stack!

storePopInst: index outer: level
	self pushInst: index outer: level; doStore: statements!

storePopLocal: index outer: level
	self pushLocal: index outer: level; doStore: statements!

storeStatic: assoc
	self pushStatic: assoc; doStore: stack! !

!Decompiler methodsFor: 'opcodes-control'!

callPrimitive: index
	" The callPrimitive opcode should not
	appear in any method at this time. "
	self error: 'Instruction decoding error'!

jump: dist
	exit _ pc + dist.
	lastJumpPc _ lastPc!

jump: dist if: condition
	self jumpTo: pc + dist if: stack removeLast sign: condition!

loopHead
	loopDepth addFirst: statements size!

makeCopyingBlock: meth count: count
	self codeBlock: meth copied: (stack removeLast: count)!

makeFullBlock: meth
	self codeBlock: meth copied: #()!

methodPrimitive: index
	primitive _ index!

methodReturnTop: levels
	exit _ method endPC + 2.
	lastJumpPc _ lastPc.
	statements addLast: (builder newReturnValue: stack removeLast)!

noOp!

primitiveReturn
	"No action needed"!

returnTop
	localVars size = 1
		ifTrue:  "i.e. we are at method level"
			[self methodReturnTop: 0]
		ifFalse:  "i.e. we are in a block"
			[exit _ method endPC + 1.
			lastJumpPc _ lastPc]!

send: selector numArgs: na
	| args rcvr r node list |
	args _ stack removeLast: na.
	rcvr _ r _ stack removeLast.
	(r == CascadeFlag or: [r == CascadeLastFlag])
		ifTrue:
			["Get the true receiver of the cascade"
			rcvr _ stack at: stack size - 1].
	node _ builder newMessageReceiver: rcvr selector: selector arguments: args.
	r == CascadeLastFlag
		ifTrue:
			["This is the last message of a cascade"
			list _ stack removeLast.  "cascade list"
			list addLast: node.
			stack removeLast.  "pop the saved receiver"
			node _ builder newCascadeReceiver: rcvr messages: list asArray].
	stack addLast: node!

sendNoCheck: selector numArgs: na
	self send: selector numArgs: na!

sendNonImmediate: selector numArgs: na
	self send: selector numArgs: na!

sendSuper: selector numArgs: na
	| rcvr rindex |
	stack removeLast.  "remove class"
	rindex _ stack size - na.  "index of receiver"
	rcvr _ stack at: rindex.
	(rcvr == CascadeFlag or: [rcvr == CascadeLastFlag])
		ifTrue: [rindex _ rindex - 2].  "back up to cascade receiver"
	stack at: rindex put: builder forSuper.  "replace receiver"
	self send: selector numArgs: na! !

!Decompiler methodsFor: 'private: private'!

buildCond: myCond sign: mySign thenBody: thenBody elseBody: elseBody
	| selector args |
	elseBody isEmpty
		ifTrue:
			[selector _ mySign ifTrue: [#ifFalse:] ifFalse: [#ifTrue:].
			args _ Array with: (builder newBlockBody: thenBody)]
		ifFalse:
			[thenBody isEmpty
				ifTrue:
					[selector _ mySign ifTrue: [#ifTrue:] ifFalse: [#ifFalse:].
					args _ Array with: (builder newBlockBody: elseBody)]
				ifFalse:
					["Check for and: or or:"
					mySign
						ifTrue: [selector _ #ifFalse:ifTrue:]
						ifFalse:
							[thenBody booleanValue == true
								ifTrue:
									[selector _ #or:.
									args _ Array with: (builder newBlockBody: elseBody)]
								ifFalse:
									[elseBody booleanValue == false
										ifTrue:
											[selector _ #and:.
											args _ Array with: (builder newBlockBody: thenBody)]
										ifFalse: [selector _ #ifTrue:ifFalse:]]].
					args == nil
						ifTrue:
							[args _ Array with: (builder newBlockBody: thenBody) with: (builder newBlockBody: elseBody)]]].
	^builder
		newMessageReceiver: myCond
		selector: selector
		arguments: args!

codeBlock: aMethod copied: values
	| block |
	block _ Decompiler new
		decompileMethod: aMethod
		builder: builder
		instVars: instVars
		localVars: localVars
		copiedVars: values
		tempCount: tempCount.
	stack addLast: block!

doStore: stackOrBlock
	"Handle an assignment.  StackOrBlock is
	stack for store, statements for storePop."
	| var expr node |
	var _ stack removeLast.
	expr _ stack removeLast.
	node _ builder newAssignmentVariable: var value: expr.
	stackOrBlock addLast: node.
	lastAssignment _ node.
	lastAssignVar _ var.
	lastAssignPc _ pc!

jumpTo: elseStart if: ifExpr sign: sign
	| elsePc end thenBody condHasValue thenJump elseBody elseJump cond ocond osign opc odepth myCond mySign |
	elsePc _ lastPc.
	end _ limit.
	ocond _ openCondition.  osign _ openSign.  opc _ openPc.  odepth _ openDepth.
	openCondition _ ifExpr.  openSign _ sign.  openPc _ elseStart.  openDepth _ statements size.
	thenBody _ self sequenceTo: elseStart temporaries: #().
	myCond _ openCondition.  mySign _ openSign.
	openCondition _ ocond.  openSign _ osign.  openPc _ opc.  openDepth _ odepth.
	condHasValue _ hasValue.
	"We have 3 cases to consider here:
		- exit < elseStart : thenBody is a loop body.
		- exit <= end : thenBody is the true arm of a conditional.
		- exit > end : thenBody is the true arm of a conditional, and ends with a return.  If condHasValue is true, the return is a local return from a block; if condHasValue is false, the return is a method return."
	exit < elseStart
		ifTrue:
			["the jump is to the beginning of the while expr.  In the case of
			while's with a block in the condition, the while expr
			should include more than just the last expression: find all the
			statements needed by using loopDepth."
			statements addLast: myCond.
			myCond _ builder newSequenceStatements: (statements removeLast: statements size - loopDepth first).
			statements addLast:
				(thenBody isEmpty
					ifTrue:
						[builder newCondition: myCond doWhile: mySign not]
					ifFalse:
						[builder newCondition: myCond while: mySign not do: thenBody]).
			loopDepth removeFirst.
			lastJumpPc _ nil.  "control falls through after loop"
			^self].
	(exit <= end and: [exit <= (method endPC + 1)])
		ifTrue: ["conditional, no return" thenJump _ exit]
		ifFalse: ["conditional with return" thenJump _ elseStart].
	elseBody _ self sequenceTo: thenJump temporaries: #().
	elseJump _ exit.
	"if elseJump is backwards, it is not part of the elseExpr"
	elseJump < elsePc
		ifTrue: [pc _ lastPc].
	cond _ self buildCond: myCond sign: mySign thenBody: thenBody elseBody: elseBody.
	(condHasValue and: [elseJump <= end])  "second clause checks for local block return"
		ifTrue: [stack addLast: cond]
		ifFalse: [statements addLast: cond].
	openCondition _ ocond.  openSign _ osign.  openPc _ opc.  openDepth _ odepth.!

pushVariable: var
	" Check for a store-pop followed by a push. "
	(var = lastAssignVar and:
	 [statements isEmpty not and:
	  [statements last == lastAssignment and:
	   [lastAssignPc = lastPc]]])
		ifTrue:
			[stack addLast: statements removeLast]
		ifFalse:
			[stack addLast: var]!

pushVarNamed: name
	self pushVariable: (builder newVariableName: name)!

sequenceTo: end temporaries: temps
	"Decompile a range of code as in statementsTo:,
	but return a sequence."

	^builder
		newSequenceTemporaries: temps
		statements: (self statementsTo: end)!

statementsTo: end
	| oldLimit blockPos stackPos |
	"Decompile the method from pc up to end and return an array of
	expressions.  If at run time this block will leave a value on
	the stack, set hasValue to true.  If the block ends with a jump or return,
	set exit to the destination of the jump, or the end of the method;
	if the block ends with a conditional jump,
	set exit to the destination of the jump; otherwise, set exit = end.
	Leave pc = end."
	oldLimit _ limit.
	blockPos _ statements size.
	stackPos _ stack size.
	limit _ end.
	[pc < limit]
		whileTrue:
			[lastPc _ pc.
			self interpretNextInstructionFor: self].
	"If there is an additional item on the stack, it will be the value
	of this block."
	(hasValue _ stack size > stackPos)
		ifTrue:
			[self pop].
	lastJumpPc = lastPc ifFalse: [exit _ pc].
	limit _ oldLimit.
	^statements removeLast: (statements size - blockPos)! !

!Decompiler methodsFor: 'private: private-initialize-release'!

decompile: aSelector in: aClass method: aMethod using: aBuilder 
	| block |
	block _ self
		decompileMethod: aMethod
		builder: aBuilder
		instVars: aClass allInstVarNames
		localVars: OrderedCollection new
		copiedVars: #()
		tempCount: (Association key: nil value: 0).
	^builder
		newMethodSelector: aSelector
		primitive: primitive
		block: block!

decompileBlock: aMethod in: aClass using: aBuilder 
	| meth |
	"Construct local variables for enclosing scopes"
	meth _ aMethod.
	localVars _ OrderedCollection new.
	tempCount _ Association key: nil value: 0.
	[meth _ meth outerMethod.
	meth isBlockMethod]
		whileTrue:
			[localVars addFirst: (self newTemps: meth numTemps + meth numCopiedValues)].
	localVars addFirst: (self newTemps: meth numTemps).
	^self
		decompileMethod: aMethod
		builder: aBuilder
		instVars: aClass allInstVarNames
		localVars: localVars
		copiedVars: (self newTemps: aMethod numCopiedValues)
		tempCount: tempCount!

decompileMethod: aMethod builder: aBuilder instVars: ivars localVars: lvars copiedVars: copied tempCount: tc
	| locals body |

	"Initialize the instance from the arguments"

	super method: aMethod.
	builder _ aBuilder.
	instVars _ ivars.
	localVars _ lvars.
	copiedVars _ copied.
	tempCount _ tc.

	"Initialize the rest of the instance"

	stack _ OrderedCollection new: aMethod frameSize.
	statements _ OrderedCollection new: 20.
	primitive _ nil.
	loopDepth _ OrderedCollection new.

	"Decompile the method"

	locals _ self newTemps: method numTemps.
	localVars addFirst: locals.
	locals _ locals collect: [:var | builder newParameterVariable: var].
	body _ self
		sequenceTo: method endPC + 1
		temporaries: (locals copyFrom: method numArgs + 1 to: locals size).
	stack isEmpty ifFalse: [self error: 'stack not empty'].
	localVars removeFirst.
	^builder
		newBlockArguments: (locals copyFrom: 1 to: method numArgs)
		body: body!

newTemps: count
	"Generate this many new temp names"
	| temp |
	^(1 to: count) collect:
		[:i |
		temp _ tempCount value + 1.
		tempCount value: temp.
		builder newVariableName: ('t', temp printString)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Decompiler class
	instanceVariableNames: ''!


!Decompiler class methodsFor: 'class initialization'!

initialize
	"Decompiler initialize"

	CascadeFlag _ 'cascade' copy.  "a unique object"
	CascadeLastFlag _ 'cascadeLast' copy  "ditto"! !

Decompiler initialize!
