'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:26 pm'!

Object subclass: #Exception
	instanceVariableNames: 'signal parameter extraString proceedBlock initialContext handlerContext firstUnwindContext '
	classVariableNames: 'EmergencyHandler '
	poolDictionaries: ''
	category: 'Kernel-Exception Handling'!
Exception comment:
'Class Exception represents an occurrence of an exceptional condition.

Instance Variables:
	signal	<Signal>
	parameter	<Object>  the with: argument to the raise... message
	extraString	<String | nil>  the errorString: argument to the raise... message
	proceedBlock	<BlockClosure>  the block to evaluate if the handler says to proceed
	initialContext	<Context>  the initial context where the search started
	handlerContext	<Context>  the context for the handle:do:
	firstUnwindContext	<Context>

Class Variables:
	EmergencyHandler	<BlockClosure> an emergency handler for unhandled exceptions
'!


!Exception methodsFor: 'initialize-release'!

signal: sig parameter: par extraString: str proceedBlock: pb
	"Set the instance variables of the receiver."

	signal _ sig.
	parameter _ par.
	extraString _ str.
	proceedBlock _ pb! !

!Exception methodsFor: 'accessing'!

asProblem
"This is just a hook to allow 'foo asProblem' to be translated to '&PROBLEM(foo)' "

	^self.!

errorString
	"Answer the String that combines the system error message with the message for the receiver."
		
	^signal errorStringExtra: extraString with: parameter!

handlerContext
	"Answer the (block) context that will be evaluated when the signal is raised."

	^handlerContext!

parameter
	"Answer the object that is the argument to raising the exception represented by the receiver."

	^parameter!

PROBLEM
	^signal PROBLEM!

signal
	"Answer the signal associated with the receiver."

	^signal!

willProceed
	"Answer whether there is a set of actions (a block) to be evaluated upon proceeding."

	^proceedBlock notNil! !

!Exception methodsFor: 'handler responses'!

proceed
	"Answer nil as the value of the signal message.
	Execution continues in the signaller.
	The stack is only unwound up to the signaller."

	^self proceedWith: nil!

proceedDoing: aBlock
	"Answer the result of executing aBlock
	as the value of the signal message.
	The block is executed in the handler
	context of the signaller, so (for example)
	it can raise a different signal in place
	of the original one.
	Execution continues in the signaller.
	The stack is only unwound up to the signaller."

	proceedBlock isNil
		ifTrue: [Signal proceedErrorSignal raiseWith: self  "can't proceed"]
		ifFalse:
			[self unwindTo: initialContext.
			thisContext terminateTo: initialContext.
			^aBlock value]!

proceedWith: aValue
	"Answer aValue as the value of the signal message.
	Execution continues in the signaller.
	The stack is only unwound up to the signaller."

	proceedBlock isNil
		ifTrue: [Signal proceedErrorSignal raiseWith: self  "can't proceed"]
		ifFalse: [proceedBlock value: aValue]!

reject
	"The handler has decided it doesn't want to
	handle this Signal.  Continue searching for
	another handler."

	^self propagatePrivateFrom: handlerContext sender!

restart
	"Restart the handle:do: expression."

	self unwind.
	handlerContext restart.
	thisContext terminateTo: handlerContext!

restartDo: aBlock
	"Restart the handle:do: expression,
	but execute a different do: block."

	self unwind.
	handlerContext localAt: 2 put: aBlock.
	handlerContext restart.
	thisContext terminateTo: handlerContext!

return
	"Unwind the stack and return nil
	as the value of the handle:do: expression."

	^self returnWith: nil!

returnDoing: aBlock
	"Unwind the stack and return the result
	of executing aBlock (after unwinding)
	as the value of the handle:do: expression."

	self unwind.
	thisContext terminateTo: handlerContext.
	^aBlock value!

returnWith: aValue
	"Unwind the stack and return aValue
	as the value of the handle:do: expression."

	self unwind.
	thisContext terminateTo: handlerContext.
	^aValue! !

!Exception methodsFor: 'raising'!

propagateFrom: startContext
	"Search for, and run, an appropriate handler."

	initialContext _ startContext.
	firstUnwindContext _ nil.
	^self propagatePrivateFrom: startContext! !

!Exception methodsFor: 'private: private'!

