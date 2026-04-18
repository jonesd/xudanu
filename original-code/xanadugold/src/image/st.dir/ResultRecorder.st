'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:33 pm'!

Heaper subclass: #ResultRecorder
	instanceVariableNames: '
		myPermissionsFilter {Filter}
		myEndorsementsFilter {Filter}
		myRelevantEndorsements {CrossRegion}
		myKeyMaster {FeKeyMaster}
		myTrailBlazer {TrailBlazer}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-backrec'!
ResultRecorder comment:
'Represents the persistent embodiment of a query operation. Can be stored on disk in the form of a RecorderFossil. The abstract protocol deals with:
	- caching previous results to avoid duplication
	- storing results in a trail at unique positions
	- managing persistent permissions
	- looking for immediate results
	- checking whether a good candidate (identified by the canopy props) should really go into the trail'!

(ResultRecorder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!ResultRecorder methodsFor: 'accessing'!

{BooleanVar} accepts: element {BeRangeElement}
	"Whether this recorder accepts this kind of RangeElement"
	
	self subclassResponsibility!

{IDRegion} actualAuthority

	^myKeyMaster actualAuthority!

{PropFinder} bertPropFinder
	"Something to find potential candidates given a source for the query"

	^PropFinder 
		backfollowFinder: self permissionsFilter 
		with: self endorsementsFilter!

{Filter} endorsementsFilter  
	"The endorsements I am looking for"
	
	^myEndorsementsFilter!

{BooleanVar} isDirectOnly
	"Whether the recorder is for a query with the directContainersOnly flag"
	
	self subclassResponsibility!

{FeKeyMaster} keyMaster

	^myKeyMaster!

{Filter of: ID} permissionsFilter
	"The permissions I am looking for"
	
	^myPermissionsFilter!

{SensorProp} sensorProp
	"A SensorProp which corresponds to what I am looking for"
	
	^SensorProp
		make: (self permissionsFilter relevantRegion cast: IDRegion)
		with: myRelevantEndorsements
		with: false! !

!ResultRecorder methodsFor: 'recording'!

{void} record: answer {BeRangeElement}
	"tell my TrailBlazer to recorder it"
	
	myTrailBlazer record: answer!

{void} triggerIfMatching: finder {PropFinder} with: fossil {RecorderFossil}
	"Trigger myself if I match the finder's profile"
	
	finder cast: AbstractRecorderFinder into: [ :arf |
		arf checkRecorder: self with: fossil]! !

!ResultRecorder methodsFor: 'create'!

create: endorsementsFilter {Filter}
	with: relevantEndorsements {CrossRegion}
	with: trailBlazer {TrailBlazer}
	
	super create.
	Ravi thingToDo. "decide whether this should have a filter or just the relevant regions"
	myEndorsementsFilter := endorsementsFilter.
	myRelevantEndorsements := relevantEndorsements.
	myKeyMaster := CurrentKeyMaster fluidGet.
	
	[BeGrandMap] USES.
	myPermissionsFilter := CurrentGrandMap fluidGet globalIDFilterSpace
		anyFilter: myKeyMaster actualAuthority.
	myTrailBlazer := trailBlazer! !

!ResultRecorder methodsFor: 'backfollow'!

{void} delayedStoreBackfollow: edition {BeEdition}
	with: finder {PropFinder} 
	with: fossil {RecorderFossil}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	"The immediate part of the backfollow has reached an Edition while traversing northwards. I now get to decide what to do next."
	
	self subclassResponsibility!

{void} delayedStoreMatching: element {BeRangeElement}
	with: finder {PropFinder} 
	with: fossil {RecorderFossil}
	with: hCrumCache {HashSetCache of: HistoryCrum}
	"The immediate part of the backfollow has reached an RangeElement of the original Edition. I now get to decide what to do next to continue the operation"
	
	 element delayedStoreBackfollow: finder with: fossil with: self with: hCrumCache
	 "this is a default implementation, which subclasses may override or modify"! !

!ResultRecorder methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !