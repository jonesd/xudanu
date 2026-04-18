'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:55 pm'!

CoreA subclass: #CoreAHook
	instanceVariableNames: 'myPackagingCategory {Category generated smalltalk}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-pkgcore'!

(CoreAHook getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #HOOK; add: #NO.GC; yourself)!

!CoreAHook methodsFor: 'generated:'!

packagingCategory ^myPackagingCategory!

packagingCategory: cat myPackagingCategory := cat! !