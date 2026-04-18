'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:27 pm'!

OrderedCollection variableSubclass: #HandlerCollection
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Exception Handling'!
HandlerCollection comment:
'Class HandlerCollection holds a collection of (signal pattern, handler) pairs.  This allows pre-construction of multi-handler bundles that can be bound efficiently, and also reduces the amount of block nesting required to bind multiple handlers.

Note that if hc is a HandlerCollection, the effect of modifying hc within the scope of hc handleDo: is not defined, e.g., in
	hc handleDo: [... hc add: sig1 with: [:ex | ...]. ... sig1 raise ...]
it isn''t defined whether the handleDo: will actually handle the raising of sig1.

Note that on:handle: uses addFirst:.  As a result, after
	hc on: sig handle: h1.
	hc on: sig handle: h2
h2 takes precedence over h1.  To get the opposite effect, use
	hc addLast: (Association key: sig value: h2).

Instance Variables: *indexed*'!


!HandlerCollection methodsFor: 'adding'!

on: aSignalPattern handle: aHandlerBlock 
	"The receiver as a kind of OrderedCollection holds a set of 
	associations between Signals and HandlerBlocks. Add this new 
	association to the receiver."

	^self addFirst: (Association key: aSignalPattern value: aHandlerBlock)! !

!HandlerCollection methodsFor: 'handling'!

handleDo: aBlock
	"Evaluate aBlock in the context of all the handlers in this collection. "
	^firstIndex <= lastIndex
		ifTrue: [self handleFrom: lastIndex do: aBlock]
		ifFalse: [aBlock value]! !

!HandlerCollection methodsFor: 'private: private'!

handleFrom: index do: aBlock
	| pair |
	pair _ self basicAt: index.
	^index = firstIndex
		ifTrue: [pair key handle: pair value do: aBlock]
		ifFalse: [pair key handle: pair value do:
			[self handleFrom: index - 1 do: aBlock]]! !