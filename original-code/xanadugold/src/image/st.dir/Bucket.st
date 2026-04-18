'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:41 pm'!

Heaper subclass: #Bucket
	instanceVariableNames: '
		bucketsPointedAt {Table of: Buckets}
		possiblyPointingIn {Table of: Buckets}
		stuffInBucket {Table of: Heaper}
		cashedLastBucketPointedAt {Bucket}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Incremental GC'!

(Bucket getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Bucket methodsFor: 'gc'!

{void} gcBucket: bucketToMoveTo {Bucket}
"garbageCollect This bucket the bulk way,  by looking at all the things the possiblyPointingAts point at and saving those in the bucket to move to"!

{void} gcThing: bucketToMoveTo {Bucket}
"garbageCollect This thing the small way,  by looking at all the things the possiblyPointingAts point at and saving if pointed at else throw away"! !