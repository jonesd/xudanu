'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:54 pm'!

Thunk subclass: #HonestAbeIniter
	instanceVariableNames: '
		myCategory {Category}
		blastOnError {BooleanVar}
		persistInterval {IntegerVar}'
	classVariableNames: '
		TheHonestConnection {Connection} 
		TheHonestGrandMap {BeGrandMap} '
	poolDictionaries: ''
	category: 'Xanadu-diskman'!

(HonestAbeIniter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!HonestAbeIniter methodsFor: 'running'!

{void} execute

	| cookbook {Cookbook} turtle {Turtle} conn {Connection} |
	TestPacker make: blastOnError with: persistInterval.
	cookbook := Cookbook make.Category: myCategory.
	turtle := Turtle make: cookbook with: myCategory with: ProtocolBroker diskProtocol.
	conn := Connection make: myCategory.
	TheHonestConnection _ conn.
	turtle saveBootHeaper: conn bootHeaper.
	"The following is here so that later thunks can get the GrandMap &c"
	"[WorksBootMaker] USES.
	GrandConnection fluidSet: TheHonestConnection.ó"
	TheHonestGrandMap _ conn bootHeaper cast: BeGrandMap.
	CurrentPacker fluidGet purge.
	"CurrentPacker fluidSet: NULL.
"! !

!HonestAbeIniter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCategory _ receiver receiveHeaper.
	blastOnError _ receiver receiveBooleanVar.
	persistInterval _ receiver receiveIntegerVar.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCategory.
	xmtr sendBooleanVar: blastOnError.
	xmtr sendIntegerVar: persistInterval.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HonestAbeIniter class
	instanceVariableNames: ''!

(HonestAbeIniter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!HonestAbeIniter class methodsFor: 'accessing'!

{BeGrandMap} fetchGrandMap
	^ TheHonestGrandMap! !

!HonestAbeIniter class methodsFor: 'smalltalk: init'!

exitTimeNonInherited
	TheHonestConnection _ NULL!

linkTimeNonInherited
	TheHonestConnection _ NULL.
	TheHonestGrandMap _ NULL.! !