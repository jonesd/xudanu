'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:19 pm'!

EditionRecorderFossil subclass: #DirectEditionRecorderFossil
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fossil'!
DirectEditionRecorderFossil comment:
'A Fossil for an EditionRecorder with the directOnly flag set.'!

(DirectEditionRecorderFossil getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!DirectEditionRecorderFossil methodsFor: 'protected: accessing'!

{ResultRecorder} actualRecorder

	^DirectEditionRecorder
		create: self directFilter
		with: self indirectFilter
		with: self trailBlazer! !

!DirectEditionRecorderFossil methodsFor: 'create'!

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

!DirectEditionRecorderFossil methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !