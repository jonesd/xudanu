'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:20 pm'!

InstructionStream subclass: #Context
	instanceVariableNames: 'sender receiver stackp stack '
	classVariableNames: 'CannotResumeSignal CannotReturnSignal CodeSimulationErrorSignal EmergencySignal MethodCache PrimitiveFailedSignal Send TryPrimitiveSelectors '
	poolDictionaries: ''
	category: 'Kernel-Methods'!
Context comment:
'Class Context represents an execution context.  The simulation methods return the new context in which to continue simulation.  This is normally the same context,  except after sends and returns.

Instance Variables:
	sender	<Context>
	receiver	<Object>
	stackp	<SmallInteger>  amount of stack that is occupied
	stack	<Array>  arguments, temporaries, and working stack

Class Variables:
	MethodCache	<IdentityDictionary>
	PrimitiveFailedSignal	<Signal> A simulated primitive has failed
	Send	<Boolean>
	TryPrimitiveSelectors <Array of: Symbols>'!


!Context methodsFor: 'accessing'!

home
	"Answer the context in which the receiver was defined.
	If this information is not available, answer nil."

	^self subclassResponsibility!

homeReceiver
	"Answer the receiver from the context
	in which the receiver was defined."
	^self subclassResponsibility!

receiver
	^receiver!

sender
	^sender!

sourceCode 
	"Answer the source form of the receiver's method."
	self subclassResponsibility!

valueStack
	"Return the Arry that contains the arguments, temporaries, and
	 value stack of the receiver.  This is added so that back-referencing
	 objects (using firstOwner/ownerAfter:) can filter for it."
	
	^stack! !

!Context methodsFor: 'testing'!

hasSender: aContext 
	"Answer true if aContext is on the sender chain
	of the receiver, i.e. if aContext is the receiver's
	sender, or the receiver's sender's sender, etc"

	| ctx |
	ctx _ self.
	[(ctx _ ctx sender) == nil]
		whileFalse: 
			[ctx == aContext ifTrue: [^true]].
	^false!

isBlockContext
	"Answer true if this is a block context.
	By default, contexts are not block contexts."
	^false! !

!Context methodsFor: 'control'!

restart
	"Reinitialize the receiver so that it is in the state it was at its creation."

	super reset.
	stackp _ method numTemps!

restartWith: aCompiledMethod 
	"Reinitialize the receiver as though it had been for a different method.  Used
	by a Debugger when one of the methods to which it refers is recompiled."

	method _ aCompiledMethod.
	^self restart!

resume
	"Continue execution of the receiver."

	self resumeWith: nil!

resumeWith: result
	"Continue execution of the receiver as if it had called a method which
	returned result. Intervening contexts are cut-back, like an ^-return;
	but no unwinds are run."

	thisContext terminateTo: self.
	^result!

terminate
	"Make the receiver unresumable."

	sender _ nil.
	pc _ method endPC + 1!

terminateTo: newSender
	"Terminate all contexts between the receiver's sender and
	newSender (if they are on the same call-chain), and change
	the sender of the receiver to newSender.  Do not run
	unwinds.  Return receiver; fail if newSender is not a Context."
	"Conceptual implementation:
		| ctx |
		ctx _ sender.
		[(nil == ctx) or: [(newSender == ctx)]]
			whileFalse: [ctx _ ctx sender].
		nil == ctx ifFalse: [
			ctx _ sender.
			[newSender == ctx] whileFalse:
				[| sndr |
				sndr _ ctx sender.
				ctx terminate.
				ctx _ sndr]].
		sender _ newSender"

	<primitive: 809>
	^self primitiveFailed!

unwindUpTo: aContext
	"Excecute unwind blocks to aContext."

	| ctx |
	ctx _ self.
	[(ctx _ ctx findNextUnwindUpTo: aContext) == nil] whileFalse:
		[(ctx localAt: 1) value]! !

!Context methodsFor: 'hander search'!

