'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:40 pm'!

Heaper subclass: #Xmtr
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(Xmtr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Xmtr methodsFor: 'sending'!

{void} sendBooleanVar: b {BooleanVar}
	self subclassResponsibility!

{void} sendHeaper: object {Heaper}
	
	self subclassResponsibility!

{void} sendIEEEDoubleVar: x {IEEEDoubleVar}
	
	self subclassResponsibility!

{void} sendInt32: n {Int32}
	
	self subclassResponsibility!

{void} sendInt8: byte {Int8}
	
	self subclassResponsibility!

{void} sendIntegerVar: n {IntegerVar}
	
	self subclassResponsibility!

{void} sendString: s {char star}

	self subclassResponsibility!

{void} sendUInt32: n {UInt32}
	
	self subclassResponsibility!

{void} sendUInt8: byte {UInt8}
	
	self subclassResponsibility!

{void} sendUInt8Data: array {UInt8Array}

	self subclassResponsibility! !

!Xmtr methodsFor: 'smalltalk: sending'!

{void} send: object {Object}
	"Dispatch to the send routines."

	(object isInteger) ifTrue: [self sendIntegerVar: object]
	ifFalse: [object == true ifTrue: [self sendUInt32: 1]
	ifFalse: [object == false ifTrue: [self sendUInt32: UInt32Zero]
	ifFalse: [self sendHeaper: object]]]! !

!Xmtr methodsFor: 'smalltalk: deja vu'!

{void} sendData: array {UInt8Array}

	self subclassResponsibility! !

!Xmtr methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !