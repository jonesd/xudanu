'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:32 pm'!

WorkRecorder subclass: #DirectWorkRecorder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-backrec'!
DirectWorkRecorder comment:
'Represents the a persistent works or rangeWorks query with the directContainersOnly flag on'!

(DirectWorkRecorder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DirectWorkRecorder methodsFor: 'create'!

create: endorsementsFilter {Filter}
	with: trailBlazer {TrailBlazer}
	
	super create: endorsementsFilter
		with: trailBlazer! !

!DirectWorkRecorder methodsFor: 'accessing'!

{BooleanVar} isDirectOnly
	
	^true! !

!DirectWorkRecorder methodsFor: 'backfollow'!

{void} delayedStoreBackfollow: edition {BeEdition unused}
	with: finder {PropFinder unused} 
	with: fossil {RecorderFossil unused}
	with: hCrumCache {HashSetCache unused of: HistoryCrum }
	
	Heaper BLAST: #FatalError. "This algorithm should never reach here"!

{void} delayedStoreMatching: element {BeRangeElement}
	with: finder {PropFinder unused} 
	with: fossil {RecorderFossil}
	with: hCrumCache {HashSetCache unused of: HistoryCrum }
	
	 self recordImmediateWorks: element with: fossil "and nothing else"! !