findNextMarkedUpTo: aContext
	"Answer the next context above the receiver which has a
	marked method.  Stop the search at aContext.  Return nil
	if no context found.  Fails if aContext is not a kind of
	Context or nil."
	"Conceptual implementation:
	| ctx |
	(aContext == nil or: [aContext isKindOf: Context]) ifFalse: [^self primitiveFailed].
	ctx _ self.
	[(ctx _ ctx sender) == nil or: [ctx == aContext]] whileFalse:
		[ctx method isMarked ifTrue: [^ctx]].
	^nil"

	<primitive: 808>
	^self primitiveFailed!

findNextUnwindUpTo: aContext
	"Return the next unwind context above the receiver, returning
	nil if there is none.  Search proceeds up to aContext."

	| ctx |
	ctx _ self.
	[(ctx _ ctx findNextMarkedUpTo: aContext) == nil] whileFalse:
		[ctx method isMarkedForUnwind ifTrue: [^ctx]].
	^nil! !

!Context methodsFor: 'printing'!

printOn: aStream 
	| mclass selector class |
	selector _ 
		(class _ self receiver class) 
			selectorAtMethod: method
			setClass: [:mc | mclass _ mc].
	selector == #?
		ifTrue: 
			[aStream nextPut: $?; print: method who.
			^self].
	aStream nextPutAll: class name.
	mclass == class 
		ifFalse: 
			[aStream nextPut: $(.
			aStream nextPutAll: mclass name.
			aStream nextPut: $)].
	aStream nextPutAll: '>>'.
	aStream nextPutAll: selector! !

!Context methodsFor: 'error handling'!

cannotResume
	"Raise a signal which means that the reciever was resumed (e.g. 
	returned into), but is not prepared for execution (e.g. was already 
	returned from). This message is sent by the execution machinery 
	(the VM or some execution simulator such as a debugger)."

	Context cannotResumeSignal raise!

cannotReturn: value 
	"Raise a signal which means that the reciever attempted to return 
	(with the supplied value), but its sender cannot be returned into 
	(e.g. sender is nil, probably because the receiver already returned). 
	This message is sent by the execution machinery (the VM or some
	execution simulator such as a debugger)."

	Context cannotReturnSignal raiseWith: value! !

!Context methodsFor: 'accessing-debugger'!

findTemp: index do: aBlock 
	"index is a linear index that includes all enclosing scopes,
	starting with the method scope, and that does not count
	compiler-generated temporary variables.  Evaluate aBlock with
	the actual context and index where the variable is stored."

	self
		findTemp: index
		do: [:ctx :i | ^aBlock value: ctx value: i]
		elseDo: [:excess | self error: 'Index is out of range']!

localScope
	"Answer a LocalScope containing the argument
	and temporary names for this context.
	Note that this includes compiler-generated
	temporary variables."

	self sourceInfo: [:methodHolder :index | 
			^methodHolder variableMap at: index]!

resizedWith: aNewMethod
	"Answer a context resized"
 
	| nargs args |
	nargs _ method numArgs.
	args _ Array new: nargs.
	1 to: nargs do: [:i | args at: i put: (stack at: i)].
	^self class
		sender: sender
		receiver: receiver
		method: aNewMethod
		arguments: args.!

sender: aContext
	sender _ aContext!

sendersTo: aContext
	"Answer an OrderedCollection of the sender chain
	starting at this context and continuing up to,
	but not including, aContext."

	| contexts ctxt |
	contexts _ OrderedCollection new. 
	ctxt _ self.
	contexts addLast: ctxt.
	[(ctxt _ ctxt sender) == aContext] whileFalse: 
		[contexts addLast: ctxt].
	^contexts!

size
	^stack size!

sourceInfo: aBlock
	"Invoke aBlock with the methodNodeHolder and the index."

	| homeMethod methodHolder index |
	homeMethod _ method homeMethod.
	methodHolder _ homeMethod sourceInfoIfCached. 
	methodHolder == nil ifTrue:
		[methodHolder _ self mclass compilerClass new
			parse: self sourceCode
			in: self mclass
			notifying: nil.
		homeMethod cacheSourceInfo: methodHolder].
	index _ homeMethod withAllBlockMethods identityIndexOf: method.
	^aBlock value: methodHolder value: index!

