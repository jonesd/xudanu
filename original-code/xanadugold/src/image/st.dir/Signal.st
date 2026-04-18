'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:27 pm'!

Object subclass: #Signal
	instanceVariableNames: 'parent mayProceed notifierString nameClass nameMessage '
	classVariableNames: 'GenericSignal NoHandlerSignal NoHomeForReturnSignal ProceedErrorSignal TimeoutSignal WrongProceedabilitySignal '
	poolDictionaries: ''
	category: 'Kernel-Exception Handling'!
Signal comment:
'Class Signal identifies a type of exceptional condition.

Instance Variables:
	parent	<Signal | nil>  the Signal of which this one is a specialization
	mayProceed	<Boolean>  if true, raiseRequest is allowed
	notifierString	<String>  the string used for constructing a Notifier message
	nameClass	<Class>  the class from which this Signal may be obtained through a class message
	nameMessage	<Symbol>  send this message to the nameClass to obtain this Signal

Class Variables:
	GenericSignal	<Signal>  the root ancestor of all Signals
	HandleDoMethod	<CompiledMethod>  the method for handle:do: (used for finding handlers)
	NoHandlerSignal	<Signal>  the Signal indicating no handler was found
	NoHomeForReturnSignal	<Signal>  the Signal indicating an invalid ^-return
	ProceedErrorSignal	<Signal>  the Signal indicating an attempt to proceed from a raise
	TimeoutSignal	<Signal>  the Signal indicating that a timeout expired
	WrongProceedabilitySignal	<Signal>  the Signal indicating an invalid attempt to raiseRequest
'!


!Signal methodsFor: 'initialize-release'!

nameClass: aClass message: aSymbol
	"Initialize the instance variables of the receiver."

	nameClass _ aClass.
	nameMessage _ aSymbol!

notifierString: aString
	"Set aString to be a part of the notification message."

	notifierString _ aString!

parent: aSignal 
	"Set the parent of the receiver to be aSignal.  A signal handler 
	on a Signal's parent will catch the Signal as well."

	self parent: aSignal mayProceed: aSignal mayProceed!

parent: aSignal mayProceed: proceedBoolean
	"Set aSignal to be the  parent of the receiver.  Answer an error 
	if the receiver already has a parent."

	parent == nil ifFalse: [self error: 'Attempt to reset parent of a Signal'.  ^self].
	parent _ aSignal.
	mayProceed _ proceedBoolean! !

!Signal methodsFor: 'instance creation'!

newSignal
	"Answer a new Signal with the receiver as parent without proceedability."
	^self class basicNew parent: self!

newSignalMayProceed: proceedBoolean
	"Answer a new Signal with the receiver as parent
	and the specified proceedability. "
	^self class basicNew parent: self mayProceed: proceedBoolean! !

!Signal methodsFor: 'accessing'!

errorString
	" Answer the string for a Notifier,
	not including the parameter
	or any extra error string passed
	as an argument to raise.... "
	^notifierString isNil
		ifTrue: [parent errorString]
		ifFalse:
			[(notifierString isEmpty not and: [notifierString first = Character space])
				ifTrue: [parent errorString , notifierString]
				ifFalse: [notifierString]]!

errorStringExtra: extraString
	"Answer the string for a Notifier,
	not including the parameter,
	but including any extra error string passed
	as an argument to raise.... "

	| string |
	extraString isNil
		ifFalse:
			[(extraString isEmpty not and: [extraString first = Character space])
				ifFalse: [^extraString]].
	string _ self errorString.
	^extraString isNil
		ifTrue: [string]
		ifFalse: ["extraString first = Character space"
			string , extraString]!

errorStringExtra: extraString with: parameter
	"Answer the string for a Notifier,
	including the parameter if relevant. "
	| errorString |
	errorString _ self errorStringExtra: extraString.
	^errorString last = Character space
		ifTrue: [errorString , parameter printString]
		ifFalse: [errorString]!

