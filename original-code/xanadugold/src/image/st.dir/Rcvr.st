'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:12 pm'!

Heaper subclass: #Rcvr
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(Rcvr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Rcvr methodsFor: 'receiving'!

{BooleanVar} receiveBooleanVar
	self subclassResponsibility!

{void} receiveData: array {UInt8Array}
	"Fill the array with data from the stream."
	
	self subclassResponsibility!

{Heaper} receiveHeaper
	self subclassResponsibility!

{IEEEDoubleVar} receiveIEEEDoubleVar
	self subclassResponsibility!

{Int32} receiveInt32
	self subclassResponsibility!

{Int8} receiveInt8
	self subclassResponsibility!

{IntegerVar} receiveIntegerVar
	self subclassResponsibility!

{void} receiveInto: memory {Heaper}
	"Receive an object into another object."

	self subclassResponsibility!

{char star} receiveString

	self subclassResponsibility!

{UInt32} receiveUInt32
	self subclassResponsibility!

{UInt8} receiveUInt8
	self subclassResponsibility! !

!Rcvr methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !