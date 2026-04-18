'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:41 pm'!

FMResourceManager subclass: #XVResourceManager
	instanceVariableNames: 'myResources {MuTable}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-XXView'!
XVResourceManager comment:
'This class is a xview only class which implements a resource manager which is used by FM classes. whatever the fuck that means'!

(XVResourceManager getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XVResourceManager methodsFor: 'creation'!

create
	super create.
	myResources _ MuTable make: HeaperSpace make!

create: onTable {MuTable}
	super create.
	myResources _ onTable! !

!XVResourceManager methodsFor: 'accessing'!

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
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XVResourceManager class
	instanceVariableNames: ''!

(XVResourceManager getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XVResourceManager class methodsFor: 'pseudo constructors'!

make
	^ self create!

make: onTable {MuTable} 
	^self create: onTable! !