'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:04 pm'!

InstructionClient subclass: #NOLOCKDetector
	instanceVariableNames: '
		method {UNKNOWN}
		continue {BooleanVar}
		ivarsAllowed {BooleanVar}
		messageAllowed {BooleanVar}
		inStream {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ Translator'!
NOLOCKDetector comment:
'Look at the instructions in the method to see if it can be a NOLOCK method.'!



!NOLOCKDetector methodsFor: 'private: private'!

method: aMethod
	method _ aMethod.
	inStream _ InstructionStream on: aMethod!

testSend
	"The generic behavior for message sending."
	
	continue _ false.! !

!NOLOCKDetector methodsFor: 'opcodes-data movement'!

pushConstant: value!

pushContext
	continue _ false!

pushCopiedValues: count
	"unsure."
	continue _ false.!

pushInst: index
	continue _ ivarsAllowed!

pushInst: index outer: level
	continue _ ivarsAllowed!

pushInstAny: index
	continue _ ivarsAllowed!

storeInst: index
	continue _ ivarsAllowed!

storeInstAny: index
	continue _ ivarsAllowed!

storePopInst: index outer: level
	continue _ ivarsAllowed! !

!NOLOCKDetector methodsFor: 'testing'!

shouldBeNOLOCK
	"Return true if this method sends at most one other message, and
	 doesn't access any instance variables after that."
	
	| end |
	end _ method bytes size.
	continue _ true.
	ivarsAllowed _ messageAllowed _ true.
	[continue and: [inStream pc <= end]]
		whileTrue: [inStream interpretNextInstructionFor: self.].
	^continue! !

!NOLOCKDetector methodsFor: 'opcodes-control'!

callPrimitive: index
	self testSend!

jump: delta
	continue _ false!

jump: delta if: condition
	continue _ false!

makeCopyingBlock: meth count: count
	continue _ false!

makeFullBlock: meth
	continue _ false!

methodPrimitive: index
	continue _ false!

send: selector numArgs: na
	self testSend!

sendNoCheck: selector numArgs: na
	self testSend!

sendNonImmediate: selector numArgs: na
	self testSend!

sendSuper: selector numArgs: na
	self testSend! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NOLOCKDetector class
	instanceVariableNames: ''!



!NOLOCKDetector class methodsFor: 'instance creation'!

on: aMethod
	"Transcript show: aMethod symbolic."
	
	^self new method: aMethod! !