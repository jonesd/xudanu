'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:16 pm'!

Object subclass: #BlockClosure
	instanceVariableNames: 'method outerContext copiedValues '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Methods'!
BlockClosure comment:
'A BlockClosure represents a block closure, created by executing a block expression ([] construct).  I may include a reference to the outer context and/or copied variables (currently, only one or the other).

There are currently three kinds of closures: "clean" closures with no references to anything from outer scopes (these have outerContext = nil, copiedValues = nil); "copying" closures that copy immutable values from outer scopes when the closure is created (these have outerContext = nil, copiedValues used); and "full" closures that retain a reference to the next outer scope (these have outerContext ~= nil, copiedValues = nil.)  As an optimization, copiedValues holds the (single) copied value if there is exactly one, or an Array of values if there is more than one.  Note that if there is a single copied value, copiedValues may still be nil: the way to check whether a closure has copied values is to ask its method whether numCopiedValues > 0.

Instance Variables:
	method			<CompiledMethod>
	outerContext	<Context | nil>
	copiedValues	<Object | Array | nil>'!


!BlockClosure methodsFor: 'accessing'!

home
	"Answer the outermost MethodContext, or nil if none was saved."

	^outerContext == nil
		ifTrue: [nil]
		ifFalse: [outerContext home]!

method
	"Answer the deferred sequence of expressions."

	^method!

numArgs
	"Answer the number of arguments expected."

	^method numArgs!

outerContext
	"Answer the context from which the receiver can obtain values."

	^outerContext!

valueStack
	"Return the copiedValues Array if there is one.  This is added so that back-referencing
	 objects (using firstOwner/ownerAfter:) can filter for it."
	
	^copiedValues isSequenceable ifTrue: [copiedValues]! !

!BlockClosure methodsFor: 'comparing'!

= aBlockClosure
	^aBlockClosure class = self class and:
	 [method = aBlockClosure method and:
	  [outerContext = aBlockClosure outerContext and:
	   [copiedValues = aBlockClosure copiedValues]]]!

hash
	^method hash bitXor: outerContext hash! !

!BlockClosure methodsFor: 'evaluating'!

is: arg 
	"Evaluate the block represented by the receiver.  Fail if the block expects other 
	than one argument.  Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 502>
	^self valueWithArguments: (Array with: arg)!

of: arg 
	"Evaluate the block represented by the receiver.  Fail if the block expects other 
	than one argument.  Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 502>
	^self valueWithArguments: (Array with: arg)!

of: arg1 and: arg2 
	"Evaluate the block represented by the receiver.  Fail if the block expects other 
	than two arguments.  Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 503>
	^self valueWithArguments: (Array with: arg1 with: arg2)!

smalltalkOnly
	"Evaluate the block represented by the receiver.  Fail if the block expects any 
	arguments.  Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 501> 
	^self valueWithArguments: #()!

translateOnly
	"don't execute the block; it is for C++ translation only"
	^VOID!

USES
	"don't execute the block; it is for C++ type scanning only"
	^VOID!

value
	"Evaluate the block represented by the receiver.  Fail if the block expects any 
	arguments.  Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 501>
	^self valueWithArguments: #()!

value: arg 
	"Evaluate the block represented by the receiver.  Fail if the block expects other 
	than one argument.  Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 502>
	^self valueWithArguments: (Array with: arg)!

value: arg1 value: arg2 
	"Evaluate the block represented by the receiver.  Fail if the block expects other 
	than two arguments.  Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 503>
	^self valueWithArguments: (Array with: arg1 with: arg2)!

value: arg1 value: arg2 value: arg3 
	"Evaluate the block represented by the receiver.  Fail if the block expects other 
	than three arguments.  Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 504>
	^self valueWithArguments: 
		(Array
			with: arg1
			with: arg2
			with: arg3)!

valueWithArguments: anArray 
	"Evaluate the block represented by the receiver.  The argument is an Array 
	whose elements are the arguments for the block.  Fail if the length of the Array 
	is not the same as the the number of arguments that the block was expecting.  
	Essential.  See Object documentation whatIsAPrimitive."

	<primitive: 500>
	(anArray isMemberOf: Array)
		ifTrue: [self error: 'This block expects ', self numArgs printString, ' argument(s)']
		ifFalse: [self error: 'BlockClosure>>valueWithArguments: requires an Array']! !

!BlockClosure methodsFor: 'unwinding'!

valueNowOrOnUnwindDo: aBlock
	"Answer the result of evaluating the receiver.
	If an exception would cause the evaluation to
	be abandoned, evaluate aBlock.  The logic for
	this is in Exception.  If no exception occurs,
	also evaluate aBlock."

	| result |
	result _ self value.
	aBlock value.
	^result!

valueOnUnwindDo: aBlock
	"Answer the result of evaluating the receiver.
	If an exception would cause the evaluation to
	be abandoned, evaluate aBlock.  The logic for
	this is in Exception."

	^self value! !

!BlockClosure methodsFor: 'controlling'!

repeat
	"Evaluate the receiver repeatedly, not ending unless the block
	forces some stopping condition. Ordinarily compiled in-line.  
	But could also be done in Smalltalk as follows"

	self value.
	[self value] repeat!

whileFalse
	"Evaluate the receiver once and then repeatedly as long as the value
	returned by the evaluation is false. Ordinarily compiled in-line.  
	But could also be done in Smalltalk as follows"

	^[self value] whileFalse: []!

whileFalse: aBlock 
	"Evaluate the argument, aBlock, as long as the value   
	of the receiver is false. Ordinarily compiled in-line.  
	But could also be done in Smalltalk as follows"

	^self value
		ifFalse:
			[aBlock value.
			[self value] whileFalse: [aBlock value]]!

whileTrue
	"Evaluate the receiver once and then repeatedly as long as the value
	returned by the evaluation is true. Ordinarily compiled in-line.  
	But could also be done in Smalltalk as follows"

	^[self value] whileTrue: []!

whileTrue: aBlock 
	"Evaluate the argument, aBlock, as long as the value   
	of the receiver is true. Ordinarily compiled in-line.  
	But could also be done in Smalltalk as follows"

	^self value
		ifTrue:
			[aBlock value.
			[self value] whileTrue: [aBlock value]]! !

!BlockClosure methodsFor: 'scheduling'!

fork
	"Create and schedule a process running the code in the receiver."

	self newProcess resume!

forkAt: priority 
	"Create and schedule a process running the code in the receiver.
	The priority of the process is the argument, priority."

	| forkedProcess |
	forkedProcess _ self newProcess.
	forkedProcess priority: priority.
	forkedProcess resume!

newProcess
	"Answer a new process running the code in the receiver.
	The process is not scheduled."

	^Process
		forContext: 
			[Process terminateSignal
				handle: [:ex | ex return]
				do: self.
			Processor terminateActive]
				newContext
		priority: Processor activePriority!

newProcessWithArguments: anArray 
	"Answer a new process running the code in the receiver.
	The receiver's block arguments are bound to the contents
	of the argument, anArray.  The process is not scheduled."

	^[self valueWithArguments: anArray] newProcess! !

!BlockClosure methodsFor: 'private: private'!

copiedValues
	"This is here only for comparing"
	^copiedValues!

newContext
	"Construct a BlockContext for running
	this closure as a new process with no arguments."

	^BlockContext
		sender: nil
		receiver: self
		method: method
		arguments: #()!

pushCopiedValues: aContext
	"This is only used for simulation"
	method numCopiedValues = 1
		ifTrue: [aContext push: copiedValues]
		ifFalse: [copiedValues do: [:value | aContext push: value]]!

setMethod: meth outerContext: ctx copiedValues: values
	method _ meth.
	outerContext _ ctx.
	copiedValues _ values! !

!BlockClosure methodsFor: 'testing'!

refersToLiteral: anObject
	^method refersToLiteral: anObject!

{BooleanVar} refersTowardsLiteral: anObject
	^method refersTowardsLiteral: anObject! !

!BlockClosure methodsFor: 'backward compatibility'!

fixTemps
	"This message has three purposes:
		- To avoid creating circularities.  This is not an issue
	in HPS.
		- To preserve home variables across process boundaries,
	because all local variables get set to nil when a process
	is terminated.  Because circularities are no longer an issue,
	it is no longer necessary to set the local variables to nil,
	so this should not be an issue either.
		- To 'capture' home variables.  This is obscure at best,
	and there are other perfectly good ways to do it without
	having to go inside the implementation of contexts.

	Nevertheless, it is necessary to implement fixTemps
	for the time being, lest programs (such as the BitEditor
	and FormEditor) break."

	| newCopied |
	newCopied _ method numCopiedValues <= 1  "i.e. 0 or 1"
		ifTrue: [copiedValues]
		ifFalse: [copiedValues shallowCopy].
	outerContext == nil
		ifTrue:
			["No outer context.  Copy the copied values if any."
			^self class
				newMethod: method
				outerContext: nil
				copiedValues: newCopied].
	"There is an outer context.
	Copy it, and continue copying recursively
	until we reach a MethodContext."
	^self class
		newMethod: method
		outerContext: outerContext copyForFixTemps
		copiedValues: newCopied! !

!BlockClosure methodsFor: 'privileged evaluation'!

valueUninterruptably
	"Execute the receiver without interrupts (e.g. Process>>interruptWith: staved off).
	Note that this does not prevent preemption by higher priority processes.
	Use this facility VERY sparingly!!"

	^Processor activeProcess
		uninterruptablyDo: self!