PROBLEM
	"A hack to keep the BLAST name in the signal object."
	
	^nameMessage! !

!Signal methodsFor: 'testing'!

accepts: aSignal
	"Answer true if a handler with this pattern
	should be run in response to aSignal."
	^aSignal inheritsFrom: self!

inheritsFrom: aSignal
	"Answer true if a handler with pattern aSignal
	should be run in response to this Signal."
	^aSignal == self or: [parent notNil and: [parent inheritsFrom: aSignal]]!

mayProceed
	"Answer whether control may proceed
	after this signal is raised. "
	^mayProceed! !

!Signal methodsFor: 'printing'!

printOn: aStream
	(nameClass notNil and:
	 [(nameClass class includesSelector: nameMessage) and:
	  [| var | var _ (nameClass class compiledMethodAt: nameMessage) returnsStaticVariable.
	   var notNil and: [var value == self]]])
		ifTrue:
			[nameClass printOn: aStream.
			aStream space; nextPutAll: nameMessage]
		ifFalse:
			[super printOn: aStream.
			notifierString isNil
				ifTrue:
					[aStream nextPutAll: ' with parent: '.
					parent printOn: aStream]
				ifFalse:
					[aStream nextPutAll: ' with notifierString '.
					notifierString printOn: aStream]]! !

!Signal methodsFor: 'handling'!

{void} delayTry: aBlock catch: aHandler
	"ProbList delayTry: [foo] catch: [:broken {XuPromise} | bar]
	translates to
	DELAY_TRY_BEGIN(ProbList) {
		foo
	} DELAY_CATCH(broken) {
		bar
	} DELAY_TRY_END;"

	| collector {CollectionAgent} aPromise {XuPromise} |
	XuPromise newCollector: self.
	collector := XuPromise collector.
	[aBlock value] valueNowOrOnUnwindDo: [XuPromise popCollector].
	XuPromise force.
	aPromise _ collector firstPromise.
	[aPromise ~~ NULL] whileTrue: [
		aHandler value: aPromise.
		aPromise _ aPromise next].!

handle: handlerBlock do: doBlock
	"Execute the doBlock.  If an exception occurs
	whose Signal is included in the receiver,
	execute the handlerBlock."

	^doBlock value! !

!Signal methodsFor: 'raising'!

newException
	"Answer an appropriate new Exception object.
	Subclasses may wish to override this."
	^Exception new!

raise
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may not choose to proceed if this message is sent."

	^self
		raiseWith: nil
		startAbove: thisContext
		extraString: nil
		proceed: false!

raiseErrorString: aString
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may not choose to proceed if this message is sent.
	The exception uses aString as its error message."

	^self
		raiseWith: nil
		startAbove: thisContext
		extraString: aString
		proceed: false!

raiseRequest
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may choose to proceed if this message is sent."

	^self
		raiseWith: nil
		startAbove: thisContext
		extraString: nil
		proceed: true!

raiseRequestErrorString: aString
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may choose to proceed if this message is sent.
	The exception uses aString as its error message."

	^self
		raiseWith: nil
		startAbove: thisContext
		extraString: aString
		proceed: true!

raiseRequestReturn
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may choose to proceed if this message is sent.
	The search begins at the sender of the home context of thisContext 
	sender, instead of at thisContext sender."

	^self
		raiseReturnWith: nil
		startAbove: thisContext
		extraString: nil
		proceed: true!

raiseRequestReturnErrorString: aString
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may choose to proceed if this message is sent.
	The search begins at the sender of the home context of thisContext 
	sender, instead of at thisContext sender.  The exception uses 
	aString as its error message."

	^self
		raiseReturnWith: nil
		startAbove: thisContext
		extraString: aString
		proceed: true!

raiseRequestReturnWith: parameter 
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may choose to proceed if this message is sent.
	The search begins at the sender of the home context of thisContext 
	sender, instead of at thisContext sender.  The exception will 
	answer the argument when asked for its parameter."

	^self
		raiseReturnWith: parameter
		startAbove: thisContext
		extraString: nil
		proceed: true!