sourceMap
	"Answer a sourceMap for PC selection in the current code."
	
	self sourceInfo: [:methodHolder :index | 
			^(methodHolder sourceMap at: index) asSortedCollection]!

tempAt: index
	"Answer the argument or temporary value at the given index.
	The index is a linear index that includes all enclosing scopes,
	starting with the method scope, and does not include
	compiler-generated temporary variables."

	^self findTemp: index do: [:ctx :i | ctx privateTempAt: i]!

tempAt: index put: value
	"Change the temporary value at the given index.
	The index is a linear index that includes all enclosing scopes,
	starting with the method scope, and does not include
	compiler-generated temporary variables."

	^self findTemp: index do: [:ctx :i | ctx privateTempAt: i put: value]!

tempNames
	"Answer an OrderedCollection of the name strings of the temporary 
	variables for this context and all its enclosing scopes. Note that this 
	does not include compiler-generated temporary variables."

	^self localScope tempNames select: [:name | name first ~= $.]! !

!Context methodsFor: 'simulation-primitive support'!

doPrimitive: primitiveIndex receiver: rcvr numArgs: numArgs
	"Simulate a primitive method whose index is primitiveIndex.  The
	simulated receiver and argument count are given as arguments to this message.
	The arguments are the top elements of the stack."

	| args primitiveSelector value |
	numArgs > 4 ifTrue: [^nil].  "currently fails text primitive"
	primitiveSelector _ TryPrimitiveSelectors at: numArgs + 1.
	Object addSelector: primitiveSelector
		withMethod: ((Object compiledMethodAt: primitiveSelector) withPrimitiveNumber: primitiveIndex).
	args _ (1 to: numArgs) collect: [:i | self localAt: stackp - numArgs + i].
	^self class primitiveFailedSignal
		handle: [:ex | ex returnWith: nil]
		do: [value _ rcvr perform: primitiveSelector withArguments: args.
			stackp _ stackp - numArgs.
			self localAt: stackp put: value.
			self]!

result0: value
	"Store the value of a 0-argument primitive"
	self localAt: stackp put: value!

result1: value
	"Store the value of a 1-argument primitive"
	stackp _ stackp - 1.
	self localAt: stackp put: value!

skipPrimitive
	"Skip over a primitive which has
	already been tried, and failed."
	pc _ pc + 3.
	(method byteAt: pc) = OpPrimReturn
		ifTrue:  "primitive might possibly build a frame"
			[pc _ pc + 1]!

tryPrimitive: index receiver: rcvr numArgs: numArgs
	"Return new context if successful, nil if failed"
	index <= 255 ifTrue: [^self tryOldPrim: index receiver: rcvr arg: self top numArgs: numArgs].
	^self tryNewPrim: index receiver: rcvr arg: self top numArgs: numArgs! !

!Context methodsFor: 'simulation-primitives'!

primBlockValue: closure arguments: args
	(args isMemberOf: Array) ifFalse: [self error: 'Block arguments list must be an Array'.  ^nil].
	closure method numArgs = args size ifFalse: [self error: 'Block called with wrong numArgs'.  ^nil].
	stackp _ stackp - 2.  "pop closure and args"
	^BlockContext
		sender: self
		receiver: closure
		method: closure method
		arguments: args!

primBlockValue: closure numArgs: numArgs
	closure method numArgs = numArgs ifFalse: [self error: 'Block called with wrong numArgs'.  ^nil].
	^self runMethod: closure method numArgs: numArgs contextClass: BlockContext!

primFlushVMmethodCache: r
	MethodCache _ IdentityDictionary new.
	Behavior flushVMmethodCache!

