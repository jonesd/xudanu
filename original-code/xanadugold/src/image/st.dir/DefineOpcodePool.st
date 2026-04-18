'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:33 pm'!

Object subclass: #DefineOpcodePool
	instanceVariableNames: ''
	classVariableNames: 'ExtendedSpecialSelectors FirstShortSend LastShortLoad LastShortOp LastShortSend LastXOp MaxLoadInst MaxLoadLiteral MaxLoadSmallInteger MaxLoadStatic MaxLoadTemp MaxLoadTempNextOuter MaxPopLoadTemp MaxSendNumArgs MaxSends MaxSendSelf0 MaxShortBranchFalse MaxShortJump MaxShortSpecialSend MaxStorePopInst MaxStorePopTemp MinShortBranchFalse MinShortJump OpCallPrimitive OpCopyingBlock OpCopyValues OpDupFirst OpDupNext OpFullBlock OpHomeReturn OpLoadByte OpLoadCharacter OpLoadFalse OpLoadInst OpLoadInstAny OpLoadInstOuter OpLoadLiteral OpLoadNil OpLoadReceiver OpLoadReceiverNextOuter OpLoadReceiverOuter OpLoadStatic OpLoadTemp OpLoadTempNextOuter OpLoadTempOuter OpLoadThisContext OpLoadTrue OpLoadTwoBytes OpLoadZero OpLongBranchFalse OpLongBranchTrue OpLongJump OpLoopHead OpNoDup OpNoOp OpPop OpPopLoadReceiver OpPopLoadTemp OpPopReturnReceiver OpPrimitive OpPrimReturn OpReturn OpReturnFalse OpReturnNil OpReturnReceiver OpReturnTrue OpSendAdd1 OpSends OpSendSelf0 OpShortBranchFalse OpShortJump OpSpecialSend OpStoreInstAny OpStorePopInst OpStorePopTemp OpStorePopTempOuter OpXLoadInst OpXLoadInstOuter OpXLoadLiteral OpXLoadStatic OpXLoadTemp OpXLoadTempOuter OpXNoCheckSend OpXNoCheckSpecialSend OpXNonImmediateSend OpXNonImmediateSpecialSend OpXSend OpXSpecialSend OpXStorePopInst OpXStorePopInstOuter OpXStorePopStatic OpXStorePopTemp OpXStorePopTempOuter OpXSuper OpXXNoCheckSend OpXXNonImmediateSend OpXXSend OpXXSuper SpecialSelectorDictionary SpecialSelectors '
	poolDictionaries: ''
	category: 'System-Compiler-Support'!
DefineOpcodePool comment:
'This class exists only to define the OpcodePool dictionary.  It creates the dictionary as its own class variable dictionary, and then copies all the entries into the pool.

Changing the instruction set requires changing the following classes:
	- DefineOpcodePool class, to define the Opxxx static variable.
	- CodeStream (perhaps), to generate the opcode when compiling.
	- InstructionStream, to decode the opcode.
	- If the semantics have been changed or extended,
	  all the subclasses of InstructionClient,
	  such as simulators, printers, decompilers, and analyzers.

Of course, changes in the VM will also be necessary.
'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DefineOpcodePool class
	instanceVariableNames: ''!


!DefineOpcodePool class methodsFor: 'class initialization'!

