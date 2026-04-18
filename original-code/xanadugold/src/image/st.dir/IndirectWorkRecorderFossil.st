'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:22 pm'!

WorkRecorderFossil subclass: #IndirectWorkRecorderFossil
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fossil'!
IndirectWorkRecorderFossil comment:
'A Fossil for a IndirectWorkRecorder.'!

(IndirectWorkRecorderFossil getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!IndirectWorkRecorderFossil methodsFor: 'protected: accessing'!

{ResultRecorder} actualRecorder

	^IndirectWorkRecorder
		create: self endorsementsFilter
		with: self trailBlazer! !

!IndirectWorkRecorderFossil methodsFor: 'create'!

create: loginAuthority {IDRegion}
	with: endorsementsFilter {Filter}
	with: trailBlazer {TrailBlazer}
	
	super create: loginAuthority
		with: endorsementsFilter
		with: trailBlazer.
	self newShepherd.
	self remember.! !

!IndirectWorkRecorderFossil methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !