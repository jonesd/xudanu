'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:29 pm'!

Heaper subclass: #XView
	instanceVariableNames: ''
	classVariableNames: '
		baseWindowInternal {Xv.U.opaque var} 
		defaultDpyInternal {Display star} '
	poolDictionaries: ''
	category: 'FM-XXView'!
XView comment:
'Todo stuff


'!

(XView getOrMakeCxxClassDescription)
	friends:
'friend Display *  defaultDpy ();
friend void  linkRepaint (
						Xv_opaque canvas, 
						Xv_window paintWindow, 
						Display * dpy, 
						Window xwin, 
						Xv_xrectlist * area);
friend void  setBaseWindow (Xv_opaque newBase);
friend void  textRepaint (
						Xv_opaque canvas, 
						Xv_window paintWindow, 
						Display * dpy, 
						Window xwin, 
						Xv_xrectlist * area);
friend Xv_opaque  baseWindow ();
friend void  setBaseWindow (Xv_opaque newBase);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XView methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '(' 
	<<	'baseWindowInternal = '  <<	baseWindowInternal  
	<<	'defaultDpyInternal = '  <<	defaultDpyInternal << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XView class
	instanceVariableNames: ''!

(XView getOrMakeCxxClassDescription)
	friends:
'friend Display *  defaultDpy ();
friend void  linkRepaint (
						Xv_opaque canvas, 
						Xv_window paintWindow, 
						Display * dpy, 
						Window xwin, 
						Xv_xrectlist * area);
friend void  setBaseWindow (Xv_opaque newBase);
friend void  textRepaint (
						Xv_opaque canvas, 
						Xv_window paintWindow, 
						Display * dpy, 
						Window xwin, 
						Xv_xrectlist * area);
friend Xv_opaque  baseWindow ();
friend void  setBaseWindow (Xv_opaque newBase);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XView class methodsFor: 'smalltalk: unused'!

