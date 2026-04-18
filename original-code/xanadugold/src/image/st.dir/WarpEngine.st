'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:26 pm'!

Heaper subclass: #WarpEngine
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Warp Display'!
WarpEngine comment:
'The WarpEngine is the actual drawing engine for FM.  It is subclassed as appropriate for various window systems and platforms.  It supports a basic set of drawing operations for the WarpDrive and Warps to invoke.'!

(WarpEngine getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!WarpEngine methodsFor: 'accessing'!

{UInt32} hashForEqual
	^ (self basicCast: UInt32) >> 5!

{BooleanVar} isEqual: other {Heaper} 
	"Return true if the two objects are EQ"

	^other == self!

{BooleanVar} setupFrom: warp {Warp}
	self subclassResponsibility! !

!WarpEngine methodsFor: 'coloring'!

{void} inkColor: color {FMColor | NULL}
	"This routine changes the ink to a color."
	self subclassResponsibility!

{void} inkColorMap: colorMap {FMColorMap | NULL} 
	"This routine changes the ink to a colorMap."
	self subclassResponsibility!

{void} inkImage: image {Image | NULL}
	"Use image as my ink.  If the current ink is a mask,
	 then the new warp should use the combination (and) of the two.
	 This needs to make a new warp that understands replicating images."

	self subclassResponsibility! !

!WarpEngine methodsFor: 'display'!

{void} copyBits: encl {PointRegion} from: source {Image} at: pos {PointPos} 
	"Display a rectangle from sourceForm into the receiver."

	self subclassResponsibility!

{void} display: chars {MuWordArray} from: startIndex {IntegerVar} to: stopIndex {IntegerVar} attributes: atts {AttributeGroup} at: displayPos {PointPos} with: clipExtent {PointPos} 
	"This is the text display primitive"

	self subclassResponsibility!

{void}drawFrom: startPoint{PointPos} to: stopPoint{PointPos}
	"Draw a line from startPoint to stopPoint."
	self subclassResponsibility!

{void} fill: encl {PointRegion} 
	"Replace a rectangular area of the receiver with the pattern 
	described by aForm according to the rule anInteger."
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WarpEngine class
	instanceVariableNames: ''!

(WarpEngine getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!WarpEngine class methodsFor: 'pseudo constructors'!

make: aForm {Image} with: aBound {PointRegion} 
	[^BitBltWarp create: (aForm cast: FormImage) form with: aBound] smalltalkOnly.
	MACINTOSH ifdef: [^MacWarpEngine make: aForm with: aBound].
	XVIEW ifdef: [^XViewWarp make: aForm with: aBound].
	  
	^NULL! !