primFlushVMmethodCacheEntries: r
	"Don't bother to be selective."
	self primFlushVMmethodCache: r.
	^self result1: r!

primPerform: rcvr selector: selector arguments: args
	| rclass nargs |
	(args isMemberOf: Array) ifFalse: [^nil].
	nargs _ args size.
	stackp - 2 + nargs > self localSize ifTrue: [^nil].  "args won't fit"
	rclass _ rcvr class.
	self findMethod: selector
		class: rclass
		ifFound:
			[:meth :mclass |
			"Push the arguments on the stack.
			We know they fit -- we just checked."
			nargs = meth numArgs ifFalse:
				[self error: 'Wrong numArgs for perform'.
				"To continue, just return the receiver of the message."
				stackp _ stackp - 2.
				^self].
			stackp _ stackp - 2.
			args do: [:a | self push: a].
			^self runMethod: meth numArgs: nargs contextClass: MethodContext].
	self error: 'Message not found: ', selector printString.
	"To continue, just return the receiver of the message."
	stackp _ stackp - 2!

primPerform: rcvr selector: selector numArgs: numArgs
	self findMethod: selector
		class: rcvr class
		ifFound:
			[:meth :mclass |
			numArgs = meth numArgs ifFalse:
				[self error: 'Wrong numArgs for perform'.
				"To continue, just return the receiver of the message."
				stackp _ stackp - numArgs - 1.
				^self].
			"Squeeze the selector out of the stack"
			numArgs negated to: -1 do: [:i | self localAt: stackp + i put: (self localAt: stackp + i + 1)].
			stackp _ stackp - 1.
			^self runMethod: meth numArgs: numArgs contextClass: MethodContext].
	self error: 'Message not found: ', selector printString.
	"To continue, just return the receiver of the message."
	stackp _ stackp - numArgs - 1!

primSuspend: r
	r == Processor activeProcess
		ifTrue: [self error: 'Attempt to suspend active process']
		ifFalse: [self result0: r suspend]!

primWait: r
	| proc flag |
	flag _ false.
	proc _ [r wait.  flag _ true] newProcess.
	proc resume.
	Processor yield.  "give proc a chance to run"
	flag
		ifTrue:
			["Semaphore had excess signals, continue"]
		ifFalse:
			["A real wait would occur"
			proc terminate.
			self error: 'Semaphore wait would suspend active process']!

tryNewPrim: index receiver: r arg: a numArgs: numArgs
	"We only simulate enough of the new HPS primitives
	to cover those primitives that have unusual effects
	on control flow (perform and block evaluation).
	The rest we execute directly."
	index = 500 ifTrue: ["BlockClosure valueWithArguments:" ^self primBlockValue: r arguments: a].
	(index >= 501 and: [index < 510]) ifTrue: ["BlockClosure value:*" ^self primBlockValue: r numArgs: numArgs].
	index = 510 ifTrue: ["Object perform:withArguments:" ^self primPerform: r selector: (self localAt: stackp - 1) arguments: a].
	(index >= 511 and: [index < 520]) ifTrue: ["Object perform:with:*" ^self primPerform: r selector: (self localAt: stackp - numArgs + 1) numArgs: numArgs - 1].
	index = 522 ifTrue: [^self primFlushVMmethodCacheEntries: r].
	^self doPrimitive: index receiver: r numArgs: numArgs!

tryOldPrim: index receiver: r arg: a numArgs: numArgs
	index <= 75 ifTrue: [^self doPrimitive: index receiver: r numArgs: numArgs].
	(index between: 80 and: 84) ifTrue: [^nil].  "old blockCopy, value and perform"
	index = 86 ifTrue: [^self primWait: r].
	index = 88 ifTrue: [^self primSuspend: r].
	index = 89 ifTrue: [^self primFlushVMmethodCache: r].
	^self doPrimitive: index receiver: r numArgs: numArgs! !

!Context methodsFor: 'simulation-control'!

callPrimitive: index
	" The callPrimitive opcode should not
	occur in any method. "
	self error: 'Instruction decoding error'!

