'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:30 pm'!

XViewWindowModel subclass: #XViewDocumentWindowModel
	instanceVariableNames: 'hackPassageObjectInternal {hackpassage.U.passagewindow.U.objects star}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-XXView'!

(XViewDocumentWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewDocumentWindowModel methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel}
	" 
	ifFalse: [model == self window document readPermissions ifTrue:
		[self changed: #reader]
	ifFalse: [model == self window document editPermissions ifTrue:
		[self changed: #writer]
	ifFalse: [model == self window referenceFilter ifTrue:
		[self changed: #filter]]]]"! !

!XViewDocumentWindowModel methodsFor: 'create'!

create: gwindow {WindowModel}
 super create: gwindow.
 XView USES.
 
	"| wname {Waldo} name {String} top {StandardSystemView} |"
	" super create: window."
	"wname _ self window document name.
	(wname isKindOf: XuText)
		ifTrue: [name _ (wname asWordArray: -1) asString]
		ifFalse: [name _ '<' , wname getCategory name , '>'].
	top  _ StandardSystemView model: self
		label: name
		minimumSize: 500@400.
	self attachIconsTo: top above: 0.075.
	self attachPanesTo: top below: 0.075.
	myController _ top controller.
	myController initialize; open"! !

!XViewDocumentWindowModel methodsFor: 'windowing'!

{void} open
	 
	XView USES. 
'
		 
	DocumentWindowModel *window;
	FMBuilding *tmpBuildingText;
	FMBuilding *tmpBuildingLinks;
	//INSTANCE = xv_unique_key();
	window = CAST(DocumentWindowModel,this->window());
	tmpBuildingText = window->documentBuilding();
	FMBuilding::registerAsStrongPointer(tmpBuildingText);
	tmpBuildingLinks = window->referencesBuilding();
	FMBuilding::registerAsStrongPointer(tmpBuildingLinks);
	cerr <<tmpBuildingText << tmpBuildingLinks << ''\n'';
	FMBuilding::registerAsStrongPointer(window);
	//
	// Initialize user interface components.
	//
	 
	hackPassageObjectInternal = new hackpassage_passagewindow_objects ();
	 
	hackPassageObjectInternal->objects_initialize((Xv_opaque)NULL,window );
	 
	// no need to register building as WindowModel holds on to it ???
	
' translateOnly.! !

!XViewDocumentWindowModel methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '()'! !