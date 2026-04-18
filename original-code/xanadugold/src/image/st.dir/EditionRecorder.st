'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:32 pm'!

ResultRecorder subclass: #EditionRecorder
	instanceVariableNames: '
		myDirectFilter {Filter}
		myIndirectFilter {Filter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-backrec'!
EditionRecorder comment:
'Represents the a persistent transcluders or rangeTranscluders query'!

(EditionRecorder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!EditionRecorder methodsFor: 'accessing'!

{BooleanVar} accepts: element {BeRangeElement}

	^element isKindOf: BeEdition!

{Filter} directFilter

	^myDirectFilter!

{Filter} indirectFilter

	^myIndirectFilter!

{BooleanVar} isDirectOnly
	
	self subclassResponsibility! !

!EditionRecorder methodsFor: 'create'!

create: directFilter {Filter}
	with: indirectFilter {Filter}
	with: trailBlazer {TrailBlazer}
	
	super create: ((directFilter unionWith: indirectFilter) cast: Filter)
		with: ((directFilter relevantRegion unionWith: indirectFilter relevantRegion ) cast: CrossRegion)
		with: trailBlazer.
	
	myDirectFilter := directFilter.
	myIndirectFilter := indirectFilter.! !

!EditionRecorder methodsFor: 'backfollow'!

{void} delayedStoreBackfollow: edition {BeEdition}
	with: finder {PropFinder unused} 
	with: fossil {RecorderFossil}
	with: hCrumCache {HashSetCache of: HistoryCrum unused}

	CurrentKeyMaster fluidBind: self keyMaster during:
		[((myDirectFilter match: edition visibleEndorsements)
				and: [edition anyPasses: (PropFinder
					backfollowFinder: self permissionsFilter with: myIndirectFilter)])
			ifTrue:
				[(RecorderTrigger make: fossil with: edition) schedule]]! !