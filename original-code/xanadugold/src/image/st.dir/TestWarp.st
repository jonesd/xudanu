'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:24 pm'!

Warp subclass: #TestWarp
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Warp Display'!

(TestWarp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TestWarp methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	super printOn: oo.
	oo << '
testdrive cache: '.
	(self drive cast: TestWarpDrive) dumpCacheOn: oo.
	oo << '
'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TestWarp class
	instanceVariableNames: ''!

(TestWarp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TestWarp class methodsFor: 'pseudoconstructors'!

make: anImage {Image} with: bounds {PointRegion} 

	| dBounds {PointRegion}  |
	dBounds _ bounds cast: PointRegion.
	^Warp
		make: PointTranslateDsp make
		with: dBounds
		with: (TestWarpDrive make: (TestWarpEngine make: anImage with: dBounds))! !