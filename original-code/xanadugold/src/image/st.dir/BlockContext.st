'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:17 pm'!

Context subclass: #BlockContext
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Methods'!
BlockContext comment:
'Class BlockContext represents the context created for executing a block.  The receiver for the BlockContext is the BlockClosure being executed.'!


!BlockContext methodsFor: 'accessing'!

home
	"Answer the outermost MethodContext.
	Note that this may be nil."

	^receiver home  "receiver is a BlockClosure"!

homeReceiver
	"Answer the receiver from the context
	in which the receiver was defined."

	| home |
	home _ self home.
	^home isNil
		ifTrue: [nil]
		ifFalse: [home receiver]!

mclass 
	"Answer the class in which the home receiver's method was found."

	| home mclass |
	home _ self home.
	home == nil ifTrue:
		["We don't have a home, but the CompiledBlock
		should know."
		home _ method mclass.
		home isNil ifTrue: [home _ Object].  "this shouldn't happen!!"
		^home].
	home receiver class 
		selectorAtMethod: method homeMethod setClass: [:mc | mclass _ mc].
	^mclass!

outerContext
	"Answer the next outer context.
	If this is a clean or copying block,
	answer nil."

	^receiver outerContext!

selector
	"Answer the selector of the method that created the receiver."

	| home classOfMethod |
	home _ self home.
	home notNil
		ifTrue:
			[^home receiver class 
				selectorAtMethod: home method 
				setClass: [:ignored]].
	classOfMethod _ self mclass.
	^classOfMethod parserClass new parseSelector: self sourceCode!

sourceCode 
	"Answer the source form of the receiver's method."

	| homeMethod mclass selector |
	^method getSourceForUserIfNone:
		[homeMethod _ method homeMethod.
		^homeMethod getSourceForUserIfNone:
			["We have to decompile.
			Use the home class."
			mclass _ self mclass.
			selector _ mclass selectorAtMethod: homeMethod setClass: [:mc | mclass _ mc].
			mclass sourceCodeForMethod: homeMethod at: selector]]! !

!BlockContext methodsFor: 'unwinding'!

methodReturn: aValue
	"Answer the result to the receiver's home."

	| home ctx |
	home _ receiver home.
	ctx _ home sender.
	self unwindUpTo: home.
	ctx isNil ifTrue: [^self cannotReturn: aValue].
	ctx push: aValue.
	^ctx!

nonlocalReturn: innerResult through: firstUnwindContext 
	"Answer the result to the receiver's home's sender, executing all 
	the unwind blocks found on the way."

	| unwindCtx home result |
	home _ self home.
	result _ innerResult.
	unwindCtx _ firstUnwindContext.
	[unwindCtx notNil]
		whileTrue: 
			[| tc |
			"We consider ^-returns inside unwind-blocks, viz:
					self turnOnWater.
					[self bathe]
						valueNowOrOnUnwindDo: [^self shutOffWater]
			...bad style at least and pathological at worst; hence we don't make
			any provision for *these* ^-returns to trigger any unwind-blocks they
			have.  Nonetheless, these ^-returns are permitted, and the value returned
			overrides any inner ^-return's value.
			The trick when running unwind-blocks is to catch *their* ^-returns
			(if any), and short-circuit the nonlocalReturn:through: search
			to prevent infinitely recursive unwinds.  Luckily, there is a mechanism
			to catch those returns: unwind blocks!!  Doug Hofstadter, call your office..."
			tc _ thisContext.
			[(unwindCtx localAt: 1) value]
				valueOnUnwindDo: 
					[result _ thisContext sender home localAt: 1.
					tc resume].
			unwindCtx _ unwindCtx findNextUnwindUpTo: home].
	home sender resumeWith: result! !

!BlockContext methodsFor: 'testing'!

isBlockContext
	^true! !

!BlockContext methodsFor: 'printing'!

printOn: aStream
	| outerContext |
	outerContext _ receiver outerContext.
	outerContext == nil 
		ifTrue: [aStream nextPutAll: '[] optimized']
		ifFalse: [aStream nextPutAll: '[] in '.
				receiver outerContext printOn: aStream]! !

!BlockContext methodsFor: 'simulation-push/store/pop'!

pushCopiedValues: count
	| oldp |
	oldp _ stackp.
	receiver pushCopiedValues: self.
	stackp = (oldp + count)
		ifFalse:
			[self error: 'wrong # of copied values']!

pushInst: index outer: level
	self push: ((self outer: level - 1) outerContext receiver instVarAt: index + 1)!

pushLocal: index outer: level
	self push: ((self outer: level - 1) outerContext localAt: index + 1)!

pushReceiverOuter: level
	self push: (self outer: level - 1) outerContext receiver!

storePopInst: index outer: level
	(self outer: level - 1) outerContext receiver instVarAt: index + 1 put: self topPop!

storePopLocal: index outer: level
	(self outer: level - 1) outerContext localAt: index + 1 put: self topPop! !

!BlockContext methodsFor: 'simulation-control'!

methodReturnTop: levels
	^self methodReturn: self top! !

!BlockContext methodsFor: 'backward compatibility'!

finishCopyForFixTemps
	"Fix the temps of the receiver
	(a BlockClosure)."
	super finishCopyForFixTemps.
	receiver _ receiver fixTemps! !

!BlockContext methodsFor: 'private: private'!

findTemp: index do: aBlock elseDo: elseBlock
	" aBlock is guaranteed to do a ^ return "
	| outer left |
	outer _ self outerContext.
	outer == nil
		ifTrue:
			[left _ index]
		ifFalse:
			[outer findTemp: index do: aBlock elseDo:
				[:excess | left _ excess]].
	^self countTemps: left do: aBlock elseDo: elseBlock!

outer: level
	"Return the BlockClosure which is the receiver
	counting outward the given # of levels."
	^level = 0
		ifTrue: [receiver]
		ifFalse: [receiver outerContext outer: level - 1]!

privateTempAt: index
	^stack at: index!

privateTempAt: index put: value
	index <= method numArgs
		ifTrue:
			[(self confirm: 'I will restart from the beginning of this block.
Is that OK?')
				ifTrue: [self restart]
				ifFalse: [^value]].
	(index > method numTemps and:
	 [index <= (method numTemps + method numCopiedValues)])
		ifTrue:
			[self error: 'Storing into locally copied values is not allowed.'.
			^value].
	^stack at: index put: value! !