callPrimitive: index numArgs: numArgs
	" This code will eventually implement the
	callPrimitive opcode.  At this time,
	it is never invoked. "
	| ctx |
	ctx _ self
		tryPrimitive: index
		receiver: (self localAt: stackp - numArgs)
		numArgs: numArgs.
	ctx isNil
		ifTrue: ["primitive failed" self push: false.  ^self]
		ifFalse:
			[ctx == self ifFalse: [self error: 'primitive changed contexts'].
			self push: true.  ^self]!

jump: delta
	pc _ pc + delta!

jump: delta if: condition
	| cond stopPC prev |
	cond _ self top.
	cond == condition ifTrue: [self pop.  pc _ pc + delta.  ^self].
	cond == condition not ifTrue: [self pop.  ^self].
	" Non-boolean condition.  Back up the pc
	and send the mustBeBoolean message. "
	" The only reliable way to back up the pc is
	to re-parse the instruction stream
	from the front.  This isn't as bad as it sounds. "
	stopPC _ pc.
	pc _ method initialPC.
	[pc = stopPC]
		whileFalse:
			[prev _ pc.
			self next].
	pc _ prev.
	^self send: #mustBeBoolean numArgs: 0!

loopHead!

makeCopyingBlock: meth count: count
	| block |
	block _ BlockClosure
			newCopyingMethod: meth
			size: count
			valuesFrom: [:i | self localAt: stackp - count + i].
	stackp _ stackp - count.
	self push: block!

makeFullBlock: meth
	self push: (BlockClosure
			newFullMethod: meth
			outerContext: self)!

methodPrimitive: index
	"This should never happen -- runMethod
	is supposed to catch this."
	self error: 'methodPrimitive called - shouldn''t happen'!

noOp!

primitiveReturn
	^self returnTop!

returnTop
	^self return: self top!

send: selector numArgs: na
	| rcvr |
	rcvr _ self localAt: stackp - na.
	^self
		send: selector
		receiver: rcvr
		class: rcvr class
		super: false
		numArgs: na!

sendNoCheck: selector numArgs: na
	^self send: selector numArgs: na!

sendNonImmediate: selector numArgs: na
	^self send: selector numArgs: na!

sendSuper: selector numArgs: na
	^self
		send: selector
		receiver: receiver
		class: self top superclass
		super: true
		numArgs: na! !

!Context methodsFor: 'simulation-data movement'!

dupFirst
	self dup!

dupLast
	self pop!

dupNext
	self pop; dup!

pop
	stackp _ stackp - 1!

pushConstant: value
	self push: value!

pushContext
	self push: self!

pushInst: index
	self push: (receiver instVarAt: index + 1)!

pushInstAny: index
	| value |
	value _ self top instVarAt: index + 1.
	self pop; push: value  "don't pop till after access succeeds"!

pushLocal: index
	self push: (self localAt: index + 1)!

pushReceiver
	self push: receiver!

pushStatic: assoc
	self push: assoc value!

storeInst: index
	receiver instVarAt: index + 1 put: self top!

storeInstAny: index
	| value |
	value _ self localAt: stackp - 1.
	self top instVarAt: index + 1 put: value.
	self pop  "don't pop till after access succeeds"!

storeLocal: index
	self localAt: index + 1 put: self top!

storeStatic: assoc
	assoc value: self top! !

!Context methodsFor: 'simulation-debugger'!

completeCallee: aContext
	"Simulate the execution of bytecodes until a return to the receiver,
	or until a return to a non-context in case of block up arrow return."

	| ctxt current |
	ctxt _ aContext.
	current _ nil.
	[ctxt == current or: [(ctxt isKindOf: Context) and: [ctxt hasSender: self]]]
		whileTrue: 
			[current _ ctxt.
			ctxt _ ctxt step].
	^ctxt!

send
	| newContext |
	Send _ true.
	newContext _ self step.
	Send _ false.
	^newContext!

