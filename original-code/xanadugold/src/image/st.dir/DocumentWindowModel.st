'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:56 pm'!

WindowModel subclass: #DocumentWindowModel
	instanceVariableNames: '
		myReferenceFilter {VariableModel of: TapestryFilter}
		myDocument {DocumentModel}
		myDocumentSelection {SelectionObject}
		myDocumentBuilding {FMBuilding}
		myDocumentScroller {ScrollerSchnert}
		myReferences {ListModel of: Reference}
		myReferencesSelection {SelectionObject}
		myReferencesBuilding {FMBuilding}
		myReferenceBuilder {FMBuilder}
		myReferencesScroller {ScrollerSchnert}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
DocumentWindowModel comment:
'Models the behaviour of a standard Tapestry
document window, in particular the icon bar layout, the
menus,
and the two panes (references and document). Window-system
specific code should be written with #ifdef blocks and
methods.

		myReferenceFilter {VariableModel of: ReferenceFilter}
			The filter used to find references to the document
		myDocument {DocumentModel}
			The document being viewed
		myDocumentSelection {SelectionRange}
			The current selection in the document
		myDocumentBuilding {FMBuilding}
			The FM viewer & controller for the document pane
		myDocumentScroller {ScrollerSchnert}
			The schnert controlling the scrolling of the document
pane
		myReferences {ListModel of: Reference}
			The list of references to the document
		myReferencesSelection {SelectionObject}
			The currently selected references
		myReferencesBuilding {FMBuilding}
			The FM viewer & controller for the references pane
		myReferencesBuilder {FMBuilder}
			The FM builder that creates the viewer/controller for a
single reference
		myReferencesScroller {ScrollerSchnert}
			The schnert controlling the scrolling of the references
pane'!

(DocumentWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!DocumentWindowModel methodsFor: 'accessing'!

{DocumentModel} document
	"the document being edited"
	^myDocument!

{FMBuilding} documentBuilding 
	"the View+Controller for the document pane; build if necessary"
	myDocumentBuilding == NULL ifTrue:
		[Scaffold fluidBind: self documentScaffold during:
			[myDocumentBuilding _ Scaffold fluidVar build: self document].
		myDocumentScroller _ ScrollerSchnert make: myDocumentBuilding view].
	^myDocumentBuilding!

{FMScaffold} documentScaffold
	"scaffold to use for building document pane"
	self subclassResponsibility!

{ScrollerSchnert} documentScroller
	"the scroller for the main document"
	^myDocumentScroller!

{SelectionObject} documentSelection
	"the selection in the document being edited"
	^myDocumentSelection!

{FMBuilder} referenceBuilder
	
	^ myReferenceBuilder!

{VariableModel of: TapestryFilter} referenceFilter
	"the current filter used for looking at references"
	^myReferenceFilter!

{ListModel of: Reference} references
	"the current list of references"
	^myReferences!

{FMBuilding} referencesBuilding 
	"the View+Controller for the references pane; build if
necessary"
	myReferencesBuilding == NULL ifTrue:
		[| notifier {NotifierSchnert} | 
			Scaffold fluidBind: self referencesScaffold during:
			[myReferencesBuilding _ Scaffold fluidVar build: self
references].
		myReferencesScroller _ ScrollerSchnert make:
myReferencesBuilding view.
		notifier _ NotifierSchnert make.
		notifier addDependent: (myReferencesBuilding cast:
FMDirectorBuilding) director.
		(myReferenceBuilder cast: FMDeferredBuilder)
builderModel addDependent: notifier].
	^myReferencesBuilding!

{ScrollerSchnert} referencesScroller
	"the scroller for the references pane"
	^myReferencesScroller!

{SelectionObject} referencesSelection
	"the selected references"
	^myReferencesSelection! !

!DocumentWindowModel methodsFor: 'protected: operations'!

{void} attachNote: type {ID} with: swapped {Boolean} with: permissions {ID} with: outline {Boolean}
	"create a note and attach it to the current selection with a link"
	| note {DocumentModel} a {LinkEnd} b {LinkEnd} |
	self hack. "ignores permissions"
	outline
		ifTrue: [note _ Application fluidVar createOutline: permissions]
		ifFalse: [note _ Application fluidVar createPassage].
	a _ self createLinkEnd.
	b _ note createLinkEnd.
	swapped ifTrue: [ | t {LinkEnd} | t _ a. a _ b. b _ t].
	Application fluidVar createLink: a with: b with: type with: permissions.
	Application fluidVar openWindow: note!

{LinkEnd} createLinkEnd
	"create a link end on the current document with the current selection"
	^self document createLinkEnd: self documentSelection! !

!DocumentWindowModel methodsFor: 'smalltalk: windowing'!

{STWindowModel} createSmalltalkWindow
	"create a corresponding smalltalk window object"
	self subclassResponsibility!

{void} openSmalltalkWindow
	mySTWindowModel open! !

!DocumentWindowModel methodsFor: 'private: building'!

{FMScaffold} referencesScaffold
	"scaffold to use for building references pane"
	| builder {MuTable of: FMBuilder} |

	builder _ MuTable make: HeaperSpace make.
	builder at: (HeaperAsPosition make: ListModel) introduce:
(ReferenceListBuilder make: self).
	builder at: (HeaperAsPosition make: Reference) introduce:
myReferenceBuilder.
	^FMScaffold make: builder with: Scaffold fluidVar! !

!DocumentWindowModel methodsFor: 'protected:
create/destruct'!

create: document {DocumentModel} 
	super create.
	[UserModel] USES.
	myReferenceFilter _ "VariableModel make: Application fluidVar user defaultFilter getValue"
			NULL .
	myDocument _ document.
	myDocumentSelection _ NULL.
	"setup from subclass constructor"
	myDocumentScroller _ NULL.
	myDocumentBuilding _ NULL.
	myReferences _ "myDocument createReferenceList: myReferenceFilter" ListModel make.
	myReferencesSelection _ ListSelection make: IntegerRegion make.
	myReferenceBuilder _ FMDeferredBuilder make: Application fluidVar user defaultReferencesStyle.
	myReferencesScroller _ NULL.
	myReferencesBuilding _ NULL.
	Refs2DocSelectionSchnert make: self.
	List2SelectionSchnert make: myReferences with: myReferencesSelection!

{void} destruct
	myReferenceFilter destroy.
	myReferenceFilter _ NULL.
	myDocument _ NULL.
	myDocumentSelection _ NULL.
	myDocumentScroller _ NULL.
	myDocumentBuilding _ NULL.
	myReferences destroy.
	myReferences _ NULL.
	myReferencesSelection destroy.
	myReferencesSelection _ NULL.
	myReferencesScroller _ NULL.
	myReferencesBuilding _ NULL.
	super destruct! !

!DocumentWindowModel methodsFor: 'protected: setup'!

{void} setDocumentSelection: selection {SelectionObject}
	"set up from subclass constructor"
	myDocumentSelection _ selection! !

!DocumentWindowModel methodsFor: 'xview: windowing'!

{void} openXViewWindow
self myXViewWindowModel open! !

!DocumentWindowModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	super printOn: oo.
	oo	<< 'myReferenceFilter' << myReferenceFilter  
		<< 'myDocument'  << myDocument 
		<< 'myDocumentSelection'  << myDocumentSelection  
		<< 'myDocumentBuilding'  << myDocumentBuilding  
		<< 'myDocumentScroller' << myDocumentScroller
		<< 'myReferences'  << myReferences 
		<< 'myReferencesSelection'  << myReferencesSelection
		<< 'myReferencesBuilding'  << myReferencesBuilding 
		<< 'myReferencesScroller' << myReferencesScroller! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DocumentWindowModel class
	instanceVariableNames: ''!

(DocumentWindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!DocumentWindowModel class methodsFor: 'pseudoConstructors'!

{FMBuilder} defaultReferenceBuilder
	^ TwoLineReferenceBuilder make! !