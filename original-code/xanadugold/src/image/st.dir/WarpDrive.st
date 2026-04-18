'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:26 pm'!

Heaper subclass: #WarpDrive
	instanceVariableNames: '
		myEngine {WarpEngine}
		myViewerCache {ViewerCache}
		myFlushCycle {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Warp Display'!
WarpDrive comment:
'The WarpDrive class is the portion of FM that controls the display cycle.  It maintains the actual drawing engine (a WarpEngine, which actually performs drawing operations) and maintains sufficient information to handle incremental redisplay.  That is, it tracks the bits corresponding to viewers that displayed on it.  If the same viewer is requested to redisplay and the oldWarp isEqual: currentWarp (same place, same size) and the viewer is unchanged, then it will not be redisplayed because all of its bits are already correct.  Theoretically, the drive can also just move a viewer''s bits if it is being redisplayed in a new location and the viewer is unchanged.
  Where Warps are stateless, WarpDrive is all state.  It represents the appearance of its image (display, offscreen pixmap, ...).  

The WarpDrive uses a WarpEngine to actually do the drawing.  Actually, the warp asks for the engine and sends the display commands to the engine directly.  This is a private exchange between the warp, warpdrive and warpengine.  The main reason for this triple (as opposed to just a warp and warpdrive) is that Smalltalk, to be efficient, wants to have a drawing object that is patterned after a bitblt (and can therefore use bitblt primitives).  Because of this, there can be no instance variables in the abstract superclass of the actual drawing engine.  Since the WarpDrive does the incremental redisplay handling also, it needs some local state, so the alternative implementation is quite tortured.  All in all, this is a better modularity anyway, separating the to main functions into different classes.'!

(WarpDrive getOrMakeCxxClassDescription)
	friends:
'/* friends for class WarpDrive */
friend class Warp;
friend class TestWarpDrive;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WarpDrive methodsFor: 'accessing'!

{WarpEngine} engine

	^ myEngine!

{BooleanVar} setupFrom: warp {Warp}
	"whether last setup was from warp; this is private between the two classes"

	^ myEngine setupFrom: warp! !

!WarpDrive methodsFor: 'testing'!

{UInt32} hashForEqual

	^ (self basicCast: UInt32) >> 5!

{BooleanVar} isEqual: other {Heaper}

	^ self == other! !

!WarpDrive methodsFor: 'coloring'!

{void} inkColor: color {FMColor | NULL}
	"This routine changes the ink to a color."
	myEngine inkColor: color!

{void} inkColorMap: colorMap {FMColorMap | NULL} 
	"This routine changes the ink to a colorMap."
	myEngine inkColorMap: colorMap!

{void} inkImage: image {Image | NULL}
	"Use image as my ink.  If the current ink is a mask,
	 then the new warp should use the combination (and) of the two.
	 This needs to make a new warp that understands replicating images."
	myEngine inkImage: image! !

!WarpDrive methodsFor: 'display management'!

{void} finishDisplay
	"This method is called at the end of a display cycle to allow the 
	drive complete any partially done bit copies and to flush old viewers 
	from its cache"
	
	((myFlushCycle + 25) < (ViewerCache currentCycle))
		ifTrue: [myViewerCache flushCache]!

{void} refresh: region {PointRegion unused} 
	"This method is called to specify any regions of the
drive that are 
	invalid and need to be redisplayed."
	"for now, redisplay all"

	myViewerCache _ ViewerCache make: NULL!

{void} setupDisplay
	"This method is invoked at the start of a display cycle to allow the 
	drive to initialize any components for the display."

	CurrentViewerCache fluidSet: myViewerCache!

{Warp} warpAt: dsp {PointTranslateDsp} with: restrict {PointRegion}

	^ Warp make: dsp with: restrict with: self! !

!WarpDrive methodsFor: 'incremental redisplay'!

{void} display: viewer {Viewer} using: warp {Warp} 
	"This is the drive incremental redisplay message. It should only be 
	called from Warp display:."

	| oldWarp {Warp} tmpCache {ViewerCache} curCache {ViewerCache} |
	curCache _ CurrentViewerCache fluidGet cast: ViewerCache.
	tmpCache _ curCache fetchCache: viewer.
	tmpCache == NULL
		ifTrue: [tmpCache _ curCache addCacheFor: viewer]
		ifFalse: [viewer isChanged ifFalse: [oldWarp _ tmpCache warp.
				(oldWarp isEqual: warp)
					ifTrue: [^VOID]
					ifFalse: [curCache invalidate: viewer.
						tmpCache _ curCache addCacheFor: viewer]]].
	tmpCache setWarp: warp.
	CurrentViewerCache fluidBind: tmpCache during: [viewer displayOn: warp]! !

!WarpDrive methodsFor: 'creation'!

create: engine {WarpEngine}
	super create.
	myEngine _ engine.
	myViewerCache _ ViewerCache make: NULL.
	myFlushCycle _ ViewerCache currentCycle!

{void} destruct

	myEngine _ NULL.
	myViewerCache destroy.
	super destruct! !

!WarpDrive methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << ' on ' << myEngine << ' caching: ' << myViewerCache! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WarpDrive class
	instanceVariableNames: ''!

(WarpDrive getOrMakeCxxClassDescription)
	friends:
'/* friends for class WarpDrive */
friend class Warp;
friend class TestWarpDrive;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WarpDrive class methodsFor: 'smalltalk: initialization'!

staticTimeNonInherited

	ViewerCache defineFluid: #CurrentViewerCache with: Emulsion globalEmulsion with: [NULL].! !

!WarpDrive class methodsFor: 'pseudo constructors'!

make: onEngine {WarpEngine}

	^ self create: onEngine! !

!WarpDrive class methodsFor: 'smalltalk: cleanup'!

cleanupGarbage

	CurrentViewerCache _ NULL! !