{PointRegion} canvasEnclosure: canvas {Canvas var}
	  | widthI{IntegerVar} heightI {IntegerVar}|
	widthI  _ (XView xv.U.get: canvas with:#CANVAS.U.WIDTH with: NULL) asInteger.
	   heightI  _ (XView xv.U.get: canvas with: #CANVAS.U.HEIGHT with: NULL) asInteger. 

	^PointRegion create: Int0 with: heightI with: Int0 with: widthI!

{PointRegion} canvasEnclosure: canvas {Canvas var} with: warp{XViewWarp}

^PointRegion create: Int0 with:( warp height) with: Int0 with: (warp width)!

{void} linkRepaint: canvas {Canvas var} with:  paintWindow {Xv.U.window var } with:  rects {Rectlist}

| ip {hackpassage.U.passagewindow.U.objects  star}  view{Viewer}  building{FMBuilding} warp{XViewWarp} |

	'fputs("passage: linkRepaint c++ \n", stderr);' translateOnly.


	"ip _ XView getPassageStructThis: canvas. 
	building _ (    ip arrow: #textBuilding) basicCast: FMBuilding star.
	warp _(     ip arrow: #textWarp) basicCast: XViewWarp star.
	view _building view.
	view composeWith: (RegionLayout make: (warp enclosure  )).
	view displayOn: warp."!

{Xv.U.opaque var} passage:textBuilding {FMBuilding} with: linkBuilding {FMBuilding}
"makes a passage view given a FMBuilding
this is a first cut or earlier"!

{void} textRepaintOld: canvas {Canvas var} with:  paintWindow {Xv.U.window var } with:  rects {Rectlist}

| ip {passage.U.passagewindow.U.objects  star}  view{Viewer}  building{FMBuilding} warp{XViewWarp} |

	'fputs("passage: textRepaint c++ \n", stderr);' translateOnly.


	ip _ XView getPassageStructThis: canvas. 
	building _ ( ip arrow: #textBuilding) basicCast: #FMBuilding star.
	warp _( ip arrow: #textWarp) basicCast: #XViewWarp star.
	view _building view.
	view composeWith: (RegionLayout make: (warp enclosure  )).
	view displayOn: warp.! !

!XView class methodsFor: 'global: debugging'!

{void} po2: thing {Heaper}
	#cerr << thing!

{void} po3: thing {StrongPtrVar}
	#cerr << thing DOTfetch!

{void} po4: thing {Heaper wimpy}
	#cerr << thing!

{void} po5
	#cerr <<'eat shit and die'! !

!XView class methodsFor: 'macros: smalltalk: external C functions'!

canvas.U.paint.U.window: foo!

DefaultGC: foo with: bar!

DefaultScreen: foo!

fputs: string with: stream!

notify.U.next.U.event.U.func: xvwin
		with: xvEvent
		with: arg
		with: type!

XSynchronize: display with: foo!

xv.U.find: window with: foo with: int!

xv.U.get: canvas with: width!

xv.U.get: canvas with: width with: ptr!

xv.U.get: thing with: foo with: bar with: baz!

xv.U.init: foo with: argc with: argv with: bar!

xv.U.main.U.loop: foo!

xv.U.set: thing with: foo with: bar with: baz!

xv.U.unique.U.key! !

!XView class methodsFor: 'global: external C functions'!

{Xv.U.opaque var}baseWindow
^baseWindowInternal!

{Display star} defaultDpy
	defaultDpyInternal = NULL ifTrue:[
		XView baseWindow = NULL ifTrue:[
			
		] ifFalse:[
			defaultDpyInternal _ (XView xv.U.get: XView baseWindow with: #XV.U.DISPLAY) basicCast: Display star.
		]
	].
 	^  defaultDpyInternal!

{hackpassage.U.passagewindow.U.objects  star} getPassageStruct: xvwin {Xv.U.Window var}
"this is a prime candidate for cashing the pointer and window, if so the distructor for windows should also zero the cashe as I don't know if X reuses window pointers "

	| tmp {hackpassage.U.passagewindow.U.objects  star}|
	tmp _ (XView xv.U.get: xvwin with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: #hackpassage.U.passagewindow.U.objects star.
		tmp = NULL ifTrue: [
			tmp _ (XView xv.U.get: (XView xv.U.get:xvwin with: #CANVAS.U.PAINT.U.CANVAS.U.WINDOW) with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: #hackpassage.U.passagewindow.U.objects star
	
		].
		 ^tmp!

{hackpassage.U.passagewindow.U.objects  star} getPassageStructPaintCanvas: xvwin {Xv.U.Window var}
"this is a prime candidate for cashing the pointer and window, if so the distructor for windows should also zero the cashe as I don't know if X reuses window pointers "
^ (XView xv.U.get: (XView xv.U.get:xvwin with: #CANVAS.U.PAINT.U.CANVAS.U.WINDOW) with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: #hackpassage.U.passagewindow.U.objects star!

{hackpassage.U.passagewindow.U.objects  star} getPassageStructThis: xvwin {Xv.U.Window var}
"this is a prime candidate for cashing the pointer and window, if so the distructor for windows should also zero the cashe as I don't know if X reuses window pointers "

	 
	^ (XView xv.U.get: xvwin with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: #hackpassage.U.passagewindow.U.objects star.!

{void} importExecuteNotify: item {Panel.U.item var} with:  event {Event star}
 
 " cxx:
	ImportRequestor_popup1_objects	*ip = (ImportRequestor_popup1_objects *) xv_get(item, XV_KEY_DATA, INSTANCE);
	
	fprintf(stderr, ""hackpassage: importExecuteNotify "" );
	 
	
"
| ip {ImportRequestor.U.popup1.U.objects star} ip2 {hackpassage.U.passagewindow.U.objects star} directory{UInt8Array} file{UInt8Array} type {UInt32} |
	 ip _ (XView xv.U.get: item with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#ImportRequestor.U.popup1.U.objects star). 
	  ip2 _ XView getPassageStruct:   ((ip arrow: #parentPassage) basicCast: #Canvas) .
	 	directory _ UInt8Array make: ((XView xv.U.get: (  ip arrow: #importDirectory) with: #PANEL.U.VALUE) basicCast: #char star).
	 	file _ UInt8Array make: ((XView xv.U.get: (  ip arrow: #importFile) with: #PANEL.U.VALUE) basicCast: #char star).
	 	type _  ((XView xv.U.get: (    ip arrow: #importFile) with: #PANEL.U.VALUE) basicCast: UInt32).
			 #cerr << 'hackpassage:importExecuteNotify \n'.
			 
			" XView importStuff: (    ip arrow: #parentPassage) with: directory with: file as: type in: UInt32Zero"
			 XView importStuff2: (    ip2 arrow: #window document) with: directory with: file as: type in: UInt32Zero!

{void} importStuff2: intoDoc{DocumentModel} with: directory {UInt8Array} with: file{UInt8Array}as: type {UInt32} in: place {UInt32}
 
	 
     
    place = UInt32Zero ifTrue:[
     		Filesys readFile: ((intoDoc   contents )cast: AttributedTextModel) with: directory with: file as: type.
     ] ifFalse:[
    		 Filesys readFile: ((intoDoc   contents )cast: AttributedTextModel) with: directory with: file as: type.
     ].
    
      
 #cerr << 'xview:importStuff \n'.!

{void} importStuff: intoWindow{Xv.U.opaque var} with: directory {UInt8Array} with: file{UInt8Array}as: type {UInt32} in: place {UInt32}
| ip {hackpassage.U.passagewindow.U.objects  star}  |

	 
    ip _ XView getPassageStruct:   (intoWindow basicCast: #Canvas) .
    place = UInt32Zero ifTrue:[
     		Filesys readFile: ((((ip arrow: #window document) cast: PassageModel)   contents )cast: AttributedTextModel) with: directory with: file as: type.
     ] ifFalse:[
    		 Filesys readFile: ((((ip arrow: #window document) cast: PassageModel)   contents )cast: AttributedTextModel) with: directory with: file as: type.
     ].
    
      
 #cerr << 'xview:importStuff \n'.!

{void} link.U.pane.U.resize: canvas {Canvas var} with:   width {int} with: height {int} 

 | ip {hackpassage.U.passagewindow.U.objects  star}   building{FMBuilding} view{Viewer}|

	'fputs("hackpassage: linkResize c++ \n", stderr);' translateOnly.
 	 
    XView getPassageStructThis: canvas.
    ip _ XView getPassageStruct: (XView canvas.U.paint.U.window: (canvas basicCast: #Canvas)) . 
  "   XView xv.U.set: (XView canvas.U.paint.U.window:(ip->#linkpane)) with: #XV.U.HEIGHT with: 10000 with: NULL."
	
  XView tieTheWarpsToTheCanvases: (XView canvas.U.paint.U.window: (ip arrow: #textPane)) with:(XView canvas.U.paint.U.window: (ip arrow: #linkpane)).
   (ip arrow: #window) ifTrue:
	 [building  _ (  ip arrow: #window) referencesBuilding  .
 
	view _building view.
	view update: UpdateRecord make from:  (ip arrow: #window).]!

{void} linkRepaint: canvas {Xv.U.opaque var} with:  paintWindow {Xv.U.window var } with:  dpy {Display star} with: xwin {Window var} with: area { Xv.U.xrectlist star}

| ip {hackpassage.U.passagewindow.U.objects  star}  "ip2 {hackpassage.U.passagewindow.U.objects  star}" view{Viewer}  building{FMBuilding} warpDrive{WarpDrive} warp {Warp}   |

	'fputs("hackpassage: linkRepaint c++ \n", stderr); ' translateOnly.
 	 defaultDpyInternal _ dpy. 
    
   
    ip _ XView getPassageStruct: (XView canvas.U.paint.U.window: (canvas basicCast: #Canvas)) . 
    XView textPaneRatio: ip with: (  ip arrow: #textRatio).
      (ip arrow: #window) ifTrue:
	 [building  _ (  ip arrow: #window) referencesBuilding  .
 
	view _building view.
	view update: UpdateRecord make from:  (ip arrow: #window).].
	
	building  _ (  ip arrow: #window) referencesBuilding  .
	 
	warpDrive _(  ip arrow: #linkWarp) basicCast: WarpDrive star. 
	view _building view.
	(ip arrow: #window) ifTrue:[
	 
	view update: UpdateRecord make from:  (ip arrow: #window).].
	view composeWith: (RegionLayout make: (PointRegion make: (((warpDrive engine) cast: XViewWarp) enclosure  ) width with: 100000)). 
	  
	 (warpDrive engine cast: XViewWarp) setxstuff: dpy with: (XView canvas.U.paint.U.window: (canvas basicCast: #Canvas)).
	warpDrive setupDisplay.
	"warp _ (Warp make:  (PointTranslateDsp make) with: (((warpDrive engine)cast: XViewWarp) enclosure) with: warpDrive)."
	warp _ (Warp make:  (PointTranslateDsp make) with: ( PointRegion make:(((warpDrive engine)cast: XViewWarp) enclosure ) width with: 1000) with: warpDrive).
	
	
	"warpDrive display: view using: warp  ."
	warp display: view.
	warpDrive finishDisplay.!

{void star}linkWarpInCanvas: xvCanvas {Xv.U.opaque var}

'
	hackpassage_passagewindow_objects *ip = (hackpassage_passagewindow_objects *) xv_get(xvCanvas, XV_KEY_DATA, INSTANCE);
		return ip->linkWarp;
		' translateOnly.!

{void star}putLinkWarpInCanvas: twarp {WarpDrive} with: xvCanvas {Xv.U.opaque var}

'
	hackpassage_passagewindow_objects *ip = (hackpassage_passagewindow_objects *) xv_get(xvCanvas, XV_KEY_DATA, INSTANCE);
	FMBuilding::unRegisterAsStrongPointer((Heaper *)(ip->linkWarp));
		return ip->linkWarp = (void *) twarp;
		' translateOnly.!

{void star}putTextWarpInCanvas: twarp {WarpDrive} with: xvCanvas {Xv.U.opaque var}

'
	hackpassage_passagewindow_objects *ip = (hackpassage_passagewindow_objects *) xv_get(xvCanvas, XV_KEY_DATA, INSTANCE);
	FMBuilding::unRegisterAsStrongPointer((Heaper *)(ip->textWarp));
		return ip->textWarp = (void *) twarp;
		' translateOnly.!

{void}setBaseWindow: newBase{Xv.U.opaque var}
 baseWindowInternal _ newBase.
 defaultDpyInternal _ (XView xv.U.get: newBase with: #XV.U.DISPLAY) basicCast:  Display star.
 'XSynchronize(XView::defaultDpyInternal,1);' translateOnly.!

{void} text.U.pane.U.resize: canvas {Canvas var} with:   width {int} with: height {int} 
 | ip {hackpassage.U.passagewindow.U.objects  star}   building{FMBuilding} view{Viewer}|

	'fputs("hackpassage: textResize c++ \n", stderr);  ' translateOnly.
 	 
    ip _ XView getPassageStruct: (XView canvas.U.paint.U.window: (canvas basicCast: #Canvas)) . 
 
	 XView tieTheWarpsToTheCanvases: (XView canvas.U.paint.U.window: (ip arrow: #textPane)) with:(XView canvas.U.paint.U.window: (ip arrow: #linkpane)).
	 (ip arrow: #window) ifTrue:
	 [building  _ (  ip arrow: #window) documentBuilding  .
 
	view _building view.
	view update: UpdateRecord make from:  (ip arrow: #window).].!

{void} textPaneRatio: ip {hackpassage.U.passagewindow.U.objects star} with: value {int  }   
 |tSize {int} totalSize {int} lSize{int} size {int} slackSize {int} |
	'
	fprintf(stderr, "hackpassage: textPaneSliderNotify: value: %d\n", value);
	tSize = xv_get(ip->textPane,XV_WIDTH,0 );
	lSize = xv_get(ip->linkpane,XV_WIDTH,0 );
	totalSize = xv_get(ip->passagewindow,XV_WIDTH,0 );
	size = tSize+lSize;
	size = totalSize;
	slackSize = 0;//totalSize - size;
	if(value < 98){
		tSize = size * value/100;
		lSize = size - tSize;
		 
	} else{
		tSize = size;
		lSize = 0;
		value = 100;
	}
	ip->textRatio = value;
	xv_set(ip->textPane, XV_WIDTH,tSize,0);
	xv_set(ip->linkpane, XV_WIDTH,lSize,0);
	xv_set(ip->linkpane, XV_X, tSize + slackSize / 2 ,0);
	 
	' translateOnly!

{void} textPaneSliderNotify: item {Panel.U.item var} with: value {int  }  with: event {Event star}
 
	'
	hackpassage_passagewindow_objects	*ip = (hackpassage_passagewindow_objects *) xv_get(item, XV_KEY_DATA, INSTANCE);
	
	fprintf(stderr, "hackpassage: textPaneSliderNotify: value: %d\n", value);
	textPaneRatio(ip,value);
	' translateOnly!

{void} textRepaint: canvas {Xv.U.opaque var} with:  paintWindow {Xv.U.window var } with:  dpy {Display star} with: xwin {Window var} with: area { Xv.U.xrectlist star}

| ip {hackpassage.U.passagewindow.U.objects  star}  "ip2 {hackpassage.U.passagewindow.U.objects  star}" view{Viewer}  building{FMBuilding} warpDrive{WarpDrive} warp {Warp}    |

	'fputs("hackpassage: textRepaint c++ \n", stderr); ' translateOnly.
 	 defaultDpyInternal _ dpy. 
   
    ip _ XView getPassageStruct: (XView canvas.U.paint.U.window: (canvas basicCast: #Canvas)) . 
    XView textPaneRatio: ip with: (  ip arrow: #textRatio).
 	
	building  _ (  ip arrow: #window) documentBuilding  .
	 
	   
	" XView tieTheWarpsToTheCanvases: (XView canvas.U.paint.U.window: (ip arrow: #textPane)) with:(XView canvas.U.paint.U.window: (ip arrow: #linkpane))."
	warpDrive _(  ip arrow: #textWarp) basicCast: WarpDrive star. 
	view _building view.
	  (ip arrow: #window) ifTrue:[
	 
	view update: UpdateRecord make from:  (ip arrow: #window).].
	  view composeWith: (RegionLayout make: (PointRegion make: (((warpDrive engine) cast: XViewWarp) enclosure  ) width with: 100000)). 
	 
	 (warpDrive engine cast: XViewWarp) setxstuff: dpy with: (XView canvas.U.paint.U.window: (canvas basicCast: #Canvas)).
	warpDrive setupDisplay.
	warp _ (Warp make:  (PointTranslateDsp make) with: ( PointRegion make:(((warpDrive engine)cast: XViewWarp) enclosure ) width with: 1000) with: warpDrive).
	
	"warpDrive display: view using: warp  ."
	warp display: view.
	warpDrive finishDisplay.
	 
	"(Warp make:  (PointTranslateDsp make) with: warpDrive enclosure with: warpDrive)
	display: view"!

{void star}textWarpInCanvas: xvCanvas {Xv.U.opaque var}
| ip {hackpassage.U.passagewindow.U.objects star} |
	 ip _ (XView xv.U.get: xvCanvas with: #XV.U.KEY.U.DATA with: #INSTANCE) basicCast: (#hackpassage.U.passagewindow.U.objects star).
	 ^   ip arrow: #textWarp. 
" cxx:
	hackpassage_passagewindow_objects *ip = (hackpassage_passagewindow_objects *) xv_get(xvCanvas, XV_KEY_DATA, INSTANCE);
		return ip->textWarp;
		"!

{void} tieTheWarpsToTheCanvases: xvtextcanvas {Xv.U.opaque var } with: xvlinkcanvas {Xv.U.opaque var}
		| textWarp {XViewWarp}   linkWarp {XViewWarp}  newWarpDrive {WarpDrive} dpy{Display star} |
		
	 xvtextcanvas = NULL ifFalse: [ 
	 
		textWarp _ XViewWarp create: xvtextcanvas.
	 
		newWarpDrive _ WarpDrive make: textWarp.
		XView putTextWarpInCanvas: newWarpDrive with: xvtextcanvas.
		FMBuilding registerAsStrongPointer: newWarpDrive.
		dpy _ (XView xv.U.get: xvtextcanvas with: #XV.U.DISPLAY) basicCast: Display star.
		textWarp setxstuff: dpy with: xvtextcanvas. " this may be incorrect, might want ip-> textPane rather than the canvaswindow thereof but I think its right roger nov 8 1990"
	].
	xvlinkcanvas = NULL ifFalse:[
		linkWarp _ XViewWarp create: xvlinkcanvas.
	 
		newWarpDrive _ WarpDrive make: linkWarp.
		XView putLinkWarpInCanvas: newWarpDrive with: xvlinkcanvas.
		FMBuilding registerAsStrongPointer: newWarpDrive.
		 
	]!

{void} xu.U.xview.U.args: argc {int var} with: argv {char vector star}
" Initialize XView"

	XView xv.U.init: #XV.U.INIT.U.ARGS with: argc with: argv with: NULL! !

!XView class methodsFor: 'xview: smalltalk: utility in line eventually'!

{Rect star}pointRegion2rect: pointR {PointRegion}!

{PointRegion}rect2PointRegion: rect {Rect star}!

{void} tieThe: textBuild{FMBuilding} Buildings: linkBuild{FMBuilding} ToTheCanvases: xvtextcanvas {Xv.U.opaque var } with: xvlinkcanvas {Xv.U.opaque var}
	| textWarp {XViewWarp}   linkWarp {XViewWarp} |
	textWarp _ XViewWarp create: xvtextcanvas.
	textWarp registerTextWithCanvas. 
	linkWarp _ XViewWarp create: xvlinkcanvas.
	linkWarp registerLinkWithCanvas.! !

!XView class methodsFor: 'smalltalk: init'!

initTimeNonInherited 
	baseWindowInternal _ NULL.
	defaultDpyInternal _NULL.
	[XView xu.U.xview.U.args: Initializer mainAC with: Initializer mainAV.
 	 XView xv.U.unique.U.key.
	 XView xv.U.unique.U.key.
	 XView xv.U.unique.U.key] translateOnly.!

linkTimeNonInherited 
baseWindowInternal _ NULL.
defaultDpyInternal _NULL.! !