'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:20 pm'!

RecorderFossil subclass: #EditionRecorderFossil
	instanceVariableNames: '
		myDirectFilter {Filter}
		myIndirectFilter {Filter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fossil'!
EditionRecorderFossil comment:
'A Fossil for an EditionRecorder.'!

(EditionRecorderFossil getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #DEFERRED; add: #DEFERRED.LOCKED; add: #NOT.A.TYPE; yourself)!

!EditionRecorderFossil methodsFor: 'protected: accessing'!

{ResultRecorder} actualRecorder

	self subclassResponsibility!

{Filter} directFilter
	
	^myDirectFilter!

{Filter} indirectFilter
	
	^myIndirectFilter! !

!EditionRecorderFossil methodsFor: 'create'!

create: loginAuthority {IDRegion}
	with: directFilter {Filter}
	with: indirectFilter {Filter}
	with: trailBlazer {TrailBlazer}
	
	super create: loginAuthority with: trailBlazer.
	myDirectFilter := directFilter.
	myIndirectFilter := indirectFilter.! !

!EditionRecorderFossil methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myDirectFilter _ receiver receiveHeaper.
	myIndirectFilter _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myDirectFilter.
	xmtr sendHeaper: myIndirectFilter.! !