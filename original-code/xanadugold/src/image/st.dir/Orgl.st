'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:46 pm'!

Heaper subclass: #Orgl
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!

(Orgl getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #OBSOLETE; yourself)!

!Orgl methodsFor: 'accessing'!

{ScruTable of: PackOBits} asDataTable
	"return a table of the data only"
	self subclassResponsibility!

{ScruTable} asTable
	"return a table of the contents"
	self subclassResponsibility!

{Orgl} combine: other {Orgl}
	"return a new orgl which combines two non-overlapping orgls"
	self subclassResponsibility!

{Mapping} compare: other {Orgl}
	"return a mapping from my domain to the region that other shares with me"
	self subclassResponsibility!

{CoordinateSpace} coordinateSpace
	"coordinate space"
	self subclassResponsibility!

{Orgl} copy: region {XnRegion}
	"return subset of this orgl which lies in the region"
	self subclassResponsibility!

{IntegerVar} count
	"the number of elements known to be in the orgl"
	self subclassResponsibility!

{Orgl} delayedExtendFindMatching: gk {ActualGateKeeper} with: stampID {ID}
	self subclassResponsibility!

{Orgl} delayedFindMatching: gk {ActualGateKeeper} with: endorsementsFilter {Filter of: (XnRegion of: ID)}
	self subclassResponsibility!

{XnRegion} domain
	self subclassResponsibility!

{XnRegion of: ID} endorsements
	self subclassResponsibility!

{Heaper} fetch: key {Position}
	"look up an element, return NULL if not there"
	self subclassResponsibility!

{Orgl} findMatching: gk {GateKeeper} with: endorsementsFilter {Filter of: (XnRegion of: ID)}
	"?????"
	self subclassResponsibility!

{Heaper} get: key {Position}
	"look up an element, blast if not there"
	| value {Heaper} |
	value _ self fetch: key.
	value == NULL
		ifTrue: [Heaper BLAST: #NotInRecord]
		ifFalse: [^ value]!

{BooleanVar} includesKey: key {Position}
	
	^ (self fetch: key) ~~ NULL!

{BooleanVar} isKnownEmpty
	self subclassResponsibility!

{XnRegion} knownSharedRegion: other {Orgl}
	"return the region in this orgl that leads to data in the other orgl"
	self subclassResponsibility!

{XnRegion} simpleDomain
	self subclassResponsibility!

{ID} stampID
	self subclassResponsibility!

{Orgl} transform: mapping {Mapping}
	"return an orgl with the coordinates transformed"
	self subclassResponsibility!

{XnRegion} unusedDomain
	self subclassResponsibility!

{XnRegion} usedDomain
	self subclassResponsibility!

{void} wait: sensor {XnSensor}
	"ring the sensor when partiality gets filled in"
	self subclassResponsibility!

{Orgl} with: gk {GateKeeper} 
	with: key {Position} 
	with: value {Heaper as: (Manipulator | ActualOrgl | ID | PackOBits)} 
	"create a new orgl with key->value mapping; overrides existing mapping"
	
	self subclassResponsibility!

{Orgl} without: key {Position}
	"return subset of this orgl without anything at the given position"
	self subclassResponsibility!

{Orgl} withoutAll: region {XnRegion}
	"return subset of this orgl without anything at the given positions"
	self subclassResponsibility! !

!Orgl methodsFor: 'smalltalk: passe'!

{Orgl} combine: other {Orgl} with: km {KeyMaster default: NULL}
	"return a new orgl which combines two non-overlapping orgls"
	self passe. "use combine:"!

{Orgl} copy: region {XnRegion} with: km {KeyMaster default: NULL}
	"return subset of this orgl which lies in the region"
	self passe. "use copy:"!

{Orgl} transform: mapping {Mapping} with: km {KeyMaster default: NULL}
	"return an orgl with the coordinates transformed"
	self passe. "use transform:"!

{Orgl} without: key {Position} with: km {KeyMaster default: NULL}
	"return subset of this orgl without anything at the given position"
	self passe. "use without:"!

{Orgl} withoutAll: region {XnRegion} with: km {KeyMaster default: NULL}
	"return subset of this orgl without anything at the given positions"
	self passe. "use withoutAll:"! !