'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:13 pm'!

LeafViewer subclass: #VariableImageViewer
	instanceVariableNames: 'mySource {VariableModel of: Image}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Simple'!

(VariableImageViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class VariableImageViewer */
friend SPTR(VariableImageViewer)  variableImageViewer (VariableModel OF1(Image) * onImageM);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariableImageViewer methodsFor: 'protected: change'!

{PointRegion} computeEnclosure
	^ self getImage enclosure! !

!VariableImageViewer methodsFor: 'accessing'!

{Image} getImage

	^ mySource getValue cast: Image!

{XnRegion} regionAt: index {IntegerVar unused}
	"Return the displayRegion occupied by the model position."
	
	self unimplemented.
	^ NULL!

{Position} selectionFor: aPoint {PointPos unused}
	"Find the model position corresponding to the display position (a XuPoint)."

	self unimplemented.
	^ NULL! !

!VariableImageViewer methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: sender {XnModel unused} 
	self changedImage! !

!VariableImageViewer methodsFor: 'private: creation'!

create: onImageModel {VariableModel of: Image}

	super create.
	mySource _ onImageModel.
	mySource addDependent: self!

{void} destruct
	mySource removeDependent: self.
	mySource _ NULL.
	super destruct! !

!VariableImageViewer methodsFor: 'displaying'!

{void} displayOn: aMedium {Warp} 
	"This is the fundamental display message 
	for Viewers, that subclasses must implement."

	self getImage displayOn: aMedium.
	self validate! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VariableImageViewer class
	instanceVariableNames: ''!

(VariableImageViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class VariableImageViewer */
friend SPTR(VariableImageViewer)  variableImageViewer (VariableModel OF1(Image) * onImageM);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariableImageViewer class methodsFor: 'make'!

make: onImageM {VariableModel of: Image}

	^ self create: onImageM! !