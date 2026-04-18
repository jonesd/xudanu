'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:11 pm'!

Abraham subclass: #OPart
	instanceVariableNames: 'mySensorCrum {SensorCrum}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Ents'!

(OPart getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.ANCESTOR; add: #DEFERRED.LOCKED; yourself)!

!OPart methodsFor: 'backfollow'!

{XnRegion} attachTrailBlazer: blazer {TrailBlazer}
	"Attach the TrailBlazer to this Edition, and return the region of partiality it is attached to"
	
	self subclassResponsibility!

{void} checkTrailBlazer: blazer {TrailBlazer}
	"Make sure that everyone below here that might have a TrailBlazer, has the given one"
	
	self subclassResponsibility!

{TrailBlazer | NULL} fetchTrailBlazer
	"If there is a TrailBlazer somewhere below this Edition, return one of them"
	
	self subclassResponsibility!

{HistoryCrum} hCrum
	self subclassResponsibility! !

!OPart methodsFor: 'accessing'!

{Mapping} mappingTo: trace {TracePosition} with: initial {Mapping}
	"return the mapping into the domain space of the given trace"
	^self hCrum mappingTo: trace with: initial!

{SensorCrum} sensorCrum
	^mySensorCrum! !

!OPart methodsFor: 'protected: delete'!

{void} dismantle
	DiskManager insistent: 2 with:
		[(Heaper isConstructed: mySensorCrum)
			ifTrue: [mySensorCrum removePointer: self].
		((Heaper isConstructed: self hCrum) and: [Heaper isConstructed: self hCrum bertCrum])
			ifTrue: [self hCrum bertCrum removePointer: self hCrum].
		super dismantle]! !

!OPart methodsFor: 'smalltalk:'!

hinspect
	self hCrum inspect!

inspect
	Sensor leftShiftDown
		ifTrue: [self basicInspect]
		ifFalse: [EntView openOn: (TreeBarnacle new
					buildOn: self
					gettingChildren: [:crum | crum crums]
					gettingImage: [:crum | DisplayText text: crum displayString asText textStyle: (TextStyle styleNamed: #small)]
					at: 0 @ 0
					vertical: true
					separation: 5 @ 10)]!

inspectCanopy
	self hCrum bertCrum inspect!

inspectMenuArray
	^#(
		('inspect history'	hinspect				'')
		('bert canopy'		inspectCanopy			'')
		('recorder canopy'	inspectRecorderCanopy		''))!

inspectRecorderCanopy
	self sensorCrum inspect!

showOn: oo
	
	oo << self getCategory name << $( << self hCrum hCut << ', ' << self hCrum asOop << ', ' << self hCrum oParents count << $)! !

!OPart methodsFor: 'protected: create'!

create: scrum {SensorCrum | NULL} 
	super create.
	scrum == NULL
			ifTrue: [mySensorCrum _ SensorCrum make]
			ifFalse: [mySensorCrum _ scrum].
	mySensorCrum addPointer: self!

create: hash {UInt32} with: scrum {SensorCrum | NULL}
	super create: hash.
	scrum == NULL
			ifTrue: [mySensorCrum _ SensorCrum make]
			ifFalse: [mySensorCrum _ scrum].
	mySensorCrum addPointer: self! !

!OPart methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: mySensorCrum hashForEqual! !

!OPart methodsFor: 'smalltalk: passe'!

{void} wait: sensor {XnSensor}
	
	self passe! !

!OPart methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySensorCrum _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySensorCrum.! !