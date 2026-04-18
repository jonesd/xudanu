'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:30 pm'!

Emulsion subclass: #DiskManagerEmulsion
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-backend'!



!DiskManagerEmulsion methodsFor: 'accessing'!

{void star} fetchNewRawSpace: size {#size.U.t var}

	'return CurrentPacker.fluidGet()->fluidSpace( (char *) fcalloc (size, sizeof(char)) );' translateOnly.
	[^CurrentPacker fluidGet fluidSpace: (Array new: size)] smalltalkOnly!

{void star} fetchOldRawSpace

	^CurrentPacker fluidGet fluidSpace! !

!DiskManagerEmulsion methodsFor: 'creation'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DiskManagerEmulsion class
	instanceVariableNames: ''!



!DiskManagerEmulsion class methodsFor: 'creation'!

make
	^ DiskManagerEmulsion new create! !