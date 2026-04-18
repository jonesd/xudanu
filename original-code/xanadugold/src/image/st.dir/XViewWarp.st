'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:40 pm'!

WarpEngine subclass: #XViewWarp
	instanceVariableNames: '
		leftInternal {Int4}
		topInternal {Int4}
		widthInternal {Int4}
		heightInternal {Int4}
		origin {PointPos}
		xvCanvasInternal {Xv.U.opaque var}
		xwinInternal {Window var}
		dpyInternal {Display star}
		warpgc {GC var}
		myLastWarp {Warp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-XXView'!

(XViewWarp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewWarp methodsFor: 'create/delete'!

create
	super create.
	myLastWarp _ NULL!

create: xvCanvas {Xv.U.opaque var} 
	"create a XViewWarp to display on the canvas xvCanvas"

	super create.
	myLastWarp _ NULL.
	xvCanvasInternal _ xvCanvas.
	leftInternal _ Int0.
	topInternal _ Int0.
	widthInternal _ ((XView
				xv.U.get: xvCanvas
				with: #XV.U.WIDTH 
				with: NULL) asInteger).
	heightInternal _ 1000"((XView
				xv.U.get: xvCanvas
				with: #XV.U.HEIGHT
				with: NULL) asInteger)".
	origin _ XuPoint create: Int0 with: Int0.
	dpyInternal _ NULL.
	xwinInternal _ NULL.
	"XView DefaultGC: dpyInternal with: xwinInternal"
	warpgc _ NULL!

create: xvCanvas {Xv.U.opaque var} with: encl {PointRegion} with: home {PointPos} 
	"create a XViewWarp to display on the canvas xvCanvas"

	super create.
	myLastWarp _ NULL.
	xvCanvasInternal _ xvCanvas.
	leftInternal _ encl left DOTasLong.
	topInternal _ encl top DOTasLong.
	widthInternal _  encl width DOTasLong.
	heightInternal _ 1000"encl height DOTasLong".
	origin _ home. 
	"widthInternal _ xvCanvas xv.U.get: #CANVAS.U.WIDTH with: NULL. 
	heightInternal _ xvCanvas xv.U.get: #CANVAS.U.HEIGHT with: NULL. "
	"origin _ XuPoint create:Int0 with:Int0"
	dpyInternal _ NULL.
	xwinInternal _ NULL.
	"XView DefaultGC: dpyInternal with: xwinInternal"
	warpgc _ NULL!

create: xvCanvas {Xv.U.opaque var} with: home {PointPos} with: leftE {Int32} with: topE {Int32} with: widthE {Int32} with: heightE {Int32} 
	"create a XViewWarp to display on the canvas xvCanvas"

	super create.
	myLastWarp _ NULL.
	xvCanvasInternal _ xvCanvas.
	leftInternal _ leftE.
	topInternal _ topE.
	widthInternal _ widthE.
	heightInternal _1000 "heightE".
	origin _ home.
	dpyInternal _ NULL.
	xwinInternal _ NULL.
	"XView DefaultGC: dpyInternal with: xwinInternal"
	warpgc _ NULL!

{void} setInternals 
	| xvCanvasTmp {Xv.U.opaque var} |
	 
	 
	 
	xvCanvasTmp _ xvCanvasInternal.
	 
	widthInternal _ ((XView
				xv.U.get: xvCanvasTmp
				with: #XV.U.WIDTH
				with: NULL) asInteger).
	heightInternal _ ((XView
				xv.U.get: xvCanvasTmp
				with: #XV.U.HEIGHT
				with: NULL) asInteger).
	
	origin _ PointPos create: Int0 with: Int0.! !

!XViewWarp methodsFor: 'accessing'!

{PointRegion} enclosure
	"Return the simpleRegion for the area that the receiver occupies in local 
	coordinates. For reference: 'self fill: self enclosure' will completely paint the 
	receiver in its current ink."

	^PointRegion make: (PointPos make: leftInternal - origin x DOTasInt with: topInternal - origin y  DOTasInt)
		with: (PointPos make: leftInternal - origin x  DOTasInt+ widthInternal with: topInternal - origin y  DOTasInt+ heightInternal)!

