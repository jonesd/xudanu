'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:31 pm'!

AgendaItem subclass: #UpdateTransitiveMemberIDs
	instanceVariableNames: 'myClubs {MuSet of: BeClub}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-brange2'!
UpdateTransitiveMemberIDs comment:
'This carries on the updating of transitive member IDs for the given club.'!

(UpdateTransitiveMemberIDs getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!UpdateTransitiveMemberIDs methodsFor: 'accessing'!

{BooleanVar} step
	myClubs isEmpty ifFalse:
		[DiskManager consistent: 5 with:
			[| club {BeClub} stomp {Stepper} |
			club := (stomp := myClubs stepper) fetch cast: BeClub.
			stomp destroy.
			club updateTransitiveMemberIDs.
			myClubs remove: club.
			self diskUpdate]].
	^ myClubs isEmpty not! !

!UpdateTransitiveMemberIDs methodsFor: 'protected: creation'!

create: clubs {MuSet of: BeClub}
	super create.
	myClubs := clubs.
	self newShepherd.! !

!UpdateTransitiveMemberIDs methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myClubs _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myClubs.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UpdateTransitiveMemberIDs class
	instanceVariableNames: ''!

(UpdateTransitiveMemberIDs getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!UpdateTransitiveMemberIDs class methodsFor: 'creation'!

make: clubs {MuSet of: BeClub}
	^ self create: clubs! !