step
	"Simulate the execution of the receiver's next bytecode.
	Answer the context that would be the active context
	after this bytecode."

	^Object errorSignal
		handle: [:ex | Context codeSimulationErrorSignal raise]
		do: [self interpretNextInstructionFor: self]!

stepUntilHaveNPC
	"Simulate the execution of bytecodes until
	the vPC can be converted to nPC."

	pc < 0 ifFalse:
		[[(method nFromVPCnoFail: pc) == nil] 
			whileTrue: [self completeCallee: self step]]!

stepUntilPC: stopPC
	"Simulate the execution of bytecodes until pc is equal to stopPC"

	Object errorSignal
		handle: [:ex | Context codeSimulationErrorSignal raise]
		do: [[self pc < stopPC and: [self willReturn not]]
					whileTrue: [self completeCallee: self step]]!

stepUntilProceedable
	"Step until a backward jump or a send and answer a new context activated 
	by the send. If a send is primitive, or the method does not create a context,
	continue to step until an ordinary send. When a return byte code is encountered,
 	return to sender and continue to step."

	| ctx newCtx |
	pc < 0 ifTrue: [^self].
	ctx _ self.
	[ctx willJumpBackward ifTrue: [^ctx].
	ctx willSend 
		ifTrue: "create new context"
			[newCtx _ ctx send.
			(newCtx == ctx or: [newCtx method frameSize = 0])
				ifFalse: [^newCtx].
			"primitive or frameless"
			ctx _ newCtx]
		ifFalse: [ctx _ ctx step]]
	  repeat!

stepUntilVisibleEffect
	"Simulate the execution of bytecodes until either sending a message 
	or assigning a expression or returning a value to the receiver (that is,
	until reaching a point that has meaning at the source level)."

	Object errorSignal
		handle: [:ex | Context codeSimulationErrorSignal raise]
		do: [[self willSend or: [self willAssign or: [self willReturn]]]
					whileFalse: [self step]]! !

!Context methodsFor: 'fileIn/Out'!

storeBinaryOn: stream
	stream inClass: receiver class do: [super storeBinaryOn: stream]! !

!Context methodsFor: 'backward compatibility'!

copyForFixTemps
	^self shallowCopy finishCopyForFixTemps!

finishCopyForFixTemps
	sender _ nil.
	stack _ stack shallowCopy!

release
	"Remove information from the receiver in order to break circularities;
	this shouldn't be necessary!!"

	self terminate!

shortStack
	"Answer a string showing the top five contexts on my sender chain."

	| shortStackStream |
	shortStackStream _ WriteStream on: (String new: 400).
	(self stackOfSize: 5) do: 
		[:item | shortStackStream print: item; cr].
	^shortStackStream contents!

stack 
	"Answer an array of the contexts on the receiver's sender chain."
	^self stackOfSize: 9999!

stackOfSize: limit 
	"Answer an array of the top 'limit' contexts on the receiver's sender chain."

	| a stk |
	stk _ OrderedCollection new: (limit min: 100).
	stk addLast: (a _ self).
	[(a _ a sender) notNil and: [stk size < limit]]
		whileTrue: 
			[stk addLast: a].
	^stk! !

!Context methodsFor: 'private: private-simulation'!

dup
	self push: self top!

findMethod: selector class: initialClass ifFound: aBlock
	"Invoke aBlock with the method and the class
	where it was found."

	| class meth |
	class _ initialClass.
	[class == nil]
		whileFalse:
			[(class includesSelector: selector)
				ifTrue:
					[meth _ class compiledMethodAt: selector.
					^aBlock value: meth value: class].
			class _ class superclass].
	^nil!

push: value
	stackp _ stackp + 1.
	self localAt: stackp put: value!

return: value 
	| caller |
	caller _ sender.
	caller isNil
		ifTrue: [^self cannotReturn: value]
		ifFalse: 
			[sender _ nil.
			^caller push: value]!

