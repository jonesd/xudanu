'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:16 pm'!

UpdateRecord subclass: #SelectionUR
	instanceVariableNames: 'regionInternal '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Update Mechanism'!


!SelectionUR methodsFor: 'accessing'!

{XnRegion} region
	^regionInternal! !

!SelectionUR methodsFor: 'create/delete'!

create: region {XnRegion}
	super create.
	regionInternal _ region! !

!SelectionUR methodsFor: 'printint'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << regionInternal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SelectionUR class
	instanceVariableNames: ''!


!SelectionUR class methodsFor: 'pseudo constructors'!

make: region {XnRegion}
	^ self create: region! !