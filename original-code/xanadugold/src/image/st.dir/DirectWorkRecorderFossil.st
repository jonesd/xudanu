'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:20 pm'!

WorkRecorderFossil subclass: #DirectWorkRecorderFossil
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fossil'!
DirectWorkRecorderFossil comment:
'A Fossil for a DirectWorkRecorder.'!

(DirectWorkRecorderFossil getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #COPY; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!DirectWorkRecorderFossil methodsFor: 'protected: accessing'!

{ResultRecorder} actualRecorder

	^DirectWorkRecorder
		create: self endorsementsFilter
		with: self trailBlazer! !

!DirectWorkRecorderFossil methodsFor: 'create'!

create: loginAuthority {IDRegion}
	with: endorsementsFilter {Filter}
	with: trailBlazer {TrailBlazer}
	
	super create: loginAuthority
		with: endorsementsFilter
		with: trailBlazer.
	self newShepherd.
	self remember.! !

!DirectWorkRecorderFossil methodsFor: 'backfollow'!

{void} storeDataRecordingAgents: sensorCrum {SensorCrum}
	with: agenda {Agenda}

	"do nothing"!

{void} storeRangeElementRecordingAgents: rangeElement {BeRangeElement}
	with: sensorCrum {SensorCrum}
	with: agenda {Agenda}

	((rangeElement isKindOf: BeEdition) or: [rangeElement isKindOf: BePlaceHolder])
		ifTrue:
			[super storeRangeElementRecordingAgents: rangeElement
				with: sensorCrum
				with: agenda]! !

!DirectWorkRecorderFossil methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !