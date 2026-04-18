'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:11 pm'!

LeafViewer subclass: #FormViewer
	instanceVariableNames: '
		sourceInternal {Image}
		isForm {BooleanVar}
		changedRegion {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Simple'!
FormViewer comment:
'Instances of this class display an Image.  Where the source does not exist is shown as white.
'!

(FormViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class FormViewer */
friend SPTR(FormViewer) formViewer (Image * onForm);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FormViewer methodsFor: 'accessing'!

{XnRegion} regionAt: index {IntegerVar unused} 
	"Return the displayRegion occupied by the model position."

	self unimplemented.
	^NULL!

{Position} selectionFor: aPoint {PointPos unused}
	"Find the model position corresponding to the display
position (a XuPoint)."

	self unimplemented.
	^NULL!

{void} setSource: aDisplayObject {Image} 
	| oldReg {PointRegion} |
	sourceInternal removeDependent: self.
	oldReg _ sourceInternal enclosure.
	sourceInternal _ aDisplayObject.
	sourceInternal addDependent: self.
	changedRegion _ (sourceInternal enclosure unionWith: oldReg) cast: PointRegion.
	self changedImage!

{Image} source
	^sourceInternal! !

!FormViewer methodsFor: 'displaying'!

{void} displayOn: aWarp {Warp} 
	"This displayOn: draws the contained image (using it's displayOn: 
	method) and then clears the rest of the warp (to white)."

	sourceInternal displayOn: aWarp.
	aWarp white fill: ((self enclosure complement intersect: changedRegion) cast: PointRegion).
	self validate! !

!FormViewer methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel unused} 
        (ur isKindOf: RegionUR) ifTrue:
                [changedRegion _ changedRegion 
                		simpleUnion: (ur basicCast: RegionUR) region].
        self changedImage! !

!FormViewer methodsFor: 'protected: accessing'!

{PointRegion} computeEnclosure
	^sourceInternal enclosure!

{void} validate
	super validate.
	changedRegion _ PointRegion make! !

!FormViewer methodsFor: 'smalltalk: smalltalk only'!

inspectPieces
	"Return pieces to be used in a tree browser."

	^OrderedCollection with: sourceInternal! !

!FormViewer methodsFor: 'protected: creation'!

create: s {Image} 
	super create.
	sourceInternal _ s.
	sourceInternal addDependent: self.
	changedRegion _ PointRegion allPoints!

{void} destruct
	sourceInternal removeDependent: self.
	super destruct! !

!FormViewer methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FormViewer class
	instanceVariableNames: ''!

(FormViewer getOrMakeCxxClassDescription)
	friends:
'/* friends for class FormViewer */
friend SPTR(FormViewer) formViewer (Image * onForm);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FormViewer class methodsFor: 'pseudoconstructors'!

make: onForm {Image}
	^ self create: onForm! !