'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:57 pm'!

FMBuilder subclass: #FullReferenceBuilder
	instanceVariableNames: ''
	classVariableNames: 'FullReferencePortions {ListModel of: Portion} '
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
FullReferenceBuilder comment:
'Builds a view onto a reference.
*Eventually, will be a director that has a model
describing the format of the view'!

(FullReferenceBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FullReferenceBuilder */
friend SPTR(FullReferenceBuilder)  fullReferenceBuilder
();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FullReferenceBuilder methodsFor: 'private: creation'!

create! !

!FullReferenceBuilder methodsFor: 'build'!

{FMBuilding} build: what {Heaper unused}

	self unimplemented.
	^ NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FullReferenceBuilder class
	instanceVariableNames: ''!

(FullReferenceBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class FullReferenceBuilder */
friend SPTR(FullReferenceBuilder)  fullReferenceBuilder
();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FullReferenceBuilder class methodsFor: 'make'!

make
	^ self create! !