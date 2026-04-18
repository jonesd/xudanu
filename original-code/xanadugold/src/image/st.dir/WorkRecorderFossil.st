'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:23 pm'!

RecorderFossil subclass: #WorkRecorderFossil
	instanceVariableNames: 'myEndorsementsFilter {Filter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fossil'!
WorkRecorderFossil comment:
'A Fossil for a WorkRecorder.'!

(WorkRecorderFossil getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #DEFERRED; add: #DEFERRED.LOCKED; add: #NOT.A.TYPE; yourself)!

!WorkRecorderFossil methodsFor: 'protected: accessing'!

{ResultRecorder} actualRecorder

	self subclassResponsibility!

{Filter} endorsementsFilter

	^myEndorsementsFilter! !

!WorkRecorderFossil methodsFor: 'create'!

create: loginAuthority {IDRegion}
	with: endorsementsFilter {Filter}
	with: trailBlazer {TrailBlazer}
	
	super create: loginAuthority with: trailBlazer.
	myEndorsementsFilter := endorsementsFilter.! !

!WorkRecorderFossil methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myEndorsementsFilter _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myEndorsementsFilter.! !