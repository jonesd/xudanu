'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:13 pm'!

FMResourceManager subclass: #XViewResourceManager
	instanceVariableNames: 'myResources {MuTable}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-xview'!

(XViewResourceManager getOrMakeCxxClassDescription)
	friends:
'/* friends for class XViewResourceManager */
friend SPTR(FMResourceManager)  fMResourceManager ();
friend SPTR(FMResourceManager)  fMResourceManager (APTR(MuTable) onTable);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewResourceManager methodsFor: 'accessing'!

{Image} fetchImage: imageName {char star} 
	"This method returns a stored image corresponding to the name 
	specified."

	^ (myResources fetch: (Sequence string: imageName)) cast: Image!

{void star} fetchResource: name {char star} 
	"This method returns an untyped resource corresponding to the name 
	specified."

	^ ((myResources fetch: (Sequence string: name)) cast: FMResourceWrapper) resource!

{void} storeImage: name {char star} with: image {Image}
	"This method takes the provided image and stores it in native format under the name specified"

	myResources at: (Sequence string: name) store: image!

{void} storeResource: name {char star} with: resource {void star}
	"This method takes the provided resource and stores it in native format under the name specified"

	myResources at: (Sequence string: name) store: (FMResourceWrapper make: resource)! !

!XViewResourceManager methodsFor: 'private: creation'!

create
	super create.
	myResources _ MuTable make: HeaperSpace make!

create: onTable {MuTable}
	super create.
	myResources _ onTable! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XViewResourceManager class
	instanceVariableNames: ''!

(XViewResourceManager getOrMakeCxxClassDescription)
	friends:
'/* friends for class XViewResourceManager */
friend SPTR(FMResourceManager)  fMResourceManager ();
friend SPTR(FMResourceManager)  fMResourceManager (APTR(MuTable) onTable);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewResourceManager class methodsFor: 'global: pseudo constructors'!

{FMResourceManager}fMResourceManager
	^ self create!

{FMResourceManager}fMResourceManager: onTable {MuTable} 
	^self create: onTable! !