raiseRequestReturnWith: parameter errorString: aString
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may choose to proceed if this message is sent.
	The search begins at the sender of the home context of thisContext 
	sender, instead of at thisContext sender.  The exception will 
	answer the first argument when asked for its parameter, and 
	will use aString as its error string."

	^self
		raiseReturnWith: parameter
		startAbove: thisContext
		extraString: aString
		proceed: true!

raiseRequestWith: parameter 
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may choose to proceed if this message is sent.
	The exception will answer the argument when asked for its parameter"

	^self
		raiseWith: parameter
		startAbove: thisContext
		extraString: nil
		proceed: true!

raiseRequestWith: parameter errorString: aString
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may choose to proceed if this message is sent.
	The exception will answer the first argument when asked for its 
	parameter, and will use aString as its error string"

	^self
		raiseWith: parameter
		startAbove: thisContext
		extraString: aString
		proceed: true!

raiseReturn
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may not choose to proceed if this message is sent.
	The search begins at the sender of the home context of thisContext 
	sender, instead of at thisContext sender."

	^self
		raiseReturnWith: nil
		startAbove: thisContext
		extraString: nil
		proceed: false!

raiseReturnErrorString: aString
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may not choose to proceed if this message is sent.
	The search begins at the sender of the home context of thisContext 
	sender, instead of at thisContext sender.  The exception uses 
	aString as its error message."

	^self
		raiseReturnWith: nil
		startAbove: thisContext
		extraString: aString
		proceed: false!

raiseReturnWith: parameter 
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may not choose to proceed if this message is sent.
	The search begins at the sender of the home context of thisContext 
	sender, instead of at thisContext sender.  The exception will 
	answer the argument when asked for its parameter."

	^self
		raiseReturnWith: parameter
		startAbove: thisContext
		extraString: nil
		proceed: false!

raiseReturnWith: parameter errorString: aString
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may not choose to proceed if this message is sent.
	The search begins at the sender of the home context of thisContext 
	sender, instead of at thisContext sender.  The exception will 
	answer the first argument when asked for its parameter, and 
	will use aString as its error string."

	^self
		raiseReturnWith: parameter
		startAbove: thisContext
		extraString: aString
		proceed: false!

raiseWith: parameter 
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may not choose to proceed if this message is sent.
	The exception will answer the argument when asked for its parameter"

	^self
		raiseWith: parameter
		startAbove: thisContext
		extraString: nil
		proceed: false!

raiseWith: parameter errorString: aString
	"Raise the receiver, that is, create an exception on the receiver 
	and have it search the execution stack for a handler that accepts 
	the receiver, then evaluate the handler's exception block.  The 
	exception block may not choose to proceed if this message is sent.
	The exception will answer the first argument when asked for its 
	parameter, and will use aString as its error string"

	^self
		raiseWith: parameter
		startAbove: thisContext
		extraString: aString
		proceed: false! !

!Signal methodsFor: 'private: private-raising'!

raiseReturnWith: parameter startAbove: context extraString: str proceed: aBoolean
	| home |
	home _ context sender home.
	home isNil
		ifTrue:
			["The context is an optimized block.
			We can't do anything about this.
			Raise an error."
			^self raiseReturnError: parameter startAbove: context]
		ifFalse:
			[^self
				raiseWith: parameter
				startingAt: home sender
				extraString: str
				proceed: aBoolean]!

raiseWith: parameter startAbove: context extraString: str proceed: aBoolean
	^self
		raiseWith: parameter
		startingAt: context sender
		extraString: str
		proceed: aBoolean!

