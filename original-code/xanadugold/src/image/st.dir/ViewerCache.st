'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:25 pm'!

Heaper subclass: #ViewerCache
	instanceVariableNames: '
		myViewer {Viewer}
		myWarp {Warp}
		myCache {MuTable of: ViewerCache}
		myCycleNumber {IntegerVar}'
	classVariableNames: 'ViewerCacheCycle {IntegerVar} '
	poolDictionaries: ''
	category: 'FM-Warp Display'!
ViewerCache comment:
'The ViewerCache is specifically designed to cache viewers and their warps for the WarpDrive.  The WarpDrive uses the cache to determine if the drive image bits are already correct.  This allows the WarpDrive to avoid redisplaying viewers unneccessarily.'!

(ViewerCache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ViewerCache methodsFor: 'cache accessing'!

{ViewerCache} addCacheFor: viewer {Viewer} 
	"This method returns the cache for the specified viewer. If the cache 
	does not already exist, it is created."

	| nc {ViewerCache} |
	nc _ ViewerCache make: viewer.
	self cacheTable at: (HeaperAsPosition make: viewer) store: nc.
	^nc!

{ViewerCache} fetchCache: viewer {Viewer} 
	"This method allows the drive to get the cache for a specified viewer."

	myCache == NULL ifTrue: [^ NULL].
	^ (myCache fetch: (HeaperAsPosition make: viewer)) cast: ViewerCache!

{Warp} fetchWarp: viewer {Viewer} 
	"This method allows the drive to get the cached warp (the one used 
	the last time the drive displayed the specified viewer) for a 
	specified viewer. "

	| tCache {ViewerCache} |
	myCache == NULL ifTrue: [^ NULL].
	tCache _ (self cacheTable fetch: (HeaperAsPosition make: viewer)) quickCast: ViewerCache.
	tCache == NULL
		ifTrue: [^NULL]
		ifFalse: [^tCache warp]!

{BooleanVar} includesKey: viewer {Viewer}

	"This method allows a drive to determine if the cache already contains a specific viewer"
	
	myCache == NULL ifTrue: [^ false].
	^ self cacheTable includesKey: (HeaperAsPosition make: viewer)!

{void} invalidate: viewer {Viewer}

	"This method invalidates a viewer and all of it's contained viewers"
	
	self cacheTable wipe: (HeaperAsPosition make: viewer)!

{void} setWarp: warp {Warp} 
	"This method sets the warp for a particular cache (and viewer)"

	myWarp _ warp!

{Viewer} viewer
	"This method returns the viewer associated with this cache"

	^myViewer!

{Warp} warp
	"This method returns the warp associated with this cache (and its 
	viewer)"

	myCycleNumber _ ViewerCacheCycle.
	^myWarp! !

!ViewerCache methodsFor: 'cache management'!

{void} flushCache

	| flushSet {MuSet} |
	
	myCache == NULL ifTrue: [^ VOID].
	flushSet _ NULL.
	myCache stepper forEach: [:cache {ViewerCache} |
		((cache cycle + 100) < ViewerCacheCycle)
			ifTrue: [flushSet == NULL ifTrue: [flushSet _ MuSet make].
				flushSet introduce: cache]
			ifFalse: [cache flushCache]].
	flushSet isEmpty not
		ifTrue: [flushSet stepper forEach: [:cache {ViewerCache} |
			self invalidate: (cache viewer)]]! !

!ViewerCache methodsFor: 'private: accessing'!

{MuTable of: ViewerCache} cacheTable 

	myCache == NULL
		ifTrue: [myCache _ HashTable make.CoordinateSpace: HeaperSpace make with: 7].
	^ myCache!

{IntegerVar} cycle

	^ myCycleNumber! !

!ViewerCache methodsFor: 'testing'!

{UInt32} hashForEqual
	"shift right by five to eliminate insignificant bits (ones that don't change much)"
	
	^ (self basicCast: UInt32) >> 5!

{BooleanVar} isEqual: other {Heaper}

	^ self == other! !

!ViewerCache methodsFor: 'creation'!

create: onViewer {Viewer}

	super create.
	myViewer _ onViewer.
	myWarp _ NULL.
	myCache _ NULL.
	myCycleNumber _ ViewerCacheCycle! !

!ViewerCache methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << '( a '.
	myViewer == NULL
		ifTrue: [oo << 'nothing!!']
		ifFalse: [oo << myViewer getCategory name].
	oo << '->' << myWarp << ' containing ['.
	myCache == NULL
		ifTrue: [oo << 'empty']
		ifFalse: [myCache stepper forEach: [:cache {ViewerCache} | oo << cache << ', ']].
	oo << '])'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ViewerCache class
	instanceVariableNames: ''!

(ViewerCache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ViewerCache class methodsFor: 'pseudo constructors'!

make: onViewer {Viewer}

	^ self create: onViewer! !

!ViewerCache class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited

	ViewerCacheCycle _ IntegerVar0! !

!ViewerCache class methodsFor: 'accessing'!

{IntegerVar} currentCycle

	^ ViewerCacheCycle! !