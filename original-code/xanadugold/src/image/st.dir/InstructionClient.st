'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:21 pm'!

Object subclass: #InstructionClient
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Methods'!
InstructionClient comment:
'Class InstructionClient is an abstract client for an InstructionStream.  The instruction stream decodes instructions in a compiled method and sends appropriate messages to the instance of the class.  The default implementation is to do nothing;  subclasses may take action according to their function (printing, decompiling, analyzing, answering queries, etc.)'!


!InstructionClient methodsFor: 'opcodes-data movement'!

dupFirst!

dupLast!

dupNext!

pop!

pushConstant: value!

pushContext!

pushCopiedValues: count!

pushInst: index!

pushInst: index outer: level!

pushInstAny: index!

pushLocal: index!

pushLocal: index outer: level!

pushReceiver!

pushReceiverOuter: level!

pushStatic: assoc!

storeInst: index!

storeInstAny: index!

storeLocal: index!

storePopInst: index outer: level!

storePopLocal: index outer: level!

storeStatic: assoc! !

!InstructionClient methodsFor: 'opcodes-control'!

callPrimitive: index!

jump: delta!

jump: delta if: condition!

loopHead!

makeCopyingBlock: meth count: count!

makeFullBlock: meth!

methodPrimitive: index!

methodReturnTop: levels!

noOp!

primitiveReturn!

returnTop!

send: selector numArgs: na!

sendNoCheck: selector numArgs: na!

sendNonImmediate: selector numArgs: na!

sendSuper: selector numArgs: na! !