findHandlerFrom: startContext
	"Search for and return an appropriate handler.
	Set handlerContext and firstUnwindContext.
	If no handler is found, return nil."
	| ctx cm skip |
	ctx _ startContext.
	[ctx == nil ifTrue: [^nil].  "no handler"
	cm _ ctx method.
	(cm isMarkedForHandle)
		ifTrue: [(ctx receiver accepts: signal) not]
		ifFalse:
			[(firstUnwindContext == nil and: [cm isMarkedForUnwind])
				ifTrue: [firstUnwindContext _ ctx].
			true]]
		whileTrue:
			["In VI2.4, the test here was:
				(cm isMarkedForPropagate and: [ctx receiver willProceed not]) "
			ctx _ (cm isMarkedForPropagate and:
					[(skip _ ctx receiver handlerContext) notNil])
				ifTrue:
					["Skip over signals already being propagated"
					skip findNextMarkedUpTo: nil]
				ifFalse: [ctx findNextMarkedUpTo: nil]].
	handlerContext _ ctx.
	^ctx localAt: 1!

noHandlerAction: result
	"Decide what to do when a handler returned
	without choosing a control option."
	"In VI2.4, the algorithm was:
		^self willProceed
			ifTrue: [self proceedWith: result]
			ifFalse: [self returnWith: result]"
	^self returnWith: result!

