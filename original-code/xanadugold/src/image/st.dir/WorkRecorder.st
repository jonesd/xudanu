'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:34 pm'!

ResultRecorder subclass: #WorkRecorder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-backrec'!
WorkRecorder comment:
'Represents the a persistent works or rangeWorks query'!

(WorkRecorder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!WorkRecorder methodsFor: 'create'!

create: endorsementsFilter {Filter}
	with: trailBlazer {TrailBlazer}
	
	super create: endorsementsFilter
		with: (endorsementsFilter relevantRegion cast: CrossRegion)
		with: trailBlazer! !

!WorkRecorder methodsFor: 'accessing'!

{BooleanVar} accepts: element {BeRangeElement}

	^element isKindOf: BeWork!

{BooleanVar} isDirectOnly
	
	self subclassResponsibility! !

!WorkRecorder methodsFor: 'backfollow'!

{void} delayedStoreBackfollow: edition {BeEdition}
	with: finder {PropFinder} 
	with: fossil {RecorderFossil}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	self subclassResponsibility!

{void} recordImmediateWorks: element {BeRangeElement} with: fossil {RecorderFossil}
	"If there are any Works directly on the RangeElement which pass the filters, record them"
	
	element cast: BeEdition into: [ :edition |
		edition currentWorks stepper forEach: [ :work {BeWork} |
			((work canBeReadBy: self keyMaster)
					and: [self endorsementsFilter match: work endorsements])
				ifTrue:
					[(RecorderTrigger make: fossil with: work) schedule]]]
	others:
		[]! !