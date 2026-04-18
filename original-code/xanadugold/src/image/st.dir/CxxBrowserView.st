'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:18 pm'!

StandardSystemView subclass: #CxxBrowserView
	instanceVariableNames: 'textView '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Browser'!


!CxxBrowserView methodsFor: 'private: private-subview creation'!

addClassView: area on: aBrowser readOnly: RO
	self addSubView:
		(SelectionInListView on: aBrowser printItems: true oneItem: RO
			aspect: #className change: #classRep: list: #classList
			menu: #classMenu initialSelection: #classRep)
		in: area borderWidth: 1!

addInlineView: area on: aBrowser readOnly: ignored
	| mid |
	mid _ (area left + area right) * 0.5.
	self addSubView: (BooleanView on: aBrowser aspect: #cxxIxx
			label: 'Cxx' asText change: #cxxIxx: value: #cxx)
		in: (area copy right: mid) borderWidth: 1.
	self addSubView: (BooleanView on: aBrowser aspect: #cxxIxx
			label: 'Inline' asText change: #cxxIxx: value: #ixx)
		in: (area copy left: mid) borderWidth: 1!

addMetaView: area on: aBrowser readOnly: ignored
	| mid |
	mid _ (area left + area right) * 0.5.
	self addSubView: (BooleanView on: aBrowser aspect: #meta
			label: 'methods' asText change: #meta: value: false)
		in: (area copy right: mid) borderWidth: 1.
	self addSubView: (BooleanView on: aBrowser aspect: #meta
			label: 'functions' asText change: #meta: value: true)
		in: (area copy left: mid) borderWidth: 1!

addMethodView: area on: aBrowser readOnly: RO
	self addSubView:
		(SelectionInListView on: aBrowser printItems: true oneItem: RO
			aspect: #method change: #methodRep: list: #methodList
			menu: #methodMenu initialSelection: #methodRep)
		in: area borderWidth: 1!

addOutlineFileView: area on: aBrowser readOnly: RO 
	self addSubView: (BetterOutlineView
			on: aBrowser treeBrowser selectionHolder
			menuChannel: 
				(MessageSend receiver: aBrowser treeBrowser selector: #selectionListMenu)
			changeRequestChannel: [aBrowser changeRequest]
			with: aBrowser treeBrowser)
		in: area
		borderWidth: 1!

addProtocolView: area on: aBrowser readOnly: RO
	self addSubView:
		(SelectionInListView on: aBrowser printItems: true oneItem: RO
			aspect: #protocolName change: #protocolRep: list: #protocolList
			menu: #protocolMenu initialSelection: #protocolRep)
		in: area borderWidth: 1!

addPubPrivTestView: area on: aBrowser readOnly: ignored
	| divWidth divHeight |
	divWidth _ (area left + area right) * 0.33.
	divHeight _ (area top + area bottom) * 0.5.
	self addSubView: (BooleanView on: aBrowser aspect: #public
			label: 'public' asText change: #changeVisibility: value: #public)
		in: (area copy right: divWidth) borderWidth: 1.
	self addSubView: (BooleanView on: aBrowser aspect: #protected
			label: 'prot' asText change: #changeVisibility: value: #protected)
		in: (area copy left: divWidth; right: (2*divWidth); top: divHeight) borderWidth: 1.
	self addSubView: (BooleanView on: aBrowser aspect: #private
			label: 'private' asText change: #changeVisibility: value: #private)
		in: (area copy left: divWidth; right: (2*divWidth); bottom: divHeight) borderWidth: 1.
	self addSubView: (BooleanView on: aBrowser aspect: #test
			label: 'test' asText change: #changeVisibility: value: #test)
		in: (area copy left: (2*divWidth)) borderWidth: 1.!

addTextView: area on: aBrowser initialSelection: sel
	self addSubView:
			(textView _ 
			CodeView on: aBrowser aspect: #text change: #acceptText:from:
				menu: #textMenu initialSelection: sel)
		in: area borderWidth: 1! !

!CxxBrowserView methodsFor: 'accessing'!

textView
	^ textView! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CxxBrowserView class
	instanceVariableNames: ''!


!CxxBrowserView class methodsFor: 'instance creation'!

openCxxBrowserOn: aBrowser
	"Create and schedule a browser on the category of classes selected 
	by aBrowser or on a hierarchy of classes."
	"CxxBrowserView openCxxBrowserOn: (CxxBrowser create: CxxSystemOrganization)"

	| topView topY bottomY metaY aboveY |
	
	topY _ 0.35.
	"change this to re-proportion system browser"
	bottomY _ 1 - topY.
	metaY _ 0.05.
	"change this to re-proportion system browser"
	
	aboveY _ topY - metaY.
	(topView _ self model: aBrowser label: 'Cxx Browser' minimumSize: 400@250)
		addOutlineFileView: (0@0 extent: 0.25@aboveY) on: aBrowser readOnly: false;
		addPubPrivTestView: (0@aboveY extent: 0.25@metaY) on: aBrowser readOnly: false;
		addClassView: (0.25@0 extent: 0.25@aboveY) on: aBrowser readOnly: false;
		addMetaView: (0.25@aboveY extent: 0.25@metaY) on: aBrowser readOnly: false;
		addProtocolView: (0.5@0 extent: 0.25@topY) on: aBrowser readOnly: false;
		addMethodView: (0.75@0 extent: 0.25@topY) on: aBrowser readOnly: false;
		addTextView: (0@topY extent: 1.0@bottomY) on: aBrowser initialSelection: nil.

	topView icon: (Icon constantNamed: #default).
	aBrowser controller: (topView textView controller).
	topView controller open!

openOutline
	"Create and schedule a browser on an entire collection of organized 
	classes. For example, evaluate:"
	"CxxBrowserView openOutline"

	CxxBrowserView openOutlineOn: CxxSystemOrganization!

openOutlineOn: anOrganizer 
	"Create and schedule a browser on an entire collection of organized 
	classes. For example, evaluate:"
	"CxxBrowserView openOutlineOn: CxxSystemOrganization"
	
	CxxBrowserView openCxxBrowserOn: (CxxBrowser create: anOrganizer)! !