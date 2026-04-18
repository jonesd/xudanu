'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:12 pm'!

SingleContainingViewer subclass: #SuperLayoutViewer
	instanceVariableNames: 'myLayout {AbstractLayout}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Simple'!

(SuperLayoutViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class SuperLayoutViewer */
friend SPTR(SuperLayoutViewer)  superLayoutViewer (Viewer * onSV, AbstractLayout * layout);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SuperLayoutViewer methodsFor: 'protected: layout'!

{PointRegion} computeEnclosure
	myLayout == NULL ifTrue: [^self subView enclosure].
	^myLayout rectangle! !

!SuperLayoutViewer methodsFor: 'private: creation'!

create: onSubview {Viewer} with: layout {AbstractLayout default: NULL}
	super create: onSubview.
	myLayout _ layout! !

!SuperLayoutViewer methodsFor: 'accessing'!

{void} composeWith: layout {AbstractLayout} 

	myLayout _ layout.
	self subView composeWith: layout.
	self changedEnclosure! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SuperLayoutViewer class
	instanceVariableNames: ''!

(SuperLayoutViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class SuperLayoutViewer */
friend SPTR(SuperLayoutViewer)  superLayoutViewer (Viewer * onSV, AbstractLayout * layout);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SuperLayoutViewer class methodsFor: 'make'!

make: onSV {Viewer} with: layout {AbstractLayout default: NULL}

	^ self create: onSV with: layout! !

!SuperLayoutViewer class methodsFor: 'smalltalk: make'!

make: onSV {Viewer}

	^ self create: onSV with: NULL! !