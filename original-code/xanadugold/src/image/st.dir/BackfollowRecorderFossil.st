'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:19 pm'!

Fossil subclass: #BackfollowRecorderFossil
	instanceVariableNames: '
		myPermissionsFilter {Filter of: ID}
		myEndorsementsFilter {Filter of: ID}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fossil'!
BackfollowRecorderFossil comment:
'A Fossil for a BackfollowRecorder Waldo, which also stores its filters.'!

(BackfollowRecorderFossil getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #OBSOLETE; add: #CONCRETE; yourself)!

!BackfollowRecorderFossil methodsFor: 'protected: accessing'!

{Waldo} makeWaldo: km {KeyMaster unused} with: tip {Manipulator}

	| result {Waldo} |
	result := XuServer currentServer wrap: self workType with: tip.
	(result cast: BackfollowRecorder)
		filter: myPermissionsFilter
		with: myEndorsementsFilter.
	^result! !

!BackfollowRecorderFossil methodsFor: 'create'!

create: gm {GrandMap}
	with: iObject {IObject}
	with: workType {PackOBits}
	with: clubsAndFilters {ImmuTable of: ID and: Filter}
	with: user {ID}
	with: permissions {Filter of: ID}
	with: endorsements {Filter of: ID}
	
	super create: gm with: iObject with: workType with: clubsAndFilters with: user.
	myPermissionsFilter := permissions.
	myEndorsementsFilter := endorsements.
	self newShepherd.
	self remember! !

!BackfollowRecorderFossil methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPermissionsFilter _ receiver receiveHeaper.
	myEndorsementsFilter _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPermissionsFilter.
	xmtr sendHeaper: myEndorsementsFilter.! !