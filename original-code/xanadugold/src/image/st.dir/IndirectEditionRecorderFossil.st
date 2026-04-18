'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:21 pm'!

EditionRecorderFossil subclass: #IndirectEditionRecorderFossil
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fossil'!
IndirectEditionRecorderFossil comment:
'A Fossil for an EditionRecorder with the directOnly flag off.'!

(IndirectEditionRecorderFossil getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!IndirectEditionRecorderFossil methodsFor: 'protected: accessing'!

{ResultRecorder} actualRecorder

	^IndirectEditionRecorder
		create: self directFilter
		with: self indirectFilter
		with: self trailBlazer! !

!IndirectEditionRecorderFossil methodsFor: 'create'!

create: loginAuthority {IDRegion}
	with: directFilter {Filter}
	with: indirectFilter {Filter}
	with: trailBlazer {TrailBlazer}
	
	super create: loginAuthority
		with: directFilter
		with: indirectFilter
		with: trailBlazer.
	self newShepherd.
	self remember.! !

!IndirectEditionRecorderFossil methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !