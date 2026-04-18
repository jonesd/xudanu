'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:19 pm'!

Emulsion subclass: #GlobalEmulsion
	instanceVariableNames: 'myFluidsSpace {Array of: Object}'
	classVariableNames: 'TheGlobalEmulsion {Emulsion} '
	poolDictionaries: ''
	category: 'Xanadu-Xpp-fluid'!

(GlobalEmulsion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!GlobalEmulsion methodsFor: 'accessing'!

{void star} fetchNewRawSpace: size {#size.U.t var}

	["cxx: return (myFluidsSpace = (char *) calloc (size, sizeof(char)));"] translateOnly.
	[^myFluidsSpace _ Array new: size] smalltalkOnly!

{void star} fetchOldRawSpace

	^myFluidsSpace! !

!GlobalEmulsion methodsFor: 'create'!

create
	super create.
	myFluidsSpace _ NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GlobalEmulsion class
	instanceVariableNames: ''!

(GlobalEmulsion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!GlobalEmulsion class methodsFor: 'make'!

make
	(TheGlobalEmulsion == nil or: [TheGlobalEmulsion == NULL]) ifTrue:
		[TheGlobalEmulsion _ self new create].
	^ TheGlobalEmulsion! !

!GlobalEmulsion class methodsFor: 'global: make'!

globalEmulsion
	^ self make! !

!GlobalEmulsion class methodsFor: 'cleanup'!

cleanupGarbage
	TheGlobalEmulsion _ NULL!

exitTimeNonInherited

	TheGlobalEmulsion := NULL.!

linkTimeNonInherited

	TheGlobalEmulsion := NULL.! !