raiseWith: parameter startingAt: context extraString: str proceed: aBoolean
	"This is where signalling is actually implemented."

	| ex |
	(aBoolean and: [mayProceed not])
		ifTrue:
			[^Signal wrongProceedabilitySignal
				raiseWith: self
				startingAt: context
				extraString: nil
				proceed: false].
	ex _ self newException
				signal: self
				parameter: parameter
				extraString: str
				proceedBlock:
					(aBoolean
						ifTrue: [[:value | ^value]]
						ifFalse: [nil]).
	^ex propagateFrom: context! !

!Signal methodsFor: 'private: private'!

raiseReturnError: parameter startAbove: context
	"Raise an error indicating that an attempt was made
	to raiseReturn from an optimized block."
	| ex |
	ex _ self newException
				signal: self
				parameter: parameter
				extraString: nil
				proceedBlock: [nil].
	^Signal noHomeForReturnSignal
		raiseWith: ex
		startingAt: context sender
		extraString: nil
		proceed: false! !

!Signal methodsFor: 'copying'!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance 
	variable. This doesn't make sense for Signals."

	^self deepCopyError! !

!Signal methodsFor: 'X++ translation'!

DOTgetProblemName
	"The problem name that would be in the Problem object in C++"
	^notifierString copyFrom: 7 to: notifierString size - 1! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Signal class
	instanceVariableNames: ''!


!Signal class methodsFor: 'class initialization'!

initialize
	"Signal initialize"
	| sig |
	"Initialize the generic Signal."
	sig _ self basicNew
		notifierString: 'An unknown Signal with: ';
		nameClass: self message: #genericSignal.
	sig parent: nil mayProceed: true.
	GenericSignal isNil
		ifTrue: [GenericSignal _ sig]
		ifFalse: [GenericSignal become: sig].
	"Initialize Signal constants in this class."
	NoHandlerSignal _ GenericSignal newSignal
		notifierString: 'No handler was found for an Exception: ';
		nameClass: self message: #noHandlerSignal.
	sig _ Object errorSignal.
	NoHomeForReturnSignal _ sig newSignal
		notifierString: 'Attempt to raiseReturn from an optimized block: ';
		nameClass: self message: #noHomeForReturnSignal.
	ProceedErrorSignal _ sig newSignal
		notifierString: 'A handler tried to proceed from a non-proceedable Exception: ';
		nameClass: self message: #proceedErrorSignal.
	WrongProceedabilitySignal _ sig newSignal
		notifierString: 'The raiser and the Signal do not agree about proceedability: ';
		nameClass: self message: #wrongProceedabilitySignal.
	TimeoutSignal _ sig newSignal
		notifierString: 'Timeout: ';
		nameClass: self message: #timeoutSignal! !

!Signal class methodsFor: 'instance creation'!

new
	"Make a new signal, with parent Object>>errorSignal."

	^Object errorSignal newSignal! !

!Signal class methodsFor: 'Signal constants'!

noHandlerSignal
	"Answer the Signal used to indicate that
	no handler was found for an exception."
	^NoHandlerSignal!

noHomeForReturnSignal
	"Answer the Signal used to indicate an
	attempt to raiseReturn from an optimized block."
	^NoHomeForReturnSignal!

proceedErrorSignal
	"Answer the Signal used to indicate that
	a handler tried to proceed when the signaller
	requested termination."
	^ProceedErrorSignal!

wrongProceedabilitySignal
	"Answer the Signal used to indicate that
	the signaller and the Signal disagree about
	whether control may proceed. "
	^WrongProceedabilitySignal! !

!Signal class methodsFor: 'private: private'!

addSelector: selector withMethod: compiledMethod 
	"Intercept this so we can mark the handler method"

	super addSelector: selector withMethod:
		(selector == #handle:do:
			ifTrue: [compiledMethod asHandlerMethod]
			ifFalse: [compiledMethod])!

genericSignal
	"Return the generic Signal.  This should only be used by
	special mechanisms like the debugger."
	"WARNING:  do not attempt to catch Signal>>genericSignal,
	doing so may lead to runaway recursive errors or unkillable
	processes!!"

	^GenericSignal! !

Signal initialize!
