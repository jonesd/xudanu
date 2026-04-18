'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:39 pm'!

Turtle subclass: #SimpleTurtle
	instanceVariableNames: '
		myCounter {Counter}
		myBootHeaper {Heaper}
		myProtocol {XcvrMaker NOCOPY}
		myCookbook {Cookbook NOCOPY}
		myBootCategory {Category}
		myAgenda {Agenda | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!

(SimpleTurtle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #LOCKED; add: #COPY; yourself)!

!SimpleTurtle methodsFor: 'accessing'!

{Category} bootCategory
	^myBootCategory!

{Heaper} bootHeaper
	^myBootHeaper!

{Cookbook} cookbook
	^myCookbook!

{Counter} counter
	^myCounter!

{Agenda | NULL} fetchAgenda

	^myAgenda!

{XcvrMaker} protocol
	^myProtocol!

{void} saveBootHeaper: boot {Heaper} 
	
	myBootHeaper == NULL
		ifFalse: [Turtle BLAST: #DontChangeTurtlesBootHeaper]
		ifTrue: 
			[DiskManager consistent: 1 with:
				[myBootHeaper _ boot.
				self diskUpdate]]!

{void} setProtocol: xcvrMaker {XcvrMaker} with: book {Cookbook}
	myProtocol _ xcvrMaker.
	myCookbook _ book.! !

!SimpleTurtle methodsFor: 'testing'!

{UInt32} contentsHash

	^((super contentsHash
		bitXor: myCounter hashForEqual)
		bitXor: myBootHeaper hashForEqual)
		bitXor: myProtocol hashForEqual! !

!SimpleTurtle methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartSimpleTurtle: rcvr {Rcvr unused default: NULL}
	myProtocol _ XcvrMaker make.  "The bogus protocol"
	myCookbook _ Cookbook make    "with the empty cookbook"! !

!SimpleTurtle methodsFor: 'protected: creation'!

create: cookbook {Cookbook} with: bootCategory {Category} with: maker {XcvrMaker} 
	
	| packer {DiskManager} |
	super create: 1.
	packer _ CurrentPacker fluidGet cast: DiskManager.
	DiskManager consistent: 1 with:
		[myCounter _ NULL.
		myBootHeaper _ NULL.
		myProtocol _ maker.
		myCookbook _ cookbook.
		myBootCategory _ bootCategory.
		myAgenda _ NULL.
		packer storeInitialFlock: self
			with: myProtocol
			with: cookbook].
	DiskManager consistent: 3 with:
		[self thingToDo. "tune the number 5000"
		myCounter _ Counter fakeCounter: 3 with: 5000 with: 2.
		packer setHashCounter: myCounter.
		self remember.
		myCounter newShepherd.
		myCounter remember.
		myAgenda _ Agenda make.
		myAgenda rememberYourself]! !

!SimpleTurtle methodsFor: 'smalltalk: passe'!

{void} newCounter: counter {Counter}
	
	self passe! !

!SimpleTurtle methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCounter _ receiver receiveHeaper.
	myBootHeaper _ receiver receiveHeaper.
	myBootCategory _ receiver receiveHeaper.
	myAgenda _ receiver receiveHeaper.
	self restartSimpleTurtle: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCounter.
	xmtr sendHeaper: myBootHeaper.
	xmtr sendHeaper: myBootCategory.
	xmtr sendHeaper: myAgenda.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SimpleTurtle class
	instanceVariableNames: ''!

(SimpleTurtle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #LOCKED; add: #COPY; yourself)!

!SimpleTurtle class methodsFor: 'pseudo-constructors'!

make: cookbook {Cookbook} with:  bootCategory {Category} with: maker {XcvrMaker}
	^SimpleTurtle create: cookbook with: bootCategory with: maker! !