runMethod: meth numArgs: nargs contextClass: cclass
	"Run a method.  numArgs is an argument
	because all callers know it, and
	we shouldn't have to compute it again."

	| args rcvr ctx prim |
	rcvr _ self localAt: stackp - nargs.
	(meth isBlockMethod not and: [(prim _ meth primitiveNumber) notNil])
		ifTrue:
			[ctx _ self
				tryPrimitive: prim
				receiver: rcvr
				numArgs: nargs.
			ctx isNil ifFalse: [^ctx]].
	args _ Array new: nargs.
	1 to: nargs do: [:i | args at: i put: (self localAt: stackp - nargs + i)].
	stackp _ stackp - nargs - 1.
	ctx _ cclass
		sender: self
		receiver: rcvr
		method: meth
		arguments: args.
	prim notNil ifTrue: [ctx skipPrimitive].
	^ctx!

send: selector receiver: rcvr class: rclass super: flag numArgs: na
	"Don't simulate calls on error:."
	selector == #error:
		ifTrue:
			[[true] whileTrue: [self error: 'error: called']].
	(flag | Send or: [rclass == Exception]) ifFalse: 
			[^self sendFast: selector receiver: rcvr numArgs: na].
	self findMethod: selector
		class: rclass
		ifFound:
			[:meth :mclass |
			flag ifTrue: [self pop].  "remove class for super"
			^self runMethod: meth numArgs: na contextClass: MethodContext].
	self error: 'Message not found: ', selector printString.
	"To continue, just return the receiver of the message."
	flag ifTrue: [self pop].  "remove class for super"
	stackp _ stackp - na.
	self localAt: stackp put: rcvr!

top
	^self localAt: stackp!

topPop
	| top |
	top _ self localAt: stackp.
	stackp _ stackp - 1.
	^top! !

!Context methodsFor: 'private: private-debugger'!

blockContextFrom: aBlockClosure args: anArray
	"Answer a BlockContext of aBlockClosure."

	| ctx |
	ctx _ BlockContext
				sender: self
				receiver: aBlockClosure
				method: aBlockClosure method
				arguments: anArray.
	ctx restart.
	^ctx!