initialize
	"DefineOpcodePool initialize"
	self initializeSpecialSelectors.
	"Define all the bytecodes.
	We have to do this in pieces
	because there are so many."
	self defineShortLoads.
	self defineShortOther.
	self defineTwoByteCodes.
	self defineThreeByteCodes.
	"Now install the pool.  This is a little
	tricky: we really want to share the
	Associations, not make new ones,
	if possible."
	(Smalltalk at: #OpcodePool ifAbsent: [nil]) isNil ifTrue:
		[Smalltalk at: #OpcodePool put: Dictionary new].
	self classPool associationsDo:
		[:assoc | OpcodePool add: assoc]! !

!DefineOpcodePool class methodsFor: 'private: private-initialization'!

defineShortLoads
	| op m |
	op _ 0.
	OpLoadInst _ op.  m _ MaxLoadInst _ 15.
	OpLoadTemp _ op _ op + m + 1.  m _ MaxLoadTemp _ 11.
	OpLoadLiteral _ op _ op + m + 1.  m _ MaxLoadLiteral _ 15.
	OpLoadTempNextOuter _ op _ op + m + 1.  m _ MaxLoadTempNextOuter _ 7.
	OpLoadStatic _ op _ op + m + 1.  m _ MaxLoadStatic _ 11.
	OpNoOp _ op _ op + m + 1.
	  op _ op + 2.  "UNASSIGNED"
	OpPrimReturn _ op _ op + 1.
	"Next 5 must stay in order, to match OpReturnxxx"
	OpLoadReceiver _ op _ op + 1.
	OpPopLoadReceiver _ op _ op + 1.
	OpLoadNil _ op _ op + 1.
	OpLoadTrue _ op _ op + 1.
	OpLoadFalse _ op _ op + 1.
	OpLoadZero _ op _ op + 1.  m _ MaxLoadSmallInteger _ 2.
	  op _ op + m + 1.
	OpStorePopTemp _ op.  m _ MaxStorePopTemp _ 7.
	  op _ op + m + 1.
	OpLoadThisContext _ op.
	OpLoadReceiverNextOuter _ op _ op + 1.
	OpPopLoadTemp _ op _ op + 1.  m _ MaxPopLoadTemp _ 1.
	OpStorePopInst _ op _ op + m + 1.  m _ MaxStorePopInst _ 7.
	  op _ op + m + 1.
	LastShortLoad _ op - 1!

defineShortOther
	| op m |
	op _ LastShortLoad + 1.
	"Next 5 must stay in order to match OpLoadxxx"
	OpReturnReceiver _ op.
	OpPopReturnReceiver _ op _ op + 1.
	OpReturnNil _ op _ op + 1.
	OpReturnTrue _ op _ op + 1.
	OpReturnFalse _ op _ op + 1.
	OpReturn _ op _ op + 1.
	OpPop _ op _ op + 1.
	OpLoopHead _ op _ op + 1.
	OpDupFirst _ op _ op + 1.
	OpDupNext _ op _ op + 1.
	OpNoDup _ op _ op + 1.
	OpShortJump _ op _ op + 1.  MinShortJump _ 1.  MaxShortJump _ 5.
	  op _ op + MaxShortJump - MinShortJump + 1.
	"Check opcode numbering"
	(op = 16r70) ifFalse: [self error: 'Opcode numbering is wrong'].
	FirstShortSend _ op.
	MaxSends _ #(15 15 7).
	MaxSendNumArgs _ MaxSends size - 1.
	m _ -1.
	OpSends _ MaxSends collect: [:m1 | op _ op + m + 1.  m _ m1.  op].
	OpSendSelf0 _ op _ op + m + 1.  m _ MaxSendSelf0 _ 7.
	OpSpecialSend _ op _ op + m + 1.  m _ MaxShortSpecialSend _ 31.
	  op _ op + m + 1.
	LastShortSend _ op - 1.
	OpShortBranchFalse _ op.  MinShortBranchFalse _ 1.  MaxShortBranchFalse _ 8.
	  op _ op + MaxShortBranchFalse - MinShortBranchFalse + 1.
	OpSendAdd1 _ op.
	LastShortOp _ op!

defineThreeByteCodes
	| op |
	op _ 16rF3.
	"Check opcode numbering"
	(op > LastXOp) ifFalse: [self error: '3-byte opcodes overlap'].
	OpXXNonImmediateSend _ op.
	OpXXNoCheckSend _ op _ op + 1.
	  op _ op + 1.  "UNASSIGNED"
	OpCallPrimitive _ op _ op + 1.
	OpXLoadInstOuter _ op _ op + 1.
	OpXLoadTempOuter _ op _ op + 1.
	OpLoadTwoBytes _ op _ op + 1.
	OpXStorePopInstOuter _ op _ op + 1.
	OpXStorePopTempOuter _ op _ op + 1.
	OpXXSend _ op _ op + 1.
	OpXXSuper _ op _ op + 1.
	OpPrimitive _ op _ op + 1.
	OpCopyingBlock _ op _ op + 1.
	"Check opcode numbering"
	(op <= 16rFF) ifFalse: [self error: 'Too many opcodes']!

defineTwoByteCodes
	| op |
	op _ 16rC9.
	"Check opcode numbering"
	(op > LastShortOp) ifFalse: [self error: '2-byte opcodes overlap'].
	OpLoadInstAny _ op.
	OpStoreInstAny _ op _ op + 1.
	OpCopyValues _ op _ op + 1.
	OpXNoCheckSend _ op _ op + 1.
	OpXNonImmediateSend _ op _ op + 1.
	OpXNonImmediateSpecialSend _ op _ op + 1.
	OpFullBlock _ op_ op + 1.
	OpXLoadInst _ op _ op + 1.
	OpXLoadTemp _ op _ op + 1.
	OpXLoadLiteral _ op _ op + 1.
	OpXLoadStatic _ op _ op + 1.
	OpLoadInstOuter _ op _ op + 1.
	OpLoadTempOuter _ op _ op + 1.
	OpLoadReceiverOuter _ op _ op + 1.
	OpLoadCharacter _ op _ op + 1.
	OpLoadByte _ op _ op + 1.
	  op _ op + 1.  "UNASSIGNED"
	OpXStorePopInst _ op _ op + 1.
	OpXStorePopTemp _ op _ op + 1.
	OpXStorePopStatic _ op _ op + 1.
	OpStorePopTempOuter _ op _ op + 1.
	OpHomeReturn _ op _ op + 1.
	OpXNoCheckSpecialSend _ op _ op + 1.
	OpLongJump _ op _ op + 1.
	OpLongBranchFalse _ op _ op + 8.  "nota bene +8"
	OpLongBranchTrue _ op _ op + 4.  "nota bene +4"
	op _ op + 4.  "nota bene +4"
	OpXSpecialSend _ op.
	OpXSend _ op _ op + 1.
	OpXSuper _ op _ op + 1.
	LastXOp _ op!

extendedSpecialSelectors
	"These are the most common selectors
	(with at least 20 occurrences)
	in the current license image.
	IF YOU CHANGE THIS LIST,
	YOU WILL HAVE TO RECOMPILE THE
	ENTIRE SYSTEM TWICE!!"

	^#(, error: name nextPutAll: to:do: cr on: add: contents extent: isEmpty boundingBox isNil text subclassResponsibility ~~ first max: with: includes: last printString close controller asSymbol notNil mustBeInteger: not copy release black basicAt: top extent cursorPoint isKindOf: height show: changed: copyFrom:to: initialize primitiveFailed species position test:labeled:repeated: space showWhile: origin addLast: print: deselect truncated includesKey: to: key min: displayOn:at:clippingBox:rule:mask: over printOn: isMemberOf: string & insetDisplayBox asText width asFloat model: topLeft basicSize at:ifAbsent: perform: negated asciiValue open white organization push: translateBy: center lineGrid with:with: operation:with:with: collect: controlTerminate selectedClass new asString mustBeString: withCRs basicAt:put: display inside controlInitialize displayOn:at: unixStringFrom: method reverse scanToken allBehaviorsDo: nextChunkPut: align:with: displayOn: displayBox form: form | borderWidth: gray fill:rule:mask: show stringIndex digitLength changeRequest select: rounded associationsDo: fromDisplay: replaceSelectionWith: fileName readOnly expected: execute offset operation:with: compositionRectangle mustBeStructure:ofLength: skip: pop: receiver fill:mask: corner crtab: basicNew between:and: operation:with:with:with: compiledMethodAt: hash addAll: insideColor: viewport waitButton intersect: tab normal word printOn:indent: left addSubView: wait redButtonPressed corner: bottom digitAt: retry:coercing: isCollapsed label: instSize notify: timesRepeat: window: containsPoint: insetBy: isVariable reset changes labels:lines:selectors: )!

frequentSpecialSelectors
	"Find the most common selectors
	for economical encoding."
	"DefineOpcodePool frequentSpecialSelectors size"
	| dict sorted sels |
	dict _ IdentityDictionary new.
	CompiledMethod allInstancesDo:
		[:cmeth | cmeth literals do:
			[:lit | (lit isSymbol) ifTrue:
				[dict at: lit put: (dict at: lit ifAbsent: [0]) + 1]]].
	sorted _ SortedCollection new: 500.
	dict associationsDo:
		[:a | a value >= 20 ifTrue:
			[sorted add: (Association key: a value negated value: a key)]].  "negated to sort in descending order"
	sels _ OrderedCollection new.
	sorted do: [:a | sels add: a value].
	^sels asArray!

initializeSpecialSelectors
	| index shortSpecialSelectors seq dict |
	shortSpecialSelectors _ #(
		+ - < > <= >= = ~=
		* // @ , extent: isNil notNil isEmpty
		at: at:put: size next nextPut: nextPutAll: == class
		add: value value: do: new new: x y
	).
	ExtendedSpecialSelectors _ self extendedSpecialSelectors.
	index _ 0.
	dict _ IdentityDictionary new: 256 * 2.
	seq _ OrderedCollection new: 256 * 2.
	shortSpecialSelectors do:
		[:sel | seq add: sel; add: sel numArgs.
		dict at: sel put: (index _ index - 1)].
	ExtendedSpecialSelectors do:
		[:sel | (dict includesKey: sel) ifFalse:
			[index > -255 ifTrue:
				[seq add: sel; add: sel numArgs.
				dict at: sel put: (index _ index - 1)]]].
	SpecialSelectorDictionary _ dict.
	SpecialSelectors _ seq asArray! !

DefineOpcodePool initialize!
