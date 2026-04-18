'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:55 pm'!

SingleContainingViewer subclass: #FMCacheViewer
	instanceVariableNames: '
		myCachedBits {Image}
		myRedisplayRequestor {BooleanModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cachevu'!

(FMCacheViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMCacheViewer methodsFor: 'accessing'!

{void} composeWith: layout {AbstractLayout}

	self clearCache.
	super composeWith: layout!

{Image} fetchCachedImage

	^ myCachedBits!

{BooleanModel} redisplayRequestor

	^ myRedisplayRequestor!

{XnRegion} regionAt: pos {IntegerVar}

	^ self subView regionAt: pos!

{Position} selectionFor: aPoint {PointPos}
	"Find the model position corresponding to the display position (a XuPoint)."

	^ self subView selectionFor: aPoint! !

!FMCacheViewer methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel}

	sender == (myCachedBits basicCast: XnModel)
		ifTrue: [self changedImage]
		ifFalse: [myRedisplayRequestor getValue
			ifTrue: [self clearCache.
				self changedImage]]!

{void} updateImage: aSubView {Viewer unused}
	self clearCache.
	self changedImage! !

!FMCacheViewer methodsFor: 'displaying'!

{void} displayOn: dWarp {Warp}

	myCachedBits == NULL
		ifTrue: [ | aWarp {Warp} im {Image} |
			im _ Image image.XuPoint: ((dWarp enclosure extent) basicCast: PointPos).
			aWarp _ Warp make: im with: im enclosure.
			self subView displayOn: aWarp.
			self setCache: im.
			aWarp destroy].
	myCachedBits displayOn: dWarp.
	myRedisplayRequestor setValue: false.
	self validate! !

!FMCacheViewer methodsFor: 'creation/dissolution'!

create: onSubView {Viewer} with: refresh {BooleanModel}

	super create: onSubView.
	myCachedBits _ NULL.
	myRedisplayRequestor _ refresh.
	myRedisplayRequestor addDependent: self!

{void} destruct

	self clearCache.
	myRedisplayRequestor removeDependent: self.
	myRedisplayRequestor _ NULL.
	super destruct! !

!FMCacheViewer methodsFor: 'protected: enclosure'!

{PointRegion} computeEnclosure

	myCachedBits == NULL
		ifTrue: [^ super computeEnclosure]
		ifFalse: [^ myCachedBits enclosure].! !

!FMCacheViewer methodsFor: 'private: caching'!

{void} clearCache
	
	myCachedBits == NULL
		ifFalse: [myCachedBits removeDependent: self.
			myCachedBits destroy.
			myCachedBits _ NULL]!

{void} setCache: toImage {Image}
	self clearCache.
	myCachedBits _ toImage.
	myCachedBits addDependent: self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMCacheViewer class
	instanceVariableNames: ''!

(FMCacheViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMCacheViewer class methodsFor: 'make'!

make: subView {Viewer}

	^ self create: subView with: BooleanModel make!

make: subView {Viewer} with: redisplay {BooleanModel}

	^ self create: subView with: redisplay! !