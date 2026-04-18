'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:30 pm'!

ByteCodeStream subclass: #CodeStream
	instanceVariableNames: 'outerStream needsFrame hybrid usesOuter canCopy tempStores usedArgs usedTemps copiedVars finalNumTemps innerBlocks forContext forNonImmediate deferredBlocks method allSourceMaps '
	classVariableNames: ''
	poolDictionaries: 'OpcodePool '
	category: 'System-Compiler-Support'!
CodeStream comment:
'I accumulate code for the compiler.

Instance variables:
	needsFrame	<Boolean>  "if true, this method needs a frame"
	hybrid	<Boolean>  "if true, contexts for this method should be created hybrid"
	usesOuter	<Integer>  "nesting level of outermost scope that must be retained"
	canCopy	<Boolean>
	tempStores	<nil | Array of: SmallInteger>
	usedArgs	<nil | ArrayedCollection of: (Array with: Integer with: Integer)>
	usedTemps	<nil | ArrayedCollection of: (Array with: Integer with: Integer)>
	copiedVars	<nil | ArrayedCollection of: (Array with: Integer with: Integer)>
	finalNumTemps	<nil | Integer>  "total numTemps, including generated temps, at end of method"
	fullBlocks	<nil | OrderedCollection of: CompiledMethod>
	forContext	<Boolean | nil>
	forNonImmediate	<Boolean | nil>
	deferredBlocks	<nil | OrderedCollection of: DeferredBlock>
	allSourceMaps	<nil | Dictionary key: CompiledMethod value: (Array with: (OrderedCollection of: (Association key: Integer value: Integer) with: NameScope)>

tempStores keeps track of the number of stores to each temporary variable bound in this scope.  A negative value means this temporary has been stored into from an inner scope; a positive value counts the number of stores at this level.

usedArgs and usedTemps keep track of outer-scope variables that are read in this scope.  Eacn entry is a pair of (scope, index); index = -1 means the receiver (self).  If canCopy is true at the end of the block, we can use a copying block rather than a full block.  When recompiling the block as a copying block, copiedVars holds the list of outer variables that have been copied locally.  finalNumTemps holds the final value of numTemps from the first compilation, which may be larger than numTemps if there were any in-line blocks (e.g. for ifTrue:) with local temporaries, or any compiler-generated temporaries (e.g. for arithmetic loops).

fullBlocks keeps track of block methods whose last literal must be changed, when the method at this level is completed, to a reference to this method.

forContext is nil if no instance variables have been referenced, true if we are compiling in a sub- or superclass of Context and an instance variable has been referenced, and false otherwise.

forNonImmediate is nil until it has been computed; then it is true if we are compiling in a class that cannot be (a superclass of) an immediate class (SmallInteger or Character), and false otherwise.

deferredBlocks is shared among all the code streams for a given method (i.e. the method stream and all the interior block streams).  It holds DeferredBlocks, which represent blocks whose nature (copying or full) cannot be determined until the end of some enclosing scope.  These are revisited at the end of compiling the entire method.

The entries in allSourceMaps save both the actual source-to-PC map and the scope chain.
'!


!CodeStream methodsFor: 'initialize-release'!

initialize
	super initialize.
	needsFrame _ hybrid _ false.
	usesOuter _ 256.  "infinity"
	canCopy _ true!

makeMethod: methodNode
	"Return an appropriate compiled code object"
	| deferred |
	deferred _ deferredBlocks.  "makeMethodOfClass: sets it to nil"
	self makeMethodOfClass: CompiledMethod local: false.
	"Revisit all ambiguous blocks"
	deferred == nil
		ifFalse:
			[deferred do: [:dfb | dfb complete]].
	^method!

newBlockScope
	| inner |
	inner _ super newBlockScope.
	sourceMap isNil ifFalse: [inner saveSourceMap: allSourceMaps].
	^inner!

outerStream: aCodeStream finalNumTemps: tempCount
	"Set the outer block and total temp count
	when compiling a block."
	outerStream _ aCodeStream.
	finalNumTemps _ tempCount!

saveSourceMap
	super saveSourceMap.
	allSourceMaps _ IdentityDictionary new: 8! !

!CodeStream methodsFor: 'accessing'!

addTemporaries: temps
	| mark stores |
	mark _ super addTemporaries: temps.
	mark notNil
		ifTrue:
			[stores _ Array new: temps size withAll: 0.
			tempStores _ tempStores == nil
						ifTrue: [stores]
						ifFalse: [tempStores , stores]].
	^mark!

bindCopied: vars
	"Record the locations of
	the copied values in a copying block."
	copiedVars _ vars.
	code nextPut: OpCopyValues
		with: vars size.
	depth _ depth + vars size.
	depth > maxDepth ifTrue: [maxDepth _ depth]!

deferredBlocks: blocks
	deferredBlocks _ blocks!

homeStream
	"Answer the outermost (method) stream
	for the current compilation."

	outerStream == nil
		ifTrue: [^self]
		ifFalse: [^outerStream homeStream]!

method
	"For deferred block fixups"
	^method!

numTemps
	"This is only meant to be used by
	an outer codeStream."
	^numTemps!

sourceInfo
	^method withAllBlockMethods collect: [:m | allSourceMaps at: m]!

usedArgs
	"This is only meant to be used by
	an outer codeStream."
	^usedArgs!

usedTemps
	"This is only meant to be used by
	an outer codeStream."
	^usedTemps!

usedVars
	"This is only meant to be used by
	an outer codeStream."
	^usedArgs == nil
		ifTrue: [usedTemps]
		ifFalse:
			[usedTemps == nil
				ifTrue: [usedArgs]
				ifFalse: [usedArgs , usedTemps]]! !

!CodeStream methodsFor: 'testing'!

canCopy
	canCopy ifFalse: [^false].
	"Check potentially copied temps"
	usedTemps == nil ifTrue: [^true].
	usedTemps do:
		[:var |
		(self findStore: (var at: 2) scope: (var at: 1)) < 0
			ifTrue: [^false]].
	^true!

inBlock
	^nesting > 0!

isForNonImmediate
	"Return true if this class is definitely not
	an immediate class or a superclass of one,
	and false otherwise."
	forNonImmediate == nil ifFalse: [^forNonImmediate].
	class instSize > 1  "actually, should be 0 in the present implementation..."
		ifTrue:  "can't be a super of an immediate"
			[^forNonImmediate _ true].
	^forNonImmediate _ (class = SmallInteger or: [class = Character or: [(SmallInteger inheritsFrom: class) or: [Character inheritsFrom: class]]]) not!

usesOuter
	^usesOuter! !

!CodeStream methodsFor: 'code generation-loads and stores'!

pushConstant: lit
	| index | 
	self push.
	lit == nil ifTrue: [code nextPut: OpLoadNil.  ^self].
	lit == true ifTrue: [code nextPut: OpLoadTrue.  ^self].
	lit == false ifTrue: [code nextPut: OpLoadFalse.  ^self].
	lit isInteger
		ifTrue:
			[(lit >= 0 and: [lit <= 2])
				ifTrue:
					[code nextPut: OpLoadZero + lit.
					^self].
			(lit >= 0 and: [lit <= 255])
				ifTrue:
					[code nextPut: OpLoadByte with: lit.
					^self].
			(lit >= -32768 and: [lit < 32768])
				ifTrue:
					[code nextPut: OpLoadTwoBytes
						with: ((lit bitShift: -8) bitAnd: 255)
						with: (lit bitAnd: 255).
					^self]].
	((lit isMemberOf: Character) and: [lit asciiValue between: 0 and: 255])
		ifTrue:
			[code nextPut: OpLoadCharacter with: lit asciiValue.
			^self].
	index _ literals at: lit ifAbsent:
		["Add the literal to the collection"
		literalCollection addLast: lit.
		literals at: lit put: literalCollection size - 1].
	index <= MaxLoadLiteral
		ifTrue: [code nextPut: OpLoadLiteral + index]
		ifFalse: [code nextPut: OpXLoadLiteral with: index]!

pushContext
	code nextPut: OpLoadThisContext.
	needsFrame _ hybrid _ true.
	self push!

pushStatic: binding
	self putIndex: (self literalIndex: binding)
		short: OpLoadStatic
		max: MaxLoadStatic
		long: OpXLoadStatic.
	self push!

putLoadInst: index scope: scope
	scope = nesting
		ifTrue:
			[self putIndex: index short: OpLoadInst max: MaxLoadInst long: OpXLoadInst]
		ifFalse:
			[self putLoadReceiver: scope;
				putLoadInstAny: index].
	forContext == nil ifTrue: [self setContextFlag].
	self push!

putLoadInstAny: index
	code nextPut: OpLoadInstAny with: index!

putLoadLocal: index argument: argFlag scope: scope
	| copiedIndex |
	scope = nesting
		ifTrue:
			[(index <= MaxPopLoadTemp and:
			 [code lastCode = OpPop])
				ifTrue:
					[code lastPut: OpPopLoadTemp + index]
				ifFalse:
					[self putIndex: index short: OpLoadTemp max: MaxLoadTemp long: OpXLoadTemp]]
		ifFalse:
			["See if this value is being cached locally"
			(copiedVars notNil and: [(copiedIndex _ copiedVars indexOf: (Array with: scope with: index)) > 0])
				ifTrue:
					[^self putLoadLocal: numArgs + finalNumTemps + copiedIndex - 1 argument: true scope: nesting].
			(scope = (nesting - 1) and: [index <= MaxLoadTempNextOuter])
				ifTrue:
					[scope < usesOuter ifTrue: [usesOuter _ scope].
					code nextPut: OpLoadTempNextOuter + index]
				ifFalse:
					[self putIndex: index scope: scope short: OpLoadTemp max: MaxLoadTemp long: OpXLoadTemp
						outer: OpLoadTempOuter long: OpXLoadTempOuter noCopy: false].
			canCopy
				ifTrue:
					[self addUse: index argument: argFlag scope: scope]].
	self push!

putLoadPseudo: name scope: scope
	"name can only be thisContext"
	self pushContext!

putLoadReceiver: scope
	| copiedIndex | 
	scope = nesting
		ifTrue:
			[code lastCode = OpPop
				ifTrue: [code lastPut: OpPopLoadReceiver]
				ifFalse: [code nextPut: OpLoadReceiver]]
		ifFalse:
			["See if this value is being cached locally"
			(copiedVars notNil and: [(copiedIndex _ copiedVars indexOf: (Array with: scope with: -1)) > 0])
				ifTrue:
					[^self putLoadLocal: numArgs + finalNumTemps + copiedIndex - 1 argument: true scope: nesting].
			scope < usesOuter ifTrue: [usesOuter _ scope].
			scope = (nesting - 1)
				ifTrue: [code nextPut: OpLoadReceiverNextOuter]
				ifFalse:
					[code nextPut: OpLoadReceiverOuter
						with: nesting - scope].
			canCopy
				ifTrue:
					[self addUse: -1 argument: true scope: scope]].
	self push!

putStoreInst: index scope: scope
	scope = nesting
		ifTrue:
			[self putStorePopInst: index scope: scope;
				putLoadInst: index scope: scope]
		ifFalse:
			[self putLoadReceiver: scope;
				putStoreInstAny: index.
			forContext == nil ifTrue: [self setContextFlag]]!

putStoreInstAny: index
	code nextPut: OpStoreInstAny with: index.
	self pop: 1!

putStoreLocal: index scope: scope
	self putStorePopLocal: index scope: scope;
		putLoadLocal: index argument: false scope: scope!

putStorePopInst: index scope: scope
	scope = nesting
		ifTrue:
			[self putIndex: index short: OpStorePopInst max: MaxStorePopInst long: OpXStorePopInst.
			self pop: 1]
		ifFalse:
			[self putLoadReceiver: scope;
				putStoreInstAny: index;
				pop].
	forContext == nil ifTrue: [self setContextFlag]!

putStorePopLocal: index scope: scope
	self putIndex: index scope: scope short: OpStorePopTemp max: MaxStorePopTemp long: OpXStorePopTemp
		outer: OpStorePopTempOuter long: OpXStorePopTempOuter noCopy: true.
	self noteStore: index scope: scope local: true.
	self pop: 1!

storePopStatic: binding
	code nextPut: OpXStorePopStatic
		with: (self literalIndex: binding).
	self pop: 1!

storeStatic: binding
	self storePopStatic: binding;
		pushStatic: binding! !

!CodeStream methodsFor: 'code generation-miscellaneous'!

codeBlock: block
	"This is handled differently from all other bytecodes,
	because it involves creating a new CodeStream."
	| inner outer innerUsed blockMethod copyingInner copyStart blockLitIndex copyEnd defb |
	inner _ self newBlockScope.
	inner outerStream: self finalNumTemps: nil.  "don't know numTemps yet"
	deferredBlocks == nil
		ifTrue:
			["Create the deferred blocks collection now,
			since we have to share it with the inner scope.
			Note that this can only happen in the outermost
			(method) scope."
			deferredBlocks _ OrderedCollection new].
	innerBlocks == nil ifTrue: [innerBlocks _ OrderedCollection new].
	inner deferredBlocks: deferredBlocks.
	block initScope: inner.
	block emitBody: inner.
	inner leaveScope.
	outer _ inner usesOuter.
	outer > nesting
		ifTrue:
			["No references to this scope
			or any outer one.  Make a clean block.
			Since there are no references to outer scopes,
			make the block at compile time."
			blockMethod _ inner makeLocalBlockMethod.
			self pushConstant: (BlockClosure newCleanMethod: blockMethod).
			innerBlocks addLast: blockMethod.
			^self].
	outer < usesOuter ifTrue: [usesOuter _ outer].
	inner canCopy
		ifTrue:
			["Recompile the block with the copied values."
			innerUsed _ inner usedVars.
			copyingInner _ self newBlockScope.
			copyingInner outerStream: self finalNumTemps: inner numTemps.
			block initScope: copyingInner.
			copyingInner bindCopied: innerUsed.
			block emitBody: copyingInner.
			copyingInner leaveScope.
			"Push the values that will be copied."
			copyStart _ code position.
			innerUsed do:
				[:var |  "array of (scope index)"
				(var at: 2) < 0
					ifTrue: [self putLoadReceiver: (var at: 1)]
					ifFalse: [self putLoadLocal: (var at: 2) argument: true scope: (var at: 1)]].
			"Emit code to create the closure."
			blockMethod _ copyingInner makeLocalBlockMethod.
			blockLitIndex _ self newLiteralIndex: blockMethod.
			code nextPut: OpCopyingBlock
				with: blockLitIndex
				with: innerUsed size.
			self pop: innerUsed size.
			copyEnd _ code position.
			"If the block used any temps, we can't tell
			whether it can actually be a copying block
			until we finish compiling the outermost scope
			that binds any temp used by the block.
			In this case, we also keep the code for the
			full block, and substitute it later if needed."
			inner usedTemps isNil
				ifFalse:
					[inner makeMethodOfClass: CompiledBlock local: false.
					outer < nesting ifTrue:  "propagate need for outer scope"
						["In principle, this scope could still be a copying block,
						but it's too hard to keep track of which variables are used."
						canCopy _ false].
					"Record everything we need to make the decision later."
					defb _ DeferredBlock new.
					defb outer: self literalIndex: blockLitIndex
						copying: copyingInner full: inner
						storeCounts: (inner usedTemps collect:
							[:var |  "var is Array with: scope with: index"
							Association
								key: var
								value: (self findStore: (var at: 2) scope: (var at: 1))])
						start: (self newLabel definition: copyStart)
						end: (self newLabel definition: copyEnd).
					deferredBlocks addLast: defb.
					"We don't have to set hybrid, because the flag is only
					an optimization hint anyway."
					needsFrame _ true.
					"Merge the temps into our own temp list."
					canCopy
						ifTrue:
							[inner usedTemps do:
								[:var |
								(var at: 1) < nesting ifTrue:
									[self addUse: (var at: 2) argument: false scope: (var at: 1)]]]]]
		ifFalse:
			[blockMethod _ inner makeMethodOfClass: CompiledBlock local: false.
			code nextPut: OpFullBlock with: (self newLiteralIndex: blockMethod).
			outer < nesting ifTrue:  "propagate need for outer scope"
				["In principle, this scope could still be a copying block,
				but it's too hard to keep track of which variables are used."
				canCopy _ false].
			needsFrame _ hybrid _ true].
	"Remember the block method so we can fix up its last literal."
	innerBlocks addLast: blockMethod.
	self push!

dupFirst
	code nextPut: OpDupFirst.
	self push!

dupLast
	code nextPut: OpNoDup!

dupNext
	code nextPut: OpDupNext!

pop
	code nextPut: OpPop.
	self pop: 1!

putPrimitive: n
	n notNil ifTrue:
		[code nextPut: OpPrimitive
			with: (n bitShift: -8)
			with: (n bitAnd: 255).
		code nextPut: OpPrimReturn]! !

!CodeStream methodsFor: 'code generation-jumps'!

define: label
	self
		define: label
		test:
			[:op :disp |
			op = OpLongBranchFalse
				ifTrue: [disp between: MinShortBranchFalse and: MaxShortBranchFalse]
				ifFalse:
					[op = (OpLongJump + 4)
						ifTrue: [disp between: MinShortJump and: MaxShortJump]
						ifFalse: [false]]]
		long: OpLongJump
		shorten: [:op | op = (OpLongJump + 4) ifTrue: [OpShortJump] ifFalse: [OpShortBranchFalse]]!

loopHead
	code nextPut: OpLoopHead!

putBranch: label
	reachable ifTrue:  "don't bother with branch-around after a return"
		[self branch: label with: OpLongJump + 4.
		reachable _ false]!

putBranchBack: label
	label reference: code position opcode: OpLongJump + 4.
	self putLongBranch: OpLongJump + 4 to: label definition.
	needsFrame _ true.  "need a frame for process switch"
	reachable _ false!

putBranchTo: label if: bool
	self pop: 1.
	self branch: label with: (bool ifTrue: [OpLongBranchTrue] ifFalse: [OpLongBranchFalse]).
	needsFrame _ true  "in case of notBoolean error"! !

!CodeStream methodsFor: 'code generation-sends and returns'!

putLocalReturn
	"Do peephole optimization for return
	self, nil, true, false."
	| op |
	reachable _ false.
	op _ code lastCode.
	(op >= OpLoadReceiver and: [op <= OpLoadFalse and: [op ~= OpPopLoadReceiver "confuses source map"]])
		ifTrue:  "optimize"
			[self noteScrunch: 1 at: code position - 1.  "fix up source map"
			code lastPut: op - OpLoadReceiver + OpReturnReceiver.
			^op ~= OpLoadReceiver]
		ifFalse:
			[code nextPut: OpReturn.
			^true]!

putMethodReturn
	nesting = 0
		ifTrue: [self putLocalReturn ifTrue: [returnsNonSelf _ true]]
		ifFalse: [code nextPut: OpHomeReturn with: nesting.  returnsNonSelf _ true].
	usesOuter _ 0.  "returning from method"
	canCopy _ false.
	reachable _ false!

send: selector numArgs: nargs
	| index | 
	index _ self selectorIndex: selector allowSpecial: true.
	index < 0
		ifTrue:  "special send"
			[(index = -1 and: [code lastCode = (OpLoadZero + 1)])
				ifTrue:  "optimize +1"
					[self noteScrunch: 1 at: code position - 1.  "fix up source map"
					code lastPut: OpSendAdd1]
				ifFalse:
					[index + MaxShortSpecialSend < -1
						ifTrue:  "extended special send"
							[code nextPut: OpXSpecialSend with: -1 - index]
						ifFalse: [code nextPut: OpSpecialSend - index - 1]]]
		ifFalse:
			[(nargs <= MaxSendNumArgs and: [index <= (MaxSends at: nargs + 1)])
				ifTrue:
					["Check for short send to self with 0 args"
					(nargs = 0 and: [index >= 0 and: [index <= MaxSendSelf0 and: [code lastCode = OpLoadReceiver]]])
						ifTrue:
							[self noteScrunch: 1 at: code position - 1.  "fix up source map"
							code lastPut: OpSendSelf0 + index]
						ifFalse: [code nextPut: (OpSends at: nargs + 1) + index]]
				ifFalse:
					[self putIndex: index count: nargs short: OpXSend long: OpXXSend]].
	self pop: nargs.
	needsFrame _ true!

sendNoCheck: selector numArgs: nargs
	| index |
	index _ self selectorIndex: selector allowSpecial: true.
	index < 0
		ifTrue:
			[code nextPut: OpXNoCheckSpecialSend with: -1 - index]
		ifFalse:
			[self
				putIndex: index
				count: nargs
				short: OpXNoCheckSend
				long: OpXXNoCheckSend].
	self pop: nargs.
	needsFrame _ true!

sendNonImmediate: selector numArgs: nargs
	| index |
	index _ self selectorIndex: selector allowSpecial: true.
	index < 0
		ifTrue:
			[code nextPut: OpXNonImmediateSpecialSend with: -1 - index]
		ifFalse:
			[self
				putIndex: index
				count: nargs
				short: OpXNonImmediateSend
				long: OpXXNonImmediateSend].
	self pop: nargs.
	needsFrame _ true!

sendSuper: selector numArgs: nargs
	| index |
	self pushConstant: class.  "push the class explicitly"
	index _ self selectorIndex: selector allowSpecial: false.
	self putIndex: index count: nargs short: OpXSuper long: OpXXSuper.
	self pop: nargs + 1.  "pop the class also"
	needsFrame _ true! !

!CodeStream methodsFor: 'private: private'!

addCopiedBinding: cv
	"Add a binding to the local scope
	that reflects a value copied here."
	| scope index |
	scope _ cv at: 1.
	index _ cv at: 2.
	bindings associationsDo:
		[:bind |
		(bind value isLocalScope: scope index: index)
			ifTrue:
				[bindings addCopied: bind key.  ^self]]!

addUse: index argument: argFlag scope: scope
	"Record the use of a potentially copied variable.
	This is only called if canCopy is true."
	| var |
	var _ Array with: scope with: index.
	argFlag
		ifTrue:
			[usedArgs == nil
				ifTrue: [usedArgs _ Array with: var]
				ifFalse:
					[(usedArgs includes: var)
						ifFalse:
							[usedArgs _ usedArgs copyWith: var]]]
		ifFalse:
			[usedTemps == nil
				ifTrue: [usedTemps _ Array with: var]
				ifFalse:
					[(usedTemps includes: var)
						ifFalse:
							[usedTemps _ usedTemps copyWith: var]]]!

checkStores: storeList
	"Check to make sure that all the variables
	for a potential copying block are still valid,
	i.e. haven't been stored into subsequently."
	storeList do:
		[:var |  "var key is (Array with: scope with: index), value is store count"
		var value = (self findStore: (var key at: 2) scope: (var key at: 1))
			ifFalse: [^false]].
	^true!

findStore: index scope: scope
	"Retrieve the store count for
	a given temporary variable."
	^scope = nesting
		ifTrue:
			[tempStores at: index - numArgs + 1]
		ifFalse:
			[outerStream findStore: index scope: scope]!

makeLocalBlockMethod
	"Make a local (copying or clean) block method.
	Such methods store their mclass explicitly."
	self makeMethodOfClass: CompiledLocalBlock local: true.
	method mclass: class.
	^method!

makeMethodOfClass: methodClass local: localFlag
	"Make up a completed method.
	If there are inner blocks, which need
	this method filled in as the outer method,
	do that now too.  If localFlag is true,
	the method has no access to variables
	from outer scopes, so cut the binding chain
	if we are saving it."
	method _ methodClass
		bytes: code contents
		literals: literalCollection
		numArgs: numArgs
		numTemps: numTemps
		maxDepth: maxDepth
		needsFrame: needsFrame
		hybrid: hybrid
		forContext: forContext == true.
	innerBlocks isNil ifFalse: [innerBlocks do: [:m | m outerMethod: method]].
	sourceMap isNil
		ifFalse:
			["If there are any copied values here,
			make entries for them in the bindings."
			copiedVars notNil ifTrue:
				[copiedVars do: [:cv | self addCopiedBinding: cv]].
			localFlag ifTrue: [bindings outerScope: NullScope new  "no outer scopes are accessible"].
			allSourceMaps at: method put: (Array with: sourceMap with: bindings)].
	deferredBlocks _ nil.  "break circularity"
	^method!

noteStore: index scope: scope local: localFlag
	"We have just generated a store into
	a temporary variable.
	If it is one of ours, record it, otherwise
	pass it on."
	| tempx |
	scope = nesting
		ifTrue:
			[tempx _ index - numArgs + 1.
			tempStores at: tempx put:
				(localFlag
					ifTrue: [(tempStores at: tempx) + 1]
					ifFalse: [SmallInteger minVal])]
		ifFalse:
			[outerStream noteStore: index scope: scope local: false]!

putIndex: index scope: scope short: op0 max: max long: op1 outer: op2 long: op3 noCopy: noCopy
	"Handle all the combinations of lengths
	for a load or a store.  Set usesOuter if
	the scope is an outer one; if noCopy is
	true, also reset canCopy."
	scope = nesting
		ifTrue:
			[self putIndex: index short: op0 max: max long: op1]
		ifFalse:
			[self putIndex: index count: nesting - scope short: op2 long: op3.
			scope < usesOuter ifTrue: [usesOuter _ scope].
			noCopy ifTrue: [canCopy _ false]]!

saveSourceMap: allMaps
	super saveSourceMap.
	allSourceMaps _ allMaps  "share with outer scope"!

setContextFlag
	"We just saw our first reference to
	an instance variable.  Check whether
	this class might be a sub- or superclass
	of Context, which requires special
	action at run time."
	forContext _ class instSize < Context instSize
		ifTrue: [Context inheritsFrom: class]
		ifFalse: [class == Context or: [class inheritsFrom: Context]]!

specialSelectors
	^SpecialSelectorDictionary! !