'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:23 pm'!

Context subclass: #MethodContext
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Methods'!
MethodContext comment:
'Class MethodContext represents a Context for executing a method as the result of a message-send.'!


!MethodContext methodsFor: 'accessing'!

home
	^self!

homeReceiver
	"Answer the receiver from the context
	in which the receiver was defined."
	^receiver!

mclass 
	"Answer the class in which the receiver's method was found."

	| mclass |
	receiver class selectorAtMethod: method setClass: [:mc | mclass _ mc].
	^mclass!

selector
	"Answer the selector of the method that created the receiver."

	^receiver class 
		selectorAtMethod: method 
		setClass: [:ignored]!

sourceCode 
	"Answer the source form of the receiver's method."
	| mclass selector |
	^method getSourceForUserIfNone:
		[selector _ self receiver class selectorAtMethod: method setClass: [:mc | mclass _ mc].
		mclass sourceCodeForMethod: method at: selector]! !

!MethodContext methodsFor: 'backward compatibility'!

blockCopy: numArgs
	"This is here ONLY for the blockCopy: benchmark!!
	Its implementation is completely irrelevant."
	^[]! !

!MethodContext methodsFor: 'private: private'!

findTemp: index do: aBlock elseDo: elseBlock
	" aBlock is guaranteed to do a ^ return "
	^self countTemps: index do: aBlock elseDo: elseBlock!

outer: level
	"We are counting levels outward from
	a BlockContext.  Level had better be zero."
	level = 0 ifFalse: [self error: 'level counting error!!'].
	^receiver!

privateTempAt: index
	^stack at: index!

privateTempAt: index put: value
	index <= method numArgs
		ifTrue:
			[(self confirm: 'I will restart from the beginning of this method.
Is that OK?')
				ifTrue: [self restart]
				ifFalse: [^value]].
	^stack at: index put: value! !