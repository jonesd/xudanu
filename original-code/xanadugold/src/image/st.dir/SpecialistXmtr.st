'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:34 pm'!

Xmtr subclass: #SpecialistXmtr
	instanceVariableNames: '
		mySpecialist {TransferSpecialist}
		myIbids {PrimIndexTable}
		myNextIbid {Int4}'
	classVariableNames: 'XmtrIbidCache {PrimIndexTable} '
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!
SpecialistXmtr comment:
'myIbids maps from already sent heapers to their ibid numbers.'!

(SpecialistXmtr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!SpecialistXmtr methodsFor: 'sending'!

{void} sendBooleanVar: b {BooleanVar}
	self subclassResponsibility!

{void} sendCategory: cat {Category}
	self subclassResponsibility!

{void} sendHeaper: object {Heaper} 
	object == NULL
		ifTrue: [self sendNULL]
		ifFalse: 
			[| pos {Int32} |
			pos _ (myIbids fetch: object) DOTasLong.
			pos ~~ -1
				ifTrue: [self sendIbid: pos]
				ifFalse: [mySpecialist sendHeaper: object to: self]]!

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
	"Send the contents of the UInt8Array as data."

	self subclassResponsibility! !

!SpecialistXmtr methodsFor: 'specialist sending'!

{void} endInstance

	self subclassResponsibility!

{void} startInstance: heaper {Heaper} with: cat {Category} 
	"Register heaper as an object to be sent across the wire, and send cat
	 as its category. cat might be different from heaper->getCategory() 
	 if another object is being substituted for heaper."
	
	myIbids at: heaper introduce: myNextIbid.
	myNextIbid _ myNextIbid + 1.
	self startNewInstance: cat! !

!SpecialistXmtr methodsFor: 'protected:'!

{void} endPacket
	myIbids clearAll.
	myNextIbid _ Int32Zero!

{void} sendNULL

	self subclassResponsibility!

{TransferSpecialist} specialist
	^mySpecialist!

{void} startNewInstance: cat {Category} 
	
	self subclassResponsibility! !

!SpecialistXmtr methodsFor: 'private: sending'!

{void} sendIbid: pos {Int32}
	"The object represented by pos has already been sent.  Send just a reference by number."
	
	self startNewInstance: CommIbid.
	self sendInt32: pos.
	self endInstance! !

!SpecialistXmtr methodsFor: 'protected: creation'!

create: specialist {TransferSpecialist}
	super create.
	mySpecialist _ specialist.
	XmtrIbidCache == NULL 
		ifTrue: [myIbids _ PrimIndexTable make: 255]
		ifFalse:
			[myIbids _ XmtrIbidCache.
			XmtrIbidCache _ NULL].
	myNextIbid _ Int32Zero!

{void} destruct
	XmtrIbidCache == NULL 
		ifTrue:
			[myIbids clearAll.
			XmtrIbidCache _ myIbids cast: PrimIndexTable.
			myIbids _ NULL]
		ifFalse: [myIbids destroy].
	"mySpecialist destroy"
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SpecialistXmtr class
	instanceVariableNames: ''!

(SpecialistXmtr getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!SpecialistXmtr class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	XmtrIbidCache _ NULL! !