valueUnpreemptively
	"Evaluate the receiver (block), without the possibility of preemption 
	by higher priority processes. Use this facility VERY sparingly!!"
	"Think about using Block>>valueUninterruptably first, and think about 
	using Semaphore>>critical: before that, and think about redesigning 
	your application even before that!! After you've done all that 
	thinking it would still behoove you to remember that no input will be 
	recognized, etc. while in this block (and Processor>>yield won't help). 
	Then, go right ahead and use it..."

	| activeProcess oldPriority |
	activeProcess _ Processor activeProcess.
	oldPriority _ activeProcess priority.
	activeProcess priority: Processor highestPriority.
	^self valueNowOrOnUnwindDo: [activeProcess priority: oldPriority]! !

!BlockClosure methodsFor: 'copying'!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance 
	variable. This doesn't make sense for BlockClosures."

	^self deepCopyError! !

!BlockClosure methodsFor: 'c++ evaluating'!

apply
	outerContext == nil ifFalse: [self error: 'Non-function block'].
	^self value!

apply: arg1
	outerContext == nil ifFalse: [self error: 'Non-function block'].
	^self value: arg1!

apply: arg1 with: arg2
	outerContext == nil ifFalse: [self error: 'Non-function block'].
	^self value: arg1 value: arg2!

apply: arg1 with: arg2 with: arg3
	outerContext == nil ifFalse: [self error: 'Non-function block'].
	^self value: arg1 value: arg2 value: arg3!

apply: arg1 with: arg2 with: arg3 with: arg4
	| args |
	outerContext == nil ifFalse: [self error: 'Non-function block'].
	args _ Array new: 4.
	args at: 1 put: arg1.
	args at: 2 put: arg2.
	args at: 3 put: arg3.
	args at: 4 put: arg4.
	^self valueWithArguments: args!

apply: arg1 with: arg2 with: arg3 with: arg4 with: arg5
	| args |
	outerContext == nil ifFalse: [self error: 'Non-function block'].
	args _ Array new: 5.
	args at: 1 put: arg1.
	args at: 2 put: arg2.
	args at: 3 put: arg3.
	args at: 4 put: arg4.
	args at: 5 put: arg5.
	^self valueWithArguments: args!

apply: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6
	| args |
	outerContext == nil ifFalse: [self error: 'Non-function block'].
	args _ Array new: 6.
	args at: 1 put: arg1.
	args at: 2 put: arg2.
	args at: 3 put: arg3.
	args at: 4 put: arg4.
	args at: 5 put: arg5.
	args at: 6 put: arg6.
	^self valueWithArguments: args!

apply: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6 with: arg7
	| args |
	outerContext == nil ifFalse: [self error: 'Non-function block'].
	args _ Array new: 7.
	args at: 1 put: arg1.
	args at: 2 put: arg2.
	args at: 3 put: arg3.
	args at: 4 put: arg4.
	args at: 5 put: arg5.
	args at: 6 put: arg6.
	args at: 7 put: arg7.
	^self valueWithArguments: args! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BlockClosure class
	instanceVariableNames: ''!
BlockClosure class comment:
'Methods addSelectorUnchecked:withMethod: and addSelector:withMethod: are overridden here so that the unique unwind method (valueOnUnwindDo:) can be marked and recorded when it is re-defined.
'!


!BlockClosure class methodsFor: 'instance creation'!

newCleanMethod: meth 
	"Answer a new instance of the receiver that defers execution of 
	expressions meth that has no access to outside names."

	^super new
		setMethod: meth
		outerContext: nil
		copiedValues: #()!

newCopyingMethod: meth size: size valuesFrom: aBlock
	"Answer a new instance of the receiver that defers execution of 
	expressions meth that has accesses outside names from aBlock."

	| values |
	size = meth numCopiedValues
		ifFalse:
			[self error: 'Wrong # of copied values'.
			^nil].
	values _ size = 1
		ifTrue: [aBlock value: 1]
		ifFalse: [(1 to: size) collect: [:i | aBlock value: i]].
	^super new setMethod: meth outerContext: nil copiedValues: values!

newFullMethod: meth outerContext: ctx
	"Answer a new instance of the receiver that defers execution of 
	expressions meth that has accesses outside names from ctx."

	^super new setMethod: meth outerContext: ctx copiedValues: #()! !

!BlockClosure class methodsFor: 'private: private'!

addSelector: selector withMethod: compiledMethod 
	"Intercept this so we can mark unwind method"

	super addSelector: selector withMethod:
		((selector == #valueOnUnwindDo: or: [selector == #valueNowOrOnUnwindDo:])
			ifTrue: [compiledMethod asUnwindMethod]
			ifFalse: [compiledMethod])!

newMethod: meth outerContext: ctx copiedValues: values
	^super new setMethod: meth outerContext: ctx copiedValues: values! !