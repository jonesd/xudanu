'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:27 pm'!

Tester subclass: #WarpTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Warp Display'!

(WarpTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!WarpTester methodsFor: 'tests'!

{void} borderTests: oo {ostream reference}

	| dWarp {Warp} bounds {PointPos} nuWarp {Warp} bWarp {Warp} |
	bounds _ PointPos make: 100 with: 100.
	oo << 'creating test warp
'.
	dWarp _ TestWarp make: (Image image.XuPoint: bounds) with: (PointRegion regionExtent: bounds).
	oo << 'test warp is: ' << dWarp << '
'.
	nuWarp _ dWarp intersect: (PointRegion make: 10 with: 10 with: 90 with: 90) translateBy: (PointTranslateDsp make: (PointPos make: 10 with: 10)).
	
	oo << 'border on black warp width 5 on main warp:
'.
	bWarp _ dWarp black borderWidth: dWarp enclosure with: 5.
	oo << bWarp << '

border on restricted/translated warp (' << nuWarp << '), width 5
'.
	bWarp _ nuWarp black borderWidth: nuWarp enclosure with: 5.
	oo << bWarp << '
'!

{void} colorWarpTests: oo {ostream reference}

	| dWarp {Warp} bounds {PointPos} nuWarp {Warp} |
	bounds _ PointPos make: 100 with: 100.
	oo << 'creating test warp
'.
	dWarp _ TestWarp make: (Image image.XuPoint: bounds) with: (PointRegion regionExtent: bounds).
	oo << 'test warp is: ' << dWarp << '
'.
	nuWarp _ dWarp black.
	oo << 'black warp is: ' << nuWarp << '

white warp is : ' << dWarp white << '

try ink.Color (white) : '.
	nuWarp _ dWarp inkColor: FMColor fmWhiteColor.
	oo << nuWarp << '

try ink.ColorMap : '.
	nuWarp _ dWarp inkColorMap: FMColorMap selectColorMap.
	oo << nuWarp << '

try ink.Image '.
	nuWarp _ dWarp inkImage: (Image image.XuPoint: (PointPos make: 10 with: 10)).
	oo << nuWarp << '

end of color tests.
'!

{void} simpleWarpTests: oo {ostream reference}

	| dWarp {Warp} bounds {PointPos} nuWarp {Warp} |
	bounds _ PointPos make: 100 with: 100.
	oo << 'creating test warp
'.
	dWarp _ TestWarp make: (Image image.XuPoint: bounds) with: (PointRegion regionExtent: bounds).
	oo << 'test warp is: ' << dWarp << '
'.
	nuWarp _ dWarp intersect: (PointRegion make: 10 with: 10 with: 90 with: 90) translateBy: (PointTranslateDsp make: (PointPos make: 10 with: 10)).
	oo << 'restricted warp is ' << nuWarp << '

testing fill() with PointRegion allPoints with a white warp
'.
	nuWarp white fill: (PointRegion allPoints).
	oo << '

testing border() on a black warp
'.
	dWarp black borderWidth: nuWarp enclosure with: 2.
	oo << '
	
'.!

{void} transformWarpTests: oo {ostream reference}

	| dWarp {Warp} bounds {PointPos} nuWarp {Warp} reg {PointRegion}
	 dsp {PointTranslateDsp} tp {PointPos} |
	bounds _ PointPos make: 100 with: 100.
	oo << 'creating test warp
'.
	dWarp _ TestWarp make: (Image image.XuPoint: bounds) with: (PointRegion regionExtent: bounds).
	reg _ PointRegion make: 20 with: 20 with: 80 with: 80.
	oo << 'test warp is: ' << dWarp << '

test intersect(' << reg << ')
'.
	nuWarp _ dWarp intersect: reg.
	dsp _ PointTranslateDsp make: 10 with: 10.
	oo << 'intersected warp is ' << nuWarp << '

test intersectTranslateBy(' << reg << ', ' << dsp << ').
'.
	nuWarp _ dWarp intersect: reg translateBy: dsp.
	tp _ PointPos make: 50 with: 50.
	oo << 'intersect/translated warp is ' << nuWarp << '
test transform(' << tp << ') from ' << dWarp << '
	transformed point is ' << (dWarp transformPoint: tp) << '

test transform(' << tp << ') from ' << nuWarp << '
	transformed point is ' << (nuWarp transformPoint: tp) << '
	
test transformedBy(' << dsp << ')
'.
	nuWarp _ dWarp transformedBy: dsp.
	oo << '	transformed warp is ' << nuWarp << '

test untransform(' << tp << ') from ' << nuWarp << '
	untransformed point is ' << (nuWarp untransform.Point: tp) << '
	
'.! !

!WarpTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}

	TestWarpEngine setRecordingStream: oo.
	self simpleWarpTests: oo.
	self transformWarpTests: oo.
	self colorWarpTests: oo.
	self borderTests: oo.! !

!WarpTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !