'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:22 pm'!

InstructionClient subclass: #InstructionStream
	instanceVariableNames: 'method pc '
	classVariableNames: 'SpecialConstants '
	poolDictionaries: 'OpcodePool '
	category: 'Kernel-Methods'!
InstructionStream comment:
'Class InstructionStream represents a HPS instruction stream, with machinery for decoding it.  The decoding is semantic rather than syntactic, i.e. a single opcode may result in more than one action message being sent to the client, and several different opcodes may result in the same message (with different parameters).

Instance Variables:
	method	<CompiledMethod>
	pc	<SmallInteger>

Class Variables:
	SpecialConstants	<Array of: Objects>

Pool Dictionary:
	OpcodePool		<Dictionary>
'!


!InstructionStream methodsFor: 'accessing'!

changeToNPC
	pc > 0 ifTrue: [pc _ method nFromVPC: pc]!

changeToVPC
	pc < 0 ifTrue: [pc _ method vFromNPC: pc]!

method
	^method!

next
	"Answer the next bytecode in the stream,
	and skip over it.  If there are no more bytecodes,
	answer nil."

	| byte |
	pc <= method bytesSize
		ifFalse: [^nil]
		ifTrue:
			[byte _ method byteAt: pc.
			byte <= LastShortOp
				ifTrue: [pc _ pc + 1]
				ifFalse:
					[byte <= LastXOp
						ifTrue: [pc _ pc + 2]
						ifFalse: [pc _ pc + 3]].
			^byte]!

pc
	"Answer the bytecode PC."

	self changeToVPC.
	^pc! !

!InstructionStream methodsFor: 'testing'!

atEnd
	"Answer true iff there are no more
	bytecodes in the stream."

	^pc > method bytesSize!

isJump: nextPC
	"Answer whether the next bytecode is a jump."

	| byte |
	byte _ method byteAt: nextPC.
	(byte >= OpShortJump and: [byte < FirstShortSend])
			ifTrue: [^true].
	(byte >= OpShortBranchFalse and: [byte < LastShortOp])
			ifTrue: [^true].	
	(byte >= OpLongJump and: [byte < OpXSpecialSend])
			ifTrue: [^true].	
	^false!

isLoad: nextPC
	"Answer whether the next bytecode is a load."

	| byte |
	byte _ method byteAt: nextPC.
	byte <= LastShortLoad 
			ifTrue: [^true].
	byte = OpLoadInstAny 
			ifTrue: [^true]. 
	(byte between: OpXLoadInst and: OpLoadByte) 
			ifTrue: [^true].
	(byte between: OpXLoadInstOuter and: OpLoadTwoBytes) 
			ifTrue: [^true].	
	^false!

nextPC: aPC
	"Answer the next bytecode in the stream,
	and skip over it.  If there are no more bytecodes,
	answer nil."

	| byte c max |
	c _ aPC.
	max _ method bytesSize.
	c <= max
		ifFalse: [^nil]
		ifTrue:
			[byte _ method byteAt: c.
			byte <= LastShortOp
				ifTrue: [c _ c + 1]
				ifFalse:
					[byte <= LastXOp
						ifTrue: [c _ c + 2]
						ifFalse: [c _ c + 3]].
			^c min: max]!

peekForInstVarRead
	"If this instruction reads an instance variable,
	answer the index of the variable (1-origin),
	otherwise answer nil.  Currently we answer
	the index even for reading instance variables
	of arbitrary objects: this probably will have
	to be changed someday."

	| byte x1 |
	byte _ method byteAt: pc.
	byte <= LastShortOp
		ifTrue:
			[byte <= MaxLoadInst ifTrue: [^byte + 1].
			^nil].
	byte <= LastXOp
		ifTrue:
			[x1 _ method byteAt: pc + 1.
			byte = OpXLoadInst ifTrue: [^x1 + 1].
			byte = OpLoadInstOuter ifTrue: [^(x1 bitAnd: 31) + 1].
			byte = OpLoadInstAny ifTrue: [^x1 + 1].
			^nil].
	byte = OpXLoadInstOuter
		ifTrue:
			[^(method byteAt: pc + 2) + 1].
	^nil!