propagatePrivateFrom: startContext
	"Search for, and run, an appropriate handler.
	This is called both initially and after a reject.
	In the latter case, we don't reset firstUnwindContext."
	| handler ex2 result |
	handler _ self findHandlerFrom: startContext.
	handler == nil ifTrue:
		[(Signal noHandlerSignal accepts: signal)
			ifTrue:
				["If this was already an unhandled exception
				exception that was rejected, just start the
				emergency handler--parameter is the exception
				that couldn't be handled originally"
				^EmergencyHandler value: parameter value: parameter initialContext]
			ifFalse:
				["No handler.  Convert this exception into
				an unhandled exception exception
				(no, you're not seeing double here.)"
				ex2 _ self class new
					signal: Signal noHandlerSignal
					parameter: self
					extraString: nil
					proceedBlock: nil.
				handler _ ex2 findHandlerFrom: initialContext.
				handler == nil ifTrue:
					["No handler for this either.  Emergency!!"
					^EmergencyHandler value: self value: initialContext].
				result _ handler value: ex2.
				"The handler returned without choosing an option."
				^ex2 noHandlerAction: result]].
	result _ handler value: self.
	"The handler returned without choosing an option."
	^self noHandlerAction: result!

unwind
	"Unwind the stack to the handlerContext,
	executing unwind blocks.  Start at the context
	we found during the signal search, if any."
	| ctx |
	ctx _ firstUnwindContext.
	ctx isNil ifTrue: [^self].
	[ctx == nil] whileFalse:
		[(ctx localAt: 1) value.
		ctx _ ctx findNextUnwindUpTo: handlerContext]!

unwindTo: aContext
	"Unwind the stack to aContext,
	executing unwind blocks."
	handlerContext _ aContext.
	firstUnwindContext _ thisContext findNextUnwindUpTo: aContext.
	self unwind! !

!Exception methodsFor: 'private: debugger-private'!

checkInitialContextIf: fakeCtx with: realCtx

	initialContext == fakeCtx 
		ifTrue: [initialContext _ realCtx].!

initialContext

	^initialContext!

rePropagateFrom: startContext
	"Answer a context of 'propagatePrivateFrom:'."

	| ctx propCtx |
	ctx _ [self propagatePrivateFrom: startContext] newContext.
	propCtx _ ctx stepUntilVisibleEffect step.
	propCtx sender: thisContext sender sender sender.
	^propCtx! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Exception class
	instanceVariableNames: ''!


!Exception class methodsFor: 'class initialization'!

initialize
	"Install the emergency handler"
	"Exception initialize"

	self emergencyHandler: [:exception :context | self emergency: exception from: context]! !

!Exception class methodsFor: 'emergency handler'!

emergency: exception from: context
	"Define a default emergency handler.
	This one is appropriate for development
	environments, but not for runtime."

	(Object userInterruptSignal accepts: exception signal)
		ifTrue: [NotifierView
					openException: exception]
		ifFalse: [NotifierView
					openContext: context
					label: 'Unhandled exception: ' , exception errorString
					contents: context shortStack
					proceedable: exception willProceed]!

emergencyHandler: aBlock
	"Define an emergency handler
	for unhandled exceptions."
	EmergencyHandler _ aBlock! !

!Exception class methodsFor: 'examples'!

exampleCollectionAt
	"Access a collection out-of-bounds and catch the error."
	"Exception exampleCollectionAt"

	| collection var |
	collection _ OrderedCollection new.
	1 to: 10 do: [:i | collection add: i].
	Collection indexNotFoundSignal
		handle: 
			[:ex | 
			Transcript cr; show: 'Exceeded collection size'.
			ex return]
		do: [1 to: 20 do: 
				[:i | 
				var _ collection at: i.
				Transcript space; show: var printString]]!

exampleCollectionRemove
	"Signal removing nonexistent element."
	"Exception exampleCollectionRemove"

	| collection |
	collection _ OrderedCollection new.
	1 to: 10 do: [:i | collection add: i].

	Object notFoundSignal 
		handle: [:ex | Transcript cr; show: 'An element not found'. 
				ex return]
		do: [collection remove: 17.]!

exampleDictionaryAt
	"Signal reading at non-existing key. The handler creates the key
	and restarts to read at the key."
	"Exception exampleDictionaryAt"

	| aDictionary value |
	aDictionary _ Dictionary new.
	aDictionary at: #C put: $c.

	Dictionary keyNotFoundSignal
		handle: [:ex | aDictionary at: #A put: $a. ex restart]
		do: [value _ aDictionary at: #A].
	Transcript cr; show: value printString, ' in ', aDictionary printString!

exampleDictionaryRemoveKey
	"Signal removing at non-existing key. The handler simply shows an error message
	and aborts."
	"Exception exampleDictionaryRemoveKey"

	| aDictionary |
	aDictionary _ Dictionary new.
	aDictionary at: #C put: $c.

	Dictionary keyNotFoundSignal
		handle: [:ex | Transcript cr; show: ex parameter, ' not found'. 
				ex return]
		do: [aDictionary removeKey: #A].!

exampleDivideByZeroAbort
	"Exception exampleDivideByZeroAbort"

	-2.0 to: 2.0 do: [:i |
	Number divisionByZeroSignal
		handle: [:ex | Transcript cr; show: 'divideByZero abort'. 
				ex return]
		do: [10.0 / i. Transcript cr; show: i printString]].!

exampleHandlerCollection
	"Exception exampleHandlerCollection"

	| sg1 sg2 sg3 |
	sg1 _ Signal new notifierString: 'sig1'.
	sg2 _ Signal new notifierString: 'sig2'.
	sg3 _ Signal new notifierString: 'sig3'.
	HandlerCollection new
		on: sg1 handle: [:ex | Transcript cr; show: 'handler of sg1'];
		on: sg2 handle: [:ex | Transcript cr; show: 'handler of sg2'];
		on: sg3 handle: [:ex | Transcript cr; show: 'handler of sg3'];
		handleDo: [sg2 raise].
	Transcript cr; show: 'end.'!

exampleReturnDoing
	"When a signal is raised in a critical region, one needs to unwind 
	the semaphore for the critical region before the handler is executed. 
	'returnDoing:' allows the unwind to be done before the handler gets 
	control."
	"Exception exampleReturnDoing"

	| sem |
	sem _ Semaphore forMutualExclusion.
	Object errorSignal handle: [:ex | ex returnDoing: [sem critical: [Transcript cr; show: 'handler block']]]
		do: [sem
				critical: 
					[Transcript cr; show: 'do block'.
					Object errorSignal raise]]
	"The following code causes deadlock."
	"| sem | 
	sem _ Semaphore forMutualExclusion. 
	Object errorSignal 
	handle: [:ex | sem critical: [Transcript cr; show: 'handler block']] 
	do: [sem critical: [Transcript cr; show: 'do block'. 
	Object errorSignal raise]]"!

exampleSignalCollection
	"Signal sig1 and sig2 are caught by the handler,
	but signal sig3 is not caught and a Notifier view 
	shows up." 
	"Exception exampleSignalCollection"

	| sig1 sig2 sig3 sc |
	sig1 _ Signal new notifierString: 'sig1'.
	sig2 _ Signal new notifierString: 'sig2'.
	sig3 _ Signal new notifierString: 'sig3'.
	sc _ SignalCollection new.
	sc add: sig1; add: sig2.
	sc handle: [:ex | Transcript cr; show: ex signal printString]
		do: [sig1 raise].
	sc handle: [:ex | Transcript cr; show: ex signal printString]
		do: [sig2 raise].
	sc handle: [:ex | Transcript cr; show: ex signal printString]
		do: [sig3 raise].!

exampleSignalHierarchy
	"Exception exampleSignalHierarchy"

	Object errorSignal
		handle: [:ex | Transcript cr; show: 'Unexpected error....abort. '. 
				ex return]
		do: [self clientA].
	Transcript cr; show: 'done.'

	"The hierarchy of signal used in this example is as follows.

	Object errorSignal
		Object notFoundSignal
			Object indexNotFoundSignal
				Object subscriptOutOfBoundsSignal
				Object nonIntegerIndexSignal
			Dictionary keyNotFoundSignal
			Dictionary valueNotFoundSignal"!

exampleStreamNextPastEnd
	"Signal reading past the end of the stream.
	Exception handling removes checking for EOF every time 
	in the main loop as in the following conventional code:
	
	[fileStream atEnd] whileFalse:
		[Transcript show: fileStream next printString].
or 
	[(char _ fileStream next) == nil] whileFalse:
		[Transcript show: char printString]"
	"Exception exampleStreamNextPastEnd"

	| fileStream fileName |
	fileStream _ (fileName _ Filename named: 'tempFile') writeStream.
	fileStream nextPutAll: 'ua jal twa ba klm'.
	fileStream close.
	fileStream _ fileName readStream.

	fileStream class endOfStreamSignal
		handle: [:ex | fileStream close.
				ex return]
		do: [[Transcript show: fileStream next printString] repeat].
	fileName delete!

exampleStreamPositionOutOfBounds
	"Signal when you set position out of bounds of the stream. 
	The handler resets position to half the size of the position."
	"Exception exampleStreamPositionOutOfBounds"

	| stream pos |
	stream _ ReadStream with: #(ua ba twa jal klm).
	pos _ 24.
	stream class positionOutOfBoundsSignal 
		handle: [:ex | pos _ ex parameter. pos _ pos // 2. 
				Transcript cr; show: pos printString.
				ex restart]
		do: [stream position: pos].
	Transcript cr; show: stream next!

exampleUnwindSemaphore
	"Unwind inconsistency of semaphore state caused by error."
	"Exception exampleUnwindSemaphore"

	| semaphore |
	semaphore _ Semaphore new.
	[semaphore wait. Transcript cr; show: 'completed'] forkAt: 4.
	Processor yield.
	Object errorSignal
		handle: 
			[:ex | Transcript cr; show: 'error occurred'. ex return]
		do: 
		[[Object errorSignal raise.
		semaphore signal.
		Transcript cr; show: 'normal end.'] 
			valueOnUnwindDo: 
				[semaphore signal. Transcript cr; show: 'unwind']].


	"Usually we use the following style so that we don't have to
	write redundant code.

	[Object errorSignal raise.] 
		valueNowOrOnUnwindDo: [semaphore signal]."!

exampleUserInterruptSignal
	"Control-C causes a pause for one second."
	"Exception exampleUserInterruptSignal"

	Object userInterruptSignal
		handle: [:ex | (Delay forSeconds: 1) wait.
						ex proceed]
		do: [1 to: 100 do: 
				[:i | Transcript show: ' ', i printString]]! !

!Exception class methodsFor: 'private: private'!

addSelector: selector withMethod: compiledMethod 
	"Intercept this so we can mark the propagate method"

	super addSelector: selector withMethod:
		(selector == #propagateFrom:
			ifTrue: [compiledMethod asPropagateMethod]
			ifFalse: [compiledMethod])! !

!Exception class methodsFor: 'private: private-examples'!

clientA

	| v |
	#('2' 7 5.5 -4 'abc' '1.5') do: 
		[:index |
		Object notFoundSignal
			handle: [:ex | Transcript show: ' not found.'. 
					ex return]
			do: [v _ self clientB: index.
				Transcript cr; show: v printString]]!

clientB: index

	| hc |
	hc _ HandlerCollection new.
	hc on: Object indexNotFoundSignal 
		handle: [:ex | Transcript cr; show: 'index: ', ex parameter printString.
				ex reject].
	hc on: Dictionary keyNotFoundSignal
		handle: [:ex | Transcript cr; show: 'key: ', ex parameter printString.
				ex reject].
	hc handleDo: [^self clientC: index]!

clientC: index
	| i collection hc |
	
	i _ index.
	collection _ OrderedCollection with: 'A' with: 'B' with: 'C'.
	hc _ HandlerCollection new.
	hc on: Object nonIntegerIndexSignal 
		handle: [:ex | i _ ex parameter.
				i isString ifTrue: [i _ i asNumber. ex restart].
				i respondsToArithmetic ifTrue: [i _ i truncated. ex restart].
				ex reject "can't handle here"].
	hc on: Object subscriptOutOfBoundsSignal
		handle: [:ex | i _ ex parameter.
				i <= 0 ifTrue: [ex reject "can't handle here"].
				i _ i \\ 3. ex restart].
	hc handleDo: [^collection at: i]! !

Exception initialize!
