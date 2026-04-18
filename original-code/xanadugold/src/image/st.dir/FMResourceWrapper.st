'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:43 pm'!

Heaper subclass: #FMResourceWrapper
	instanceVariableNames: 'myWrapped {void star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-resourc'!
FMResourceWrapper comment:
'This class is a special wrapper class which is used by the resource manager to wrap non-X++ classes so that they may be maintained by X++ classes if necessary.'!

(FMResourceWrapper getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMResourceWrapper */
friend SPTR(FMResourceWrapper) fMResourceWrapper (void * onThing);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMResourceWrapper methodsFor: 'accessing'!

{void star} resource
	"This method returns a pointer to the wrapped item (resource)"

	^ myWrapped! !

!FMResourceWrapper methodsFor: 'private: creation'!

create: onResource {void star}

	super create.
	myWrapped _ onResource! !

!FMResourceWrapper methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMResourceWrapper class
	instanceVariableNames: ''!

(FMResourceWrapper getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMResourceWrapper */
friend SPTR(FMResourceWrapper) fMResourceWrapper (void * onThing);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMResourceWrapper class methodsFor: 'pseudo constructors'!

make: onThing {void star}

	^ self create: onThing! !