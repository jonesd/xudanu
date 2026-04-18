'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:16 pm'!

UpdateRecord subclass: #RegionUR
	instanceVariableNames: 'regionInternal {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Update Mechanism'!
RegionUR comment:
'This is currently used for changes to a form. '!

(RegionUR getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RegionUR methodsFor: 'accessing'!

{XnRegion} region
	^regionInternal! !

!RegionUR methodsFor: 'create/delete'!

create: region {XnRegion}
	super create.
	regionInternal _ region! !

!RegionUR methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << regionInternal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RegionUR class
	instanceVariableNames: ''!

(RegionUR getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RegionUR class methodsFor: 'pseudo constructors'!

make: region {XnRegion}
	^ self create: region! !