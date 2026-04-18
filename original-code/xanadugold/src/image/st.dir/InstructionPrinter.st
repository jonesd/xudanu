'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:21 pm'!

InstructionClient subclass: #InstructionPrinter
	instanceVariableNames: 'method stream inStream '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Methods'!
InstructionPrinter comment:
'Class InstructionPrinter knows how to print HPS instructions on a stream in symbolic form.

Instance Variables:
	method		<CompiledMethod>
	stream		<WriteStream>
	inStream	<InstructionStream>
'!


!InstructionPrinter methodsFor: 'printing'!

printInstructionsOn: aStream 
	"Append to the stream, aStream, a description of each bytecode in the instruction
	stream."
	
	| end |
	stream _ (String new: 30) writeStream.
	end _ method bytes size.
	[inStream pc <= end]
		whileTrue: [self printNextInstructionOn: aStream]! !

!InstructionPrinter methodsFor: 'opcodes-data movement'!

dupFirst
	stream nextPutAll: 'dup first; '!

dupLast
	stream nextPutAll: 'dup last; '!

dupNext
	stream nextPutAll: 'dup; '!

pop
	stream nextPutAll: 'pop; '!

pushConstant: value
	stream nextPutAll: 'push ';
		print: value;
		nextPutAll: '; '!

pushContext
	stream nextPutAll: 'push context; '!

pushCopiedValues: count
	stream nextPutAll: 'push ';
		print: count;
		nextPutAll: ' copied values; '!

pushInst: index
	stream nextPutAll: 'push inst ';
		store: index;
		nextPutAll: '; '!

pushInst: index outer: level
	self outer: level; pushInst: index!

pushInstAny: index
	stream nextPutAll: 'push inst ';
		store: index;
		nextPutAll: ' of top; '!

pushLocal: index
	stream nextPutAll: 'push local ';
		store: index;
		nextPutAll: '; '!

pushLocal: index outer: level
	self outer: level; pushLocal: index!

pushReceiver
	stream nextPutAll: 'push self; '!

pushReceiverOuter: level
	self outer: level; pushReceiver!

pushStatic: assoc
	stream nextPutAll: 'push ';
		nextPutAll: assoc key;
		nextPutAll: '; '!

storeInst: index
	stream nextPutAll: 'store inst ';
		store: index;
		nextPutAll: '; '!

storeInstAny: index
	stream nextPutAll: 'store inst ';
		store: index;
		nextPutAll: ' of top; '!

storeLocal: index
	stream nextPutAll: 'store local ';
		store: index;
		nextPutAll: '; '!

storePopInst: index outer: level
	self outer: level; storeInst: index; pop!

storePopLocal: index outer: level
	self outer: level; storeLocal: index; pop!

storeStatic: assoc
	stream nextPutAll: 'store ';
		nextPutAll: assoc key;
		nextPutAll: '; '! !

!InstructionPrinter methodsFor: 'opcodes-control'!

callPrimitive: index
	stream nextPutAll: 'call primitive ';
		print: index;
		nextPutAll: '; '!

jump: delta
	stream nextPutAll: 'jump ';
		print: inStream pc + delta;
		nextPutAll: '; '!

jump: delta if: condition
	stream nextPutAll: 'jump ';
		print: condition;
		space;
		print: inStream pc + delta;
		nextPutAll: '; '!

loopHead
	stream nextPutAll: 'loop head; '!

makeCopyingBlock: meth count: count
	stream nextPutAll: 'make copying block (';
		print: count;
		nextPutAll: '); '!

makeFullBlock: meth
	stream nextPutAll: 'make full block; '!

methodPrimitive: index
	stream nextPutAll: 'primitive ';
		print: index;
		nextPutAll: '; '!

methodReturnTop: levels
	stream nextPutAll: ' outer(';
		print: levels;
		nextPutAll: ') method return; '!

noOp
	stream nextPutAll: 'no-op; '!

primitiveReturn
	stream nextPutAll: '(primitive return); '!

returnTop
	stream nextPutAll: 'return; '!

send: selector numArgs: na
	stream nextPutAll: 'send ';
		nextPutAll: selector;
		nextPutAll: '; '!

sendNoCheck: selector numArgs: na
	stream nextPutAll: 'no-check '.
	self send: selector numArgs: na!

sendNonImmediate: selector numArgs: na
	stream nextPutAll: 'non-immediate '.
	self send: selector numArgs: na!

sendSuper: selector numArgs: na
	stream nextPutAll: 'super '.
	self send: selector numArgs: na! !

!InstructionPrinter methodsFor: 'private: private'!

method: aMethod
	method _ aMethod.
	inStream _ InstructionStream on: aMethod!

outer: level
	stream nextPutAll: 'outer'.
	level > 0 ifTrue: [stream nextPut: $(; print: level; nextPut: $)].
	stream space!

printNextInstructionOn: aStream
	| code oldPC |
	oldPC _ inStream pc.
	stream reset.
	inStream interpretNextInstructionFor: self.
	stream skip: -2.  "remove final ; "
	aStream print: oldPC; space.
	aStream nextPut: $<.
	oldPC to: inStream pc - 1 do: 
		[:i | 
		code _ (method byteAt: i) storeStringRadix: 16.
		aStream nextPut: 
			(code size < 5
				ifTrue: [$0]
				ifFalse: [code at: 4]).
		aStream nextPut: code last; space].
	aStream skip: -1.
	aStream nextPut: $>.
	aStream space.
	aStream nextPutAll: stream contents.
	aStream cr! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InstructionPrinter class
	instanceVariableNames: ''!


!InstructionPrinter class methodsFor: 'instance creation'!

on: aMethod
	^self new method: aMethod! !