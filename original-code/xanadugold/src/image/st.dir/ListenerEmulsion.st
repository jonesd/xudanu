'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:48 pm'!

Emulsion subclass: #ListenerEmulsion
	instanceVariableNames: 'defaultFluidSpace {char star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-srvloop'!



!ListenerEmulsion methodsFor: 'accessing'!

{void star} fetchNewRawSpace: size {#size.U.t var}

	(CurrentChunk == NULL) ifTrue: [
		["cxx: return (defaultFluidSpace = (char *) fcalloc (size, sizeof(char)));"] translateOnly.
		[^defaultFluidSpace _ Array new: size] smalltalkOnly]
	ifFalse: [
		["cxx: return CurrentChunk->fluidSpace( (char *) fcalloc (size, sizeof(char)) );"] translateOnly.
		[^CurrentChunk fluidSpace: (Array new: size)] smalltalkOnly]!

{void star} fetchOldRawSpace

	(CurrentChunk == NULL) ifTrue: [
		^defaultFluidSpace. ]
	ifFalse: [
		^CurrentChunk fluidSpace.]! !

!ListenerEmulsion methodsFor: 'creation'!

create
	super create.
	defaultFluidSpace _ NULL.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ListenerEmulsion class
	instanceVariableNames: ''!



!ListenerEmulsion class methodsFor: 'smalltalk: passe'!

make
	
	self passe. "use 'Listener listenerEmulsion'"! !