checkHandlerBlock: block value: selector
	"Answer true if the exception handler is about to run"

	^method == (Exception compiledMethodAt: #propagatePrivateFrom:) 
		and: [block class == BlockClosure
			and: [selector == #value: or: [selector == #value:value:]]]
					"handler"				"Emergency handler"!

removeContextsTo: aContext
	"Remove contexts from the receiver's callee to aContext.
	Find aContext's callee first, and then Set aContext's callee 
	to the receiver's callee."

	| ctx nextCtx |
	ctx _ thisContext.
	[(nextCtx _ ctx sender) ==  aContext]
		whileFalse: [ctx _ nextCtx].
	ctx sender: self.!

sendFast: selector receiver: rcvr numArgs: na
	"Execute a send by using perform to invoke VM. Before doing perform,
	insert extra contexts between the receiver and the perform context.
	The extra contexts holds an exception handling block and an unwind block.
	The exception handling block is used to repropagate the signal through the 
	client process contexts chain. The unwind block is used to catch control flow
	after an uparrow block return occurs in executing the send."

	| args context |
	args _ Array new: na.
	1 to: na do: [:i | args at: i put: (self localAt: stackp - na + i)].
	stackp _ stackp - na - 1.
	(self checkHandlerBlock: rcvr value: selector) ifTrue: 
		[args size = 2  
			ifTrue: ["emergency handler"
					EmergencySignal raiseWith: (args at: 1 "the exception")]
			ifFalse: ["normal handler"
					^Array with: (self blockContextFrom: rcvr args: args)]].
	[| savedSender invisibleContext stubCtx ctx |
	invisibleContext _ thisContext.
	savedSender _ thisContext sender.
	thisContext sender: self.
	[Signal genericSignal 
		handle: [:ex |
				ex checkInitialContextIf: stubCtx with: self.
				self removeContextsTo: stubCtx.
				context _ ex rePropagateFrom: self.
				thisContext sender: invisibleContext]
		do: [stubCtx _ thisContext.
			context _ self push: (rcvr perform: selector withArguments: args)]
	] valueOnUnwindDo: 
			[ctx _ thisContext sender home.
			ctx method == (BlockContext compiledMethodAt: #nonlocalReturn:through:)
				ifTrue: [context _ ctx uparrowReturn.].
			thisContext sender: invisibleContext].
	thisContext sender: savedSender] value.
	^context!

uparrowReturn

	| home result unwindCtx context |
	home _ self localAt: 4.
	result _ self localAt: 5.
	unwindCtx _ self localAt: 3.
	context _ home sender.
	context push: result.
	unwindCtx unwindUpTo: home.
	^context! !

!Context methodsFor: 'private: private-initialization'!

setSender: s receiver: r method: m arguments: args size: ss
	args size = m numArgs ifFalse: [self error: 'Wrong number of arguments'].
	super method: m.
	sender _ s.
	receiver _ r.
	stack _ Array new: ss.
	1 to: args size do: [:i | stack at: i put: (args at: i)].
	stackp _ args size + m numTempsOnly! !

!Context methodsFor: 'private: private-accessing'!

countTemps: index do: aBlock elseDo: elseBlock
	" aBlock is guaranteed to do a ^ return "
	| i ilocal |
	i _ index.
	ilocal _ 1.
	self localScope localTempNames do:
		[:name |
		name first = $. ifFalse:  " not a compiler-generated temporary "
			[i = 1 ifTrue: [aBlock value: self value: ilocal].
			i _ i - 1].
		ilocal _ ilocal + 1].
	^elseBlock value: i!

localAt: index
	^stack at: index!

localAt: index put: value
	^stack at: index put: value!

localSize
	^stack size! !

!Context methodsFor: 'copying'!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance 
	variable. This doesn't make sense for Contexts."

	^self deepCopyError! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Context class
	instanceVariableNames: ''!


!Context class methodsFor: 'class initialization'!

initialize
	"Context initialize"
	MethodCache _ IdentityDictionary new.
	Send _ false.
	TryPrimitiveSelectors _ #(#tryPrimitive0 #tryPrimitive1: #tryPrimitive2:with: #tryPrimitive3:with:with: #tryPrimitive4:with:with:with: ).
	PrimitiveFailedSignal _ Object errorSignal newSignal 
		notifierString: 'A simulated primitive has failed';
		nameClass: self message: #primitiveFailedSignal.
	EmergencySignal _ (Signal genericSignal newSignalMayProceed: false)
		notifierString: 'Code simulation emergency';
		nameClass: self message: #emergencySignal.
	CodeSimulationErrorSignal _ Object errorSignal newSignal 
		notifierString: 'Code simulation error';
		nameClass: self message: #codeSimulationErrorSignal.
	CannotReturnSignal _ Object errorSignal newSignal 
		notifierString: 'Context cannot return';
		nameClass: self message: #cannotReturnSignal.
	CannotResumeSignal _ Object errorSignal newSignal 
		notifierString: 'Context cannot resume';
		nameClass: self message: #cannotResumeSignal! !

!Context class methodsFor: 'instance creation'!

sender: s receiver: r method: m arguments: args
	"If frameSize = 0, we need to use m numArgs + 2,
	for simulating frameless methods."
	| fs |
	fs _ m frameSize.
	fs = 0 ifTrue: [fs _ m numTemps + 2].
	^self new setSender: s receiver: r method: m arguments: args size: fs! !

!Context class methodsFor: 'Signal constants'!

cannotResumeSignal

	^CannotResumeSignal!

cannotReturnSignal

	^CannotReturnSignal!

codeSimulationErrorSignal

	^CodeSimulationErrorSignal!

emergencySignal

	^EmergencySignal!

primitiveFailedSignal

	^PrimitiveFailedSignal! !

Context initialize!
