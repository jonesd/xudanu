'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:24 pm'!

WarpEngine subclass: #TestWarpEngine
	instanceVariableNames: '
		myLastWarp {Warp}
		myBounds {PointRegion}'
	classVariableNames: 'MyRecordingStream {ostream smalltalk reference} '
	poolDictionaries: ''
	category: 'FM-Warp Display'!

(TestWarpEngine getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TestWarpEngine methodsFor: 'create'!

create: oo {ostream reference}

	super create.
	myLastWarp _ NULL!

create: form {Image unused} with: bounds {PointRegion}

	super create.
	myLastWarp _ NULL.
	myBounds _ bounds! !

!TestWarpEngine methodsFor: 'accessing'!

{BooleanVar} setupFrom: warp {Warp} 
	myLastWarp == NULL ifTrue: [^false].
	^warp isEqual: myLastWarp! !

!TestWarpEngine methodsFor: 'coloring'!

{void} inkColor: color {FMColor | NULL}
	"This routine changes the ink to a color."
	MyRecordingStream << 'changing color to ' << color << '
'!

{void} inkColorMap: colorMap {FMColorMap | NULL} 
	"This routine changes the ink to a colorMap."
	MyRecordingStream << 'changing colorMap to ' << colorMap << '
'!

{void} inkImage: image {Image | NULL}
	"Use image as my ink.  If the current ink is a mask,
	 then the new warp should use the combination (and) of the two.
	 This needs to make a new warp that understands replicating images."

	MyRecordingStream << 'changing ink image to ' << image << '
'! !

!TestWarpEngine methodsFor: 'display'!

{void} copyBits: encl {PointRegion} from: source {Image} at: pos {PointPos} 
	"Display a rectangle from sourceForm into the receiver."

	MyRecordingStream << 'copyBits(' << encl << ', ' << source << ', ' << pos << ')'!

{void} display: chars {MuWordArray} from: startIndex {IntegerVar} to: stopIndex {IntegerVar} attributes: atts {AttributeGroup} at: displayPos {PointPos} with: clipExtent {PointPos} 
	"This is the text display primitive"

	MyRecordingStream << 'display(' << chars << ', ' << startIndex << ', ' << stopIndex
			 << ', ' << atts << ', ' << displayPos << ', ' << clipExtent << ')'!

{void} drawFrom: startPoint {PointPos} to: stopPoint {PointPos} 
	"Draw a line from startPoint to stopPoint."

	MyRecordingStream << 'drawFrom(' << startPoint << ', ' << stopPoint << ')'!

{void} fill: encl {PointRegion} 
	"Replace a rectangular area of the receiver with the pattern 
	described by aForm according to the rule anInteger."

	MyRecordingStream << 'fill(' << encl << ')'! !

!TestWarpEngine methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << ' with bounds of ' << myBounds << '
	and last warp of ' << myLastWarp! !

!TestWarpEngine methodsFor: 'testing special'!

{void} clipRect: aRect {PointRegion} 
	MyRecordingStream << 'engine clipRect (' << aRect << ')
'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TestWarpEngine class
	instanceVariableNames: ''!

(TestWarpEngine getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TestWarpEngine class methodsFor: 'testing initialization'!

{void} setRecordingStream: oo {ostream reference}

	MyRecordingStream _ oo! !

!TestWarpEngine class methodsFor: 'pseudo constructors'!

make: aForm {Image} with: aBound {PointRegion} 
	^ TestWarpEngine create: aForm with: aBound! !