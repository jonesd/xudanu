'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:05 pm'!

SingleContainingViewer subclass: #FMSelectionViewer
	instanceVariableNames: 'myRequestModel {BooleanModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Selection'!

(FMSelectionViewer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMSelectionViewer methodsFor: 'protected: create'!

create: onSubviewer {Viewer}

	super create: (FMCacheViewer make: onSubviewer).
	myRequestModel _ (self subView cast: FMCacheViewer) redisplayRequestor!

{void} destruct
	"Since this viewer created its subview (FMCacheViewer) and a 
	booleanmodel shared with the cache view, this unthreads and 
	destroys all of that."

	| cv {SingleContainingViewer} |
	cv _ self subView cast: SingleContainingViewer.
	self setSubView: cv subView.
	cv destroy.
	myRequestModel destroy.
	super destruct! !

!FMSelectionViewer methodsFor: 'protected: change'!

{void} changedImage

	myRequestModel setValue: true.
	super changedImage! !

!FMSelectionViewer methodsFor: 'protected: accessing'!

{Highlight} highlight
	"Return the highlight used to indicate that an item is selected"
	
	self subclassResponsibility!

{Heaper} selection
	"Return the selection for this viewer"
	
	self subclassResponsibility! !

!FMSelectionViewer methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	super printOn: oo.
	oo << '
	selection ' << self selection << '
	highlighting with: ' << self highlight! !