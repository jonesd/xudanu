'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:32 pm'!

AgendaItem subclass: #UpdateTransitiveSuperClubIDs
	instanceVariableNames: '
		myClubs {MuSet of: BeClub | NULL}
		myGrandMap {BeGrandMap}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-brange2'!
UpdateTransitiveSuperClubIDs comment:
'This carries on the updating of transitive superclass IDs for the given club.'!

(UpdateTransitiveSuperClubIDs getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!UpdateTransitiveSuperClubIDs methodsFor: 'accessing'!

{BooleanVar} step
	myClubs isEmpty ifFalse:
		[DiskManager consistent: 2 with:
			[| club {BeClub} stomp {Stepper} |
			club := (stomp := myClubs stepper) fetch cast: BeClub.
			stomp destroy.
			CurrentGrandMap fluidBind: myGrandMap during: [club updateTransitiveSuperClubIDs].
			myClubs remove: club.
			self diskUpdate]].
	^ myClubs isEmpty not! !

!UpdateTransitiveSuperClubIDs methodsFor: 'protected: creation'!

create: clubs {MuSet of: BeClub} with: grandMap {BeGrandMap}
	super create.
	myClubs := clubs.
	myGrandMap := grandMap.
	self newShepherd.! !

!UpdateTransitiveSuperClubIDs methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myClubs _ receiver receiveHeaper.
	myGrandMap _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myClubs.
	xmtr sendHeaper: myGrandMap.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UpdateTransitiveSuperClubIDs class
	instanceVariableNames: ''!

(UpdateTransitiveSuperClubIDs getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!UpdateTransitiveSuperClubIDs class methodsFor: 'creation'!

make: clubs {MuSet of: BeClub} with: grandMap {BeGrandMap}
	^ self create: clubs with: grandMap! !