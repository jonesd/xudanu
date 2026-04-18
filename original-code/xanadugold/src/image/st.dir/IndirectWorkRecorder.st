'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:33 pm'!

WorkRecorder subclass: #IndirectWorkRecorder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-backrec'!
IndirectWorkRecorder comment:
'Represents the a persistent works or rangeWorks query with the directContainersOnly flag off'!

(IndirectWorkRecorder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!IndirectWorkRecorder methodsFor: 'create'!

create: endorsementsFilter {Filter}
	with: trailBlazer {TrailBlazer}
	
	super create: endorsementsFilter
		with: trailBlazer! !

!IndirectWorkRecorder methodsFor: 'accessing'!

{BooleanVar} isDirectOnly
	
	^false! !

!IndirectWorkRecorder methodsFor: 'backfollow'!

{void} delayedStoreBackfollow: edition {BeEdition}
	with: finder {PropFinder} 
	with: fossil {RecorderFossil}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	self recordImmediateWorks: edition with: fossil.
	edition delayedStoreBackfollow: finder with: fossil with: self with: hCrumCache!

{void} delayedStoreMatching: element {BeRangeElement}
	with: finder {PropFinder} 
	with: fossil {RecorderFossil}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	
	 self recordImmediateWorks: element with: fossil.
	 super delayedStoreMatching: element with: finder with: fossil with: hCrumCache! !