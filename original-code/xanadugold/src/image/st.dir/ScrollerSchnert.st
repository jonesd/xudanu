'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:01 pm'!

XnModel subclass: #ScrollerSchnert
	instanceVariableNames: '
		myViewer {Viewer}
		myExtent {VariableModel of: PointPos}
		myOffset {VariableModel of: PointPos}
		myVisible {VariableModel of: XnRegion}
		myDesired {VariableModel of: XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
ScrollerSchnert comment:
'This schnert manages the scrolling of a window referring to data that is organized by some coordinate space.

		myViewer {Viewer}
			The FM Viewer displaying the information
		myExtent {VariableModel of: XuPoint}
			The size of the window
			Typically set from information supplied by the window system
		myOffset {VariableModel of: XuPoint}
			The offset from the origin at which the window is shown
			Typically set by the scroll bar
		myVisible {VariableModel of: XuRegion}
			The region of the model that is actually visible in the window
			Set by the ScrollerSchnert after a change in offset or extent
		myDesired {VariableModel of: XuRegion}
			A change in this causes the scroller to try and make this area
			visible in the window by changing the offset, causing the visible
			region to be updated as well'!

(ScrollerSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ScrollerSchnert */
friend SPTR(ScrollerSchnert) scrollerSchnert (Viewer * view);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ScrollerSchnert methodsFor: 'accessing'!

{VariableModel of: XnRegion} desired
	^myDesired!

{VariableModel of: PointPos} extent
	^myExtent!

{VariableModel of: PointPos} offset
	^myOffset!

{Viewer} viewer
	^myViewer!

{VariableModel of: XnRegion} visible
	^myVisible! !

!ScrollerSchnert methodsFor: 'updating'!

{void} update: change {UpdateRecord unused} from: model
{XnModel} 
	"update my models according to what has changed"

	model == (myDesired basicCast: XnModel)
		ifTrue: [self updateOffset]
		ifFalse: [(model == (myOffset basicCast: XnModel) 
					or: [model == (myExtent basicCast: XnModel)])
				ifTrue: [self updateVisible]]! !

!ScrollerSchnert methodsFor: 'private: updating'!

{void} updateOffset
	myOffset setValue: (myViewer offsetFor: (myDesired getValue cast: XnRegion))!

{void} updateVisible
	myVisible setValue: (myViewer
		selectionIn: (PointRegion
			regionExtent: (myOffset getValue cast: PointPos)
			with: (myExtent getValue cast: PointPos)))! !

!ScrollerSchnert methodsFor: 'private: creation'!

create: view {Viewer}
	super create.
	myViewer _ view.
	myExtent _ VariableModel make: PointPos make.
	myOffset _ VariableModel make: PointPos make.
	myVisible _ VariableModel make.
	myDesired _ VariableModel make.
	
	myExtent addDependent: self.
	myOffset addDependent: self.
	myDesired addDependent: self!

{void} destruct

	myExtent removeDependent: self.
	myOffset removeDependent: self.
	myDesired removeDependent: self.
	myExtent destroy.
	myVisible destroy.
	myOffset destroy.
	myDesired destroy.
	myViewer _ NULL.
	myExtent _ NULL.
	myOffset _ NULL.
	myVisible _ NULL.
	myDesired _ NULL.
	super destruct! !

!ScrollerSchnert methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '('
	      << 'myViewer'  << myViewer 
		<< 'myExtent' << myExtent  
		<< 'myOffset'  << myOffset
		<< 'myVisible'  << myVisible
		<< 'myDesired' << myDesired << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScrollerSchnert class
	instanceVariableNames: ''!

(ScrollerSchnert getOrMakeCxxClassDescription)
	friends:
'/* friends for class ScrollerSchnert */
friend SPTR(ScrollerSchnert) scrollerSchnert (Viewer * view);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ScrollerSchnert class methodsFor: 'make'!

make: view {Viewer.X}
	^self create: view! !