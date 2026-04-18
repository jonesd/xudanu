'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:10 pm'!

Thunk subclass: #DiskIniter
	instanceVariableNames: '
		myCategory {Category}
		myFilename {char star}
		mySnarfSize {Int32 NOCOPY}
		mySnarfCount {Int32 NOCOPY}
		myStageCount {Int32 NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(DiskIniter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!DiskIniter methodsFor: 'running'!

{void} execute

	| maker {XcvrMaker} cookbook {Cookbook} turtle {Turtle} conn {Connection} |
	DiskManager initializeDisk: myFilename.
	maker _ ProtocolBroker diskProtocol.
	cookbook _ Cookbook make.Category: myCategory.
	turtle _ Turtle make: cookbook with: myCategory with: maker.
	conn _ Connection make: myCategory.
	turtle saveBootHeaper: conn bootHeaper.
	(conn bootHeaper cast: BeGrandMap) bePurgeable.
	CurrentPacker fluidGet purge.
	"Let's make sure that the GC gets as much as possible."
	"[WorksBootMaker] USES.
	GrandConnection fluidSet: NULL."
	conn _ NULL.
	turtle _ NULL.
	maker _ NULL.
	cookbook _ NULL.
	CurrentPacker fluidGet destroy.
	CurrentPacker fluidSet: (NULL basicCast: DiskManager).! !

!DiskIniter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCategory _ receiver receiveHeaper.
	myFilename _ receiver receiveString.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCategory.
	xmtr sendString: myFilename.! !