peekForInstVarWrite
	"If this instruction writes into an instance variable,
	answer the index of the variable (1-origin),
	otherwise answer nil.  Currently we answer
	the index even for writing instance variables
	of arbitrary objects: this probably will have
	to be changed someday."

	| byte index |
	byte _ method byteAt: pc.
	byte <= LastShortOp
		ifTrue:
			[index _ byte - OpStorePopInst.
			(index >= 0 and: [index <= MaxStorePopInst]) ifTrue: [^index + 1].
			^nil].
	byte <= LastXOp
		ifTrue:
			[byte = OpXStorePopInst ifTrue: [^(method byteAt: pc + 1) + 1].
			byte = OpStoreInstAny ifTrue: [^(method byteAt: pc + 1) + 1].
			^nil].
	byte = OpXStorePopInstOuter
		ifTrue:
			[^(method byteAt: pc + 2) + 1].
	^nil!

peekForSelector
	"If this instruction is a send, answer its selector,
	otherwise answer nil."

	| byte x1 x2 index |
	byte _ method byteAt: pc.
	byte <= LastShortOp
		ifTrue:
			[(index _ byte - (OpSends at: 1)) < 0 ifTrue: [^nil].  "not a send"
			(index <= (MaxSends at: 1) or:
			 [(index _ byte - (OpSends at: 2)) <= (MaxSends at: 2) or:
			  [(index _ byte - (OpSends at: 3)) <= (MaxSends at: 3) or:
			   [(index _ byte - OpSendSelf0) <= MaxSendSelf0]]])
				ifTrue: [^method literalAt: index + 1].
			(index _ byte - OpSpecialSend) <= MaxShortSpecialSend
				ifTrue: [index _ index * 2 + 1.  ^SpecialSelectors at: index].
			byte = OpSendAdd1 ifTrue: [^#+].
			^nil].
	byte <= LastXOp
		ifTrue:
			[x1 _ method byteAt: pc + 1.
			(byte = OpXSend or: [byte = OpXSuper or: [byte = OpXNoCheckSend or: [byte = OpXNonImmediateSend]]])
				ifTrue: [^method literalAt: (x1 bitAnd: 31) + 1].
			(byte = OpXSpecialSend or: [byte = OpXNoCheckSpecialSend or: [byte = OpXNonImmediateSpecialSend]])
				ifTrue: [^SpecialSelectors at: x1 * 2 + 1].
			^nil].
	(byte = OpXXSend or: [byte = OpXXSuper or: [byte = OpXXNoCheckSend or: [byte = OpXXNonImmediateSend]]])
		ifTrue:
			[x2 _ method byteAt: pc + 2.
			^method literalAt: x2 + 1].
	^nil!

peekForSpecialSelector: index0
	"Answer whether this instruction
	sends the special selector with the
	given (0-origin) index."

	| byte |
	byte _ method byteAt: pc.
	byte <= LastShortOp
		ifTrue:
			[index0 <= MaxShortSpecialSend
				ifTrue:
					[byte - OpSpecialSend = index0 ifTrue: [^true].
					index0 = 0 ifTrue: [^byte = OpSendAdd1]].
			^false].
	byte <= LastXOp
		ifTrue:
			[^(byte = OpXSpecialSend or: [byte = OpXNoCheckSpecialSend or: [byte = OpXNonImmediateSpecialSend]])
				and: [(method byteAt: pc + 1) = index0]].
	^false!

willAssign
	"Answer whether the next bytecode is a pop-store."

	| byte |
	self changeToVPC.
	byte _ method byteAt: pc.
	(byte between: OpStorePopTemp and: OpStorePopTemp + MaxStorePopTemp) 
			ifTrue: [^true].		"pop store temporary variable 0-7"
	(byte between: OpStorePopInst and: OpStorePopInst + MaxStorePopInst) 
			ifTrue: [^true]. 	"pop store instance variable 0-7"
	byte = OpStoreInstAny ifTrue: [^true].
	(byte between: OpXStorePopInst and: OpStorePopTempOuter) 
			ifTrue: [^true].		"two byte pop store"
	(byte between: OpXStorePopInstOuter and: OpXStorePopTempOuter) 
			ifTrue: [^true].		"three byte pop store"
	^false!

willJumpBackward
	"Answer whether the next bytecode is a backward jump ."

	| byte |
	self changeToVPC.
	byte _ method byteAt: pc.
	^byte >= OpLongJump and: [byte < (OpLongJump + 4)]!

willLoad
	"Answer whether the next bytecode is a load."

	| byte |
	self changeToVPC.
	byte _ method byteAt: pc.
	byte <= LastShortLoad 
			ifTrue: [^true].
	byte = OpLoadInstAny 
			ifTrue: [^true]. 
	(byte between: OpXLoadInst and: OpLoadByte) 
			ifTrue: [^true].
	(byte between: OpXLoadInstOuter and: OpLoadTwoBytes) 
			ifTrue: [^true].	
	^false!

willReturn
	"Answer whether the next bytecode is a return."

	| byte |
	self changeToVPC.
	byte _ method byteAt: pc.
	(byte between: OpReturnReceiver and: OpReturn) ifTrue: [^true].
	byte = OpHomeReturn ifTrue: [^true].
	^false!

willSend
	"Answer whether the next bytecode is a message-send."

	| byte |
	self changeToVPC.
	byte _ method byteAt: pc.
	byte < FirstShortSend 
			ifTrue: [^false].
	(byte between: FirstShortSend and:  LastShortSend) 
			ifTrue: [^true].		"special send or short send"
	byte = OpSendAdd1 ifTrue: [^true].
	(byte between: OpXNoCheckSend and: OpXNonImmediateSpecialSend) 
			ifTrue: [^true].		"long sends"
	byte = OpXNoCheckSpecialSend 
			ifTrue: [^true].
	(byte between: OpXSpecialSend and: OpXXNoCheckSend) 
			ifTrue: [^true].
	(byte between: OpXXSend and: OpXXSuper) 
			ifTrue: [^true].
	^false! !

!InstructionStream methodsFor: 'positioning'!

reset
	"Reset the stream to its initial position."

	pc _ method initialPC! !

!InstructionStream methodsFor: 'decoding'!

interpretNextInstructionFor: client 
	"Send to the argument, client, a message that specifies the type of the
	the next instruction."

	| byte x1 x2 |
	self changeToVPC.
	byte _ method byteAt: pc.
	pc _ pc+1.
	"Open-code much of the opcode dispatch.
	This isn't as tedious as it sounds."
	byte <= LastShortLoad ifTrue: [^self interpretShortLoad: byte for: client].
	byte <= OpNoDup ifTrue: [^self interpretShortMisc: byte for: client].
	byte <= LastShortOp ifTrue: [^self interpretShortControl: byte for: client].
	x1 _ method byteAt: pc.
	pc _ pc+1.
	byte < OpHomeReturn ifTrue: [^self interpretXMisc: byte with: x1 for: client].
	byte <= LastXOp ifTrue: [^self interpretXControl: byte with: x1 for: client].
	x2 _ method byteAt: pc.
	pc _ pc+1.
	^self interpretXX: byte with: x1 with: x2 for: client!

scanFor: scanBlock
	"Answer true if scanBlock answers true on some bytecode,
	false if scanBlock never answers true."

	| end byte |
	end _ method bytesSize.
	[pc <= end]
		whileTrue: 
			[(scanBlock value: (byte _ method byteAt: pc)) ifTrue: [^true].
			byte <= LastShortOp
				ifTrue: [pc _ pc + 1]
				ifFalse:
					[byte <= LastXOp
						ifTrue: [pc _ pc + 2]
						ifFalse: [pc _ pc + 3]]].
	^false! !

!InstructionStream methodsFor: 'private: private-decoding'!

interpretShortControl: byte for: client
	| index |
	(index _ byte - OpShortJump) <= (MaxShortJump - MinShortJump) ifTrue: [^client jump: index + MinShortJump].
	(index _ byte - (OpSends at: 1)) <= (MaxSends at: 1) ifTrue: [^client send: (method literalAt: index + 1) numArgs: 0].
	(index _ byte - (OpSends at: 2)) <= (MaxSends at: 2) ifTrue: [^client send: (method literalAt: index + 1) numArgs: 1].
	(index _ byte - (OpSends at: 3)) <= (MaxSends at: 3) ifTrue: [^client send: (method literalAt: index + 1) numArgs: 2].
	(index _ byte - OpSendSelf0) <= MaxSendSelf0 ifTrue: [^client pushReceiver; send: (method literalAt: index + 1) numArgs: 0].
	(index _ byte - OpSpecialSend) <= MaxShortSpecialSend ifTrue: [index _ index * 2 + 1.  ^client send: (SpecialSelectors at: index) numArgs: (SpecialSelectors at: index + 1)].
	(index _ byte - OpShortBranchFalse) <= (MaxShortBranchFalse - MinShortBranchFalse) ifTrue: [^client jump: index + MinShortBranchFalse if: false].
	byte = OpSendAdd1 ifTrue: [^client pushConstant: 1; send: #+ numArgs: 1].
	self error: 'Instruction decoding error'!

interpretShortLoad: byte for: client
	| index |
	(index _ byte) <= MaxLoadInst ifTrue: [^client pushInst: index].
	(index _ byte - OpLoadTemp) <= MaxLoadTemp ifTrue: [^client pushLocal: index].
	(index _ byte - OpLoadLiteral) <= MaxLoadLiteral ifTrue: [^client pushConstant: (method literalAt: index + 1)].
	(index _ byte - OpLoadTempNextOuter) <= MaxLoadTempNextOuter ifTrue: [^client pushLocal: index outer: 1].
	(index _ byte - OpLoadStatic) <= MaxLoadStatic ifTrue: [^client pushStatic: (method literalAt: index + 1)].
	byte = OpNoOp ifTrue: [^client noOp].
	byte = OpPrimReturn ifTrue: [^client primitiveReturn].
	byte = OpLoadReceiver ifTrue: [^client pushReceiver].
	byte = OpPopLoadReceiver ifTrue: [^client pop; pushReceiver].
	byte = OpLoadNil ifTrue: [^client pushConstant: nil].
	byte = OpLoadTrue ifTrue: [^client pushConstant: true].
	byte = OpLoadFalse ifTrue: [^client pushConstant: false].
	(index _ byte - OpLoadZero) <= 2 ifTrue: [^client pushConstant: index].
	(index _ byte - OpStorePopTemp) <= MaxStorePopTemp ifTrue: [^client storeLocal: index; pop].
	byte = OpLoadThisContext ifTrue: [^client pushContext].
	byte = OpLoadReceiverNextOuter ifTrue: [^client pushReceiverOuter: 1].
	(index _ byte - OpPopLoadTemp) <= MaxPopLoadTemp ifTrue: [^client pop; pushLocal: index].
	(index _ byte - OpStorePopInst) <= MaxStorePopInst ifTrue: [^client storeInst: index; pop].
	self error: 'Instruction decoding error'!

interpretShortMisc: byte for: client
	byte = OpReturnReceiver ifTrue: [^client pushReceiver; returnTop].
	byte = OpPopReturnReceiver ifTrue: [^client pop; pushReceiver; returnTop].
	byte = OpReturnNil ifTrue: [^client pushConstant: nil; returnTop].
	byte = OpReturnTrue ifTrue: [^client pushConstant: true; returnTop].
	byte = OpReturnFalse ifTrue: [^client pushConstant: false; returnTop].
	byte = OpReturn ifTrue: [^client returnTop].
	byte = OpPop ifTrue: [^client pop].
	byte = OpLoopHead ifTrue: [^client loopHead].
	byte = OpDupFirst ifTrue: [^client dupFirst].
	byte = OpDupNext ifTrue: [^client dupNext].
	byte = OpNoDup ifTrue: [^client dupLast].
	self error: 'Instruction decoding error'!

interpretXControl: byte with: x1 for: client
	| index |
	byte = OpHomeReturn ifTrue: [^client methodReturnTop: x1].
	byte = OpXNoCheckSpecialSend ifTrue: [index _ x1 * 2 + 1.  ^client sendNoCheck: (SpecialSelectors at: index) numArgs: (SpecialSelectors at: index + 1)].
	(index _ byte - OpLongJump) <= 7 ifTrue: [^client jump: index - 4 * 256 + x1].
	(index _ byte - OpLongBranchFalse) <= 3 ifTrue: [^client jump: index * 256 + x1 if: false].
	(index _ byte - OpLongBranchTrue) <= 3 ifTrue: [^client jump: index * 256 + x1 if: true].
	byte = OpXSpecialSend ifTrue: [index _ x1 * 2 + 1.  ^client send: (SpecialSelectors at: index) numArgs: (SpecialSelectors at: index + 1)].
	byte = OpXSend ifTrue: [^client send: (method literalAt: (x1 bitAnd: 31) + 1) numArgs: (x1 bitShift: -5)].
	byte = OpXSuper ifTrue: [^client sendSuper: (method literalAt: (x1 bitAnd: 31) + 1) numArgs: (x1 bitShift: -5)].
	self error: 'Instruction decoding error'!

interpretXMisc: byte with: x1 for: client
	| index |
	byte = OpLoadInstAny ifTrue: [^client pushInstAny: x1].
	byte = OpStoreInstAny ifTrue: [^client storeInstAny: x1].
	byte = OpCopyValues ifTrue: [^client pushCopiedValues: x1].
	byte = OpXNoCheckSend ifTrue: [^client sendNoCheck: (method literalAt: (x1 bitAnd: 31) + 1) numArgs: (x1 bitShift: -5)].
	byte = OpXNonImmediateSend ifTrue: [^client sendNonImmediate: (method literalAt: (x1 bitAnd: 31) + 1) numArgs: (x1 bitShift: -5)].
	byte = OpXNonImmediateSpecialSend ifTrue: [index _ x1 * 2 + 1.  ^client sendNonImmediate: (SpecialSelectors at: index) numArgs: (SpecialSelectors at: index + 1)].
	byte = OpFullBlock ifTrue: [^client makeFullBlock: (method literalAt: x1 + 1)].
	byte = OpXLoadInst ifTrue: [^client pushInst: x1].
	byte = OpXLoadTemp ifTrue: [^client pushLocal: x1].
	byte = OpXLoadLiteral ifTrue: [^client pushConstant: (method literalAt: x1 + 1)].
	byte = OpXLoadStatic ifTrue: [^client pushStatic: (method literalAt: x1 + 1)].
	byte = OpLoadInstOuter ifTrue: [^client pushInst: (x1 bitAnd: 31) outer: (x1 bitShift: -5)].
	byte = OpLoadTempOuter ifTrue: [^client pushLocal: (x1 bitAnd: 31) outer: (x1 bitShift: -5)].
	byte = OpLoadReceiverOuter ifTrue: [^client pushReceiverOuter: x1].
	byte = OpLoadCharacter ifTrue: [^client pushConstant: (Character value: x1)].
	byte = OpLoadByte ifTrue: [^client pushConstant: x1].
	byte = OpXStorePopInst ifTrue: [^client storeInst: x1; pop].
	byte = OpXStorePopTemp ifTrue: [^client storeLocal: x1; pop].
	byte = OpXStorePopStatic ifTrue: [^client storeStatic: (method literalAt: x1 + 1); pop].
	byte = OpStorePopTempOuter ifTrue: [^client storePopLocal: (x1 bitAnd: 31) outer: (x1 bitShift: -5)].
	self error: 'Instruction decoding error'!

interpretXX: byte with: x1 with: x2 for: client
	byte = OpXXNonImmediateSend ifTrue: [^client sendNonImmediate: (method literalAt: x2 + 1) numArgs: x1].
	byte = OpXXNoCheckSend ifTrue: [^client sendNoCheck: (method literalAt: x2 + 1) numArgs: x1].
	byte = OpCallPrimitive ifTrue: [^client callPrimitive: x1 * 256 + x2].
	byte = OpXLoadInstOuter ifTrue: [^client pushInst: x2 outer: x1].
	byte = OpXLoadTempOuter ifTrue: [^client pushLocal: x2 outer: x1].
	byte = OpLoadTwoBytes ifTrue: [^client pushConstant: (x1 >= 128 ifTrue: [x1 - 256] ifFalse: [x1]) * 256 + x2].
	byte = OpXStorePopInstOuter ifTrue: [^client storePopInst: x2 outer: x1].
	byte = OpXStorePopTempOuter ifTrue: [^client storePopLocal: x2 outer: x1].
	byte = OpXXSend ifTrue: [^client send: (method literalAt: x2 + 1) numArgs: x1].
	byte = OpXXSuper ifTrue: [^client sendSuper: (method literalAt: x2 + 1) numArgs: x1].
	byte = OpPrimitive ifTrue: [^client methodPrimitive: x1 * 256 + x2].
	byte = OpCopyingBlock ifTrue: [^client makeCopyingBlock: (method literalAt: x1 + 1) count: x2].
	self error: 'Instruction decoding error'! !

!InstructionStream methodsFor: 'private: private'!

method: aMethod
	method _ aMethod.
	self reset! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InstructionStream class
	instanceVariableNames: ''!


!InstructionStream class methodsFor: 'class initialization'!

initialize
	"HPSInstructionStream initialize"

	SpecialConstants _ Array with: true with: false with: nil with: 0! !

!InstructionStream class methodsFor: 'instance creation'!

on: aMethod
	^self new method: aMethod! !

InstructionStream initialize!
