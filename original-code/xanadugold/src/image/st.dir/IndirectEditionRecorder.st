'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:33 pm'!

EditionRecorder subclass: #IndirectEditionRecorder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-backrec'!
IndirectEditionRecorder comment:
'Represents the a persistent transcluders or rangeTranscluders query with directContainersOnly flag off'!

(IndirectEditionRecorder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!IndirectEditionRecorder methodsFor: 'accessing'!

{BooleanVar} isDirectOnly
	
	^false! !

!IndirectEditionRecorder methodsFor: 'create'!

create: directFilter {Filter}
	with: indirectFilter {Filter}
	with: trailBlazer {TrailBlazer}
	
	super create: directFilter
		with: indirectFilter
		with: trailBlazer! !

!IndirectEditionRecorder methodsFor: 'backfollow'!

{void} delayedStoreBackfollow: edition {BeEdition}
	with: finder {PropFinder} 
	with: fossil {RecorderFossil}
	with: hCrumCache {HashSetCache of: HistoryCrum}

	super delayedStoreBackfollow: edition with: finder with: fossil with: hCrumCache.
	edition delayedStoreBackfollow: finder with: fossil with: self with: hCrumCache.! !