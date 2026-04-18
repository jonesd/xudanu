'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:24 pm'!

WarpDrive subclass: #TestWarpDrive
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Warp Display'!

(TestWarpDrive getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TestWarpDrive methodsFor: 'testing special'!

{void} dumpCacheOn: oo {ostream reference}

	oo << 'Dumping WarpDrive
	engine is ' << myEngine << '
	flushCycle is ' << myFlushCycle << '
	cache is ' << myViewerCache << '

'.! !