{UInt32} hashForEqual
	^self basicCast: UInt32!

{IntegerVar} height
^heightInternal!

{BooleanVar}isEqual: other{Heaper}
	"Return true if the two objects are equal.  (Same destination area, same transformation)."
	^ self hashForEqual = other hashForEqual!

{void} setxstuff: dpy{Display star} with: xwin {Window var}
 dpyInternal _dpy.
 xwinInternal _ XView xv.U.get: xwin with: XV.U.XID.
 warpgc _ XView DefaultGC: dpyInternal with: (XView DefaultScreen: dpyInternal)!

{IntegerVar} width
^widthInternal! !

!XViewWarp methodsFor: 'coloring'!

{void} inkColor: color {FMColor} 
	"Create a newz warp that uses color as its ink for painting. All draw/paint/etc. 
	operations use the current ink to change the actual display. Painting with a 
	color simply overrides the existing colors on the display display in the areas 
	painted."
 "set internal state"!

{void} inkColorMap: colorMap {FMColorMap} 
	"Create a newz warp that uses colorMap as its ink for painting. All draw/paint/etc. 
	operations use the current ink to change the actual display. Painting with a 
	colorMap transforms the color in the area of the paint operations according to colorMap."
	 "set internal state"!

{void} inkImage: image {Image} 
	"Create a newz warp that uses image as its ink for painting. All draw/paint/etc. 
	operations use the current ink to change the actual display.  Painting with an
	image uses the image essentially as a halftone, replicating all over the area to be displayed.
	This can be combined with a colorMap."
	 "set internal state"! !

!XViewWarp methodsFor: 'private: private'!

{PointRegion}destinationEnclosure
"	^(PointRegion create: leftInternal with: topInternal) extent: (XuPoint create: widthInternal with: heightInternal)"
self unimplemented.
	^NULL! !

!XViewWarp methodsFor: 'transforming'!

{Warp}intersect: encl {XnRegion} 
	"Return a newz warp that occupies the region of the current warp intersent encl."
 
	"^XViewWarp
		create: xvCanvasInternal
		with: (self destinationEnclosure intersect: (encl translatedBy: origin))
		with: origin"
		
		self unimplemented.
		^NULL!

{Warp} intersect: encl {XnRegion} translateBy: aPoint {PointPos} 
	"This is equivalent to '(self intersect: encl) translateBy: aPoint'. It's simply so 
	common in scroll and multi-views that we have a special operation for it. This 
	operation will go away eventually."

	"	^XViewWarp
		create: xvCanvasInternal
		with: (self destinationEnclosure intersect: (encl translateBy: origin))
		with: (aPoint plus: origin)"
		self unimplemented.
		^NULL!

{PointPos}transformPoint: pos {PointPos}
	"This will be sent by other warps (ScaledWarps in particular), but doesn't need to be implemented yet."

	^pos plus: origin! !

!XViewWarp methodsFor: 'displaying'!

{void} copyBits: encl {PointRegion} from: source {Image} at: pos {PointPos} 
	"copy all the bits of source that fall within encl to the recevier, translated so 
	that the origin of the coordinate system of encl would be at pos."

	self unimplemented!

