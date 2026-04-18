'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:57 pm'!

StubA subclass: #StubAHook
	instanceVariableNames: 'myPackagingCategory {Category generated smalltalk}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-pkgstub'!

(StubAHook getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(PACKAGE.HOOK CoreAHook ); yourself)!

!StubAHook methodsFor: 'generated:'!

packagingCategory ^myPackagingCategory!

packagingCategory: cat myPackagingCategory := cat! !