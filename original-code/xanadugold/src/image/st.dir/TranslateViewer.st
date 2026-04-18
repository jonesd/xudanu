'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:13 pm'!

SingleContainingViewer subclass: #TranslateViewer
	instanceVariableNames: 'myOffsetVar {VariableModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Simple'!

(TranslateViewer getOrMakeCxxClassDescription)
	friends:
'/*
friends for class TranslateViewer */
friend SPTR(TranslateViewer)  translateViewer (Viewer *
withSub, VariableModel * dspModel);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TranslateViewer methodsFor: 'accessing'!

{void} composeWith: layout {AbstractLayout}
	"Since the default boundingRegion gets transformed, so
must the compositionRegion."

	self subView composeWith: (layout translatedBy:
(myOffsetVar getValue cast: PointPos))!

{Dsp} dsp
	"Return the transformation between me and my subView."

	^myOffsetVar getValue convert: Dsp! !

!TranslateViewer methodsFor: 'displaying'!

{Warp} distort: warp {Warp} 
	"Distort the warp appropriately for projecting subViews."

	^warp transformedBy: self dsp! !

!TranslateViewer methodsFor: 'protected: layout'!

{PointRegion} computeEnclosure
	^(self dsp inverseOfAll: self subView enclosure)
cast: PointRegion! !

!TranslateViewer methodsFor: 'private: create'!

create: view {Viewer} with: var {VariableModel}
	super create: view.
	myOffsetVar _ var.
	myOffsetVar addDependent: self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TranslateViewer class
	instanceVariableNames: ''!

(TranslateViewer getOrMakeCxxClassDescription)
	friends:
'/*
friends for class TranslateViewer */
friend SPTR(TranslateViewer)  translateViewer (Viewer *
withSub, VariableModel * dspModel);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TranslateViewer class methodsFor: 'pseudo constructors'!

make: withSub {Viewer} with: dspModel {VariableModel}

	^ self create: withSub with: dspModel! !