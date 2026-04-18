'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:43 pm'!

Heaper subclass: #FMResourceManager
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-resourc'!
FMResourceManager comment:
'This class is a representation of a resource manager for FM.  Concrete implementations of this class for specific machine/os/windowing systems provide access to their native resource managers.  This resource manager is restricted to provide access to simple FM compatible resources such as pixmaps (Images) and icons.'!

(FMResourceManager getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMResourceManager */
friend SPTR(FMResourceManager) fMResourceManager ();
friend SPTR(FMResourceManager) fMResourceManager (MuTable * onTable);';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMResourceManager methodsFor: 'deferred: accessing'!

{Image} fetchImage: imageName {char star} 
	"This method returns a stored image corresponding to the name 
	specified."

	self subclassResponsibility!

{void star} fetchResource: name {char star} 
	"This method returns an untyped resource corresponding to the name 
	specified."

	self subclassResponsibility!

{void} storeImage: name {char star} with: image {Image}
	"This method takes the provided image and stores it in native format under the name specified"

	self subclassResponsibility!

{void} storeResource: name {char star} with: resource {void star}
	"This method takes the provided resource and stores it in native format under the name specified"

	self subclassResponsibility! !

!FMResourceManager methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name! !

!FMResourceManager methodsFor: 'accessing'!

{Image} getImage: name {Character star}

	| im {Image} |
	im _ self fetchImage: name.
	im == NULL
		ifTrue: [Heaper BLAST: #ImageNotFound.
			^ NULL].
	^ im!

{void star} getResource: name {Character star}

	| res {void star} |
	res _ self fetchResource: name.
	res == NULL
		ifTrue: [Heaper BLAST: #ResourceNotFound.
			^ NULL].
	^ res! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMResourceManager class
	instanceVariableNames: ''!

(FMResourceManager getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMResourceManager */
friend SPTR(FMResourceManager) fMResourceManager ();
friend SPTR(FMResourceManager) fMResourceManager (MuTable * onTable);';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMResourceManager class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited

	 Resources  fluidSet: FMResourceManager fMResourceManager!

staticTimeNonInherited

	FMResourceManager defineFluid: #Resources with: Emulsion globalEmulsion with: [NULL].! !

!FMResourceManager class methodsFor: 'smalltalk: cleanup'!

cleanupGarbage
	"FMResourceManager cleanupGarbage"
	Resources _ nil! !

!FMResourceManager class methodsFor: 'global: extern: pseudo
constructors'!

{FMResourceManager} fMResourceManager
	^ self make!

{FMResourceManager} fMResourceManager: aTable {MuTable}
	^ self make: aTable! !

!FMResourceManager class methodsFor: 'smalltalk: pseudo
constructors'!

make

	[^ STResourceManager make] smalltalkOnly.
	 
	^ NULL!

make: onTable {MuTable unused}

	[^ STResourceManager make: onTable] smalltalkOnly.
	 
	^ NULL! !