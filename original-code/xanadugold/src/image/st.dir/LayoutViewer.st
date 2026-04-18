'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:11 pm'!

SingleContainingViewer subclass: #LayoutViewer
	instanceVariableNames: 'myLayoutVar {VariableModel of: AbstractLayout}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Simple'!
LayoutViewer comment:
'This viewer is used to restrict and translate the contained viewer.  This viewer is used in conjunction with the MultiViewer to allow placement of subviewers within a containing viewer that does not impose placement restrictions.  The contained viewer will be restricted to the layout region and the origin translated to 0@0'!

(LayoutViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class LayoutViewer */
friend
	SPTR(LayoutViewer)  layoutViewer (Viewer * withSub,
										   VariableModel OF1(AbstractLayout) * layoutModel);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LayoutViewer methodsFor: 'private: create'!

create: view {Viewer} with: layoutVar {VariableModel of: AbstractLayout}
	super create: view.
	myLayoutVar _ layoutVar.
	myLayoutVar addDependent: self! !

!LayoutViewer methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused}

	self changedEnclosure! !

!LayoutViewer methodsFor: 'accessing'!

{void} composeWith: layout {AbstractLayout} 
	"Since the default boundingRegion gets transformed, so must the 
	compositionRegion."

	self subView composeWith: 
		(RegionLayout make: ((self dsp inverseOfAll: (self restrictedRegion intersect: layout region))
				cast: PointRegion))!

{Dsp} dsp
	"Return the transformation between me and my subView."
	[Converter] USES.
	^ self offset convert: Dsp!

{PointPos} offset
	"Return the offset from my origin to my subview's origin"

	^(myLayoutVar getValue cast: AbstractLayout) region origin!

{PointRegion} restrictedRegion
	"The region that my subview is restricted to in my parents view. This 
	region is in my parent viewers coordinates"

	^(myLayoutVar getValue cast: AbstractLayout) region! !

!LayoutViewer methodsFor: 'displaying'!

{Warp} distort: warp {Warp} 
	"Distort the warp appropriately for projecting subViews."

	^warp intersect: self restrictedRegion translateBy: self dsp! !

!LayoutViewer methodsFor: 'protected: layout'!

{PointRegion} computeEnclosure

	^((self dsp inverseOfAll: self restrictedRegion)
		intersect: self subView enclosure)
		cast: PointRegion! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LayoutViewer class
	instanceVariableNames: ''!

(LayoutViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class LayoutViewer */
friend
	SPTR(LayoutViewer)  layoutViewer (Viewer * withSub,
										   VariableModel OF1(AbstractLayout) * layoutModel);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LayoutViewer class methodsFor: 'pseudo constructors'!

make: withSub {Viewer} with: layoutModel {VariableModel of: AbstractLayout}

	^ self create: withSub with: layoutModel! !