{void} display: chars {MuWordArray} from: startIndex {IntegerVar} to: stopIndex {IntegerVar} attributes: atts {AttributeGroup} at: displayPos {PointPos} with: clipExtent {PointPos}
	"This is the basic string display primitive. display the run of characters from 
	startIndex to stopIndex from chars. The entire run is displayed with the same 
	attributes, described in atts. Display the run at displayPos in the receiver's 
	coordinate system."

	| sunfont {Xv.U.opaque var} cstring {char star} op{int} nchars{int} stringTruncated {char star} fontAscent {int var}| 
	[FMFont] USES.
	sunfont_ (atts  font  font) basicCast: #Xv.U.opaque var.
	"fontAscent _ atts font ascent ."
	op_ #PIX.U.SRC.
	nchars _ stopIndex DOTasInt  - startIndex DOTasInt.
	stringTruncated _ Character vector create: nchars + 1.
	cstring _ chars gutsOf basicCast: Character star +startIndex DOTasInt.
	String strncpy: stringTruncated with: cstring+ startIndex DOTasInt with: nchars.
 
	stringTruncated at: nchars put: NULL.
	"XView pw.U.text: xvCanvasInternal with: (displayPos x DOTasLong) with: (displayPos y DOTasLong) with: op with: sunfont with: stringTruncated."
' 
fontAscent = atts->font()->ascent().asLong();
XDrawImageString(dpyInternal,xwinInternal,warpgc,displayPos->x().asLong(),
					displayPos->y().asLong() +fontAscent,stringTruncated, strlen(stringTruncated));' translateOnly!

{void}drawFrom: startPoint{PointPos} to: stopPoint{PointPos}
	"Draw a line from the startPoint to the stopPoint.  We don't currently use this, so it can be safely ignored for the moment."
	
	self unimplemented!

{void} fill: encl {PointRegion}
	"Fill region with the current ink."

	'cerr<< "this is a test in XViewWarp fill:region" ;' translateOnly.
"	 
	| l {IntegerVar} t {IntegerVar} opWidth{IntegerVar} opHeight{IntegerVar} destX{IntegerVar} destY{IntegerVar} |
	 
	encl simpleRegions forEach: [ :region {PointRegion} |
		((opWidth _ region right - (l _ region left)) > IntegerVar0
				and: [(opHeight _ region bottom - (t _ region top)) > IntegerVar0]) ifTrue:
			[destX _ l + origin x.
			destY _ t + origin y.
			"
			
	'			 	 
	IntegerVar l;
	IntegerVar  t;
	IntegerVar opWidth;
	IntegerVar opHeight;
	IntegerVar destX;
	IntegerVar destY;
	
	
		SPTR(Stepper) while_Stepper = &*(encl->simpleRegions());
		while ( while_Stepper->hasValue() ) {
			PointRegion * region = CAST(PointRegion,while_Stepper->fetch());
			{	BooleanVar crutch_Flag;
				/* (opWidth = region->right() - (l = region->left())) > IntegerVar0 && (opHeight = region->bottom() - (t = region->top())) > IntegerVar0 */
				
				crutch_Flag = (opWidth = region->right() - (l = region->left())) > IntegerVar0;
				if(crutch_Flag) {
					crutch_Flag = (opHeight = region->bottom() - (t = region->top())) > IntegerVar0;
				}
				if (crutch_Flag) {
					destX = l + origin->x();
					destY = t + origin->y();
					  XClearArea(dpyInternal,xwinInternal,destX.asInt(),destY.asInt(),opWidth.asInt(),opHeight.asInt(),FALSE  );
	 
				}
			}
			while_Stepper->step();
		}
		while_Stepper->destroy();
' translateOnly.! !

!XViewWarp methodsFor: 'protected: protected accessing'!

{BooleanVar} setupFrom: warp {Warp}
	"whether last setup was from warp; this is private between the two classes"
	"this is subclassResponsibility only because BitBltWarp needs its instance
	variables in the right place for primitives"
	myLastWarp == warp ifTrue: [^true].
	myLastWarp _ warp.
	^false! !

!XViewWarp methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << 'XViewWarp  (  leftInternal = ' << leftInternal <<' topInternal = ' << topInternal << ' widthInternal = ' << widthInternal << ' heightInternal = ' << heightInternal  << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XViewWarp class
	instanceVariableNames: ''!

(XViewWarp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewWarp class methodsFor: 'pseudo constructors'!

make: aForm {Image} with: aBound {PointRegion}
^XViewWarp create.! !