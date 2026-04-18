'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:54 pm'!

Heaper subclass: #CanopyCache
	instanceVariableNames: '
		myCachedCrum {CanopyCrum}
		myCachedRoot {CanopyCrum}
		myCachedPath {MuSet of: CanopyCrum}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!

(CanopyCache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CanopyCache methodsFor: 'protected: creation'!

create
	super create.
	myCachedCrum _ NULL.
	myCachedRoot _ NULL.
	myCachedPath _ MuSet make! !

!CanopyCache methodsFor: 'operations'!

{void} clearCache
	"Clear the cache because the canopy has
	 changed.  This ought to destroy the cachedPath. 
	 This must be cleared after every episode!!!!!!"

	myCachedCrum _ NULL.
	myCachedRoot _ NULL.
	myCachedPath _ MuSet make.!

{MuSet of: CanopyCrum} pathFor: canopyCrum {CanopyCrum} 
	"Return the set of all crums from canopyCrum 
	(inclusive) to the top of canopyCrum's canopy."

	(myCachedCrum basicCast: Heaper star) == canopyCrum
		ifFalse: 
			[| cur {CanopyCrum} |
			cur _ canopyCrum.
			myCachedCrum _ canopyCrum.
			myCachedRoot _ canopyCrum.
			myCachedPath _ MuSet make.
			[cur ~~ NULL]
				whileTrue: 
					[myCachedRoot _  cur.
					myCachedPath store: cur.
					cur _ cur fetchParent]].
	^myCachedPath!

{CanopyCrum} rootFor: bertCrum {CanopyCrum} 
	"Return the crum at the top of canopyCrum's canopy."

	self pathFor: bertCrum.
	^myCachedRoot!

{void} updateCache: childCrum {CanopyCrum} forParent: parentCrum {CanopyCrum} 
	"If the cache contains childCrum it must be made 
	to contain childCrum's new parent: parentCrum. 
	Also update CachedRoot." 

	(myCachedPath hasMember: childCrum) ifTrue: 
		[myCachedPath store: parentCrum.
		 (myCachedRoot basicCast: Heaper star) == childCrum 
			ifTrue: [myCachedRoot _ parentCrum]]!

{void} updateCacheFor: canopyCrum {CanopyCrum} 
	"If the cache contains canopyCrum, it must be updated 
	because canopyCrum has new parents. For now, just 
	invalidate the cache." 

	(myCachedCrum basicCast: Heaper star) == canopyCrum
		ifTrue: [self clearCache]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CanopyCache class
	instanceVariableNames: ''!

(CanopyCache getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CanopyCache class methodsFor: 'make'!

make
	^ self create! !