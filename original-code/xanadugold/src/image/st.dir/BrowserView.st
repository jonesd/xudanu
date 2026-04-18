'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:57 pm'!

StandardSystemView subclass: #BrowserView
	instanceVariableNames: ''
	classVariableNames: 'MethodSetViewBusy {BooleanVar} '
	poolDictionaries: ''
	category: 'Tools-Browser'!
BrowserView comment:
'A BrowserView is a StandardSystemView that provides initialization methods (messages to itself) to create and schedule the various system browsers:  System Browser, System Category Browser, Class Browser, Message Category Browser, Message Browser.'!



!BrowserView methodsFor: 'private: private-subview creation'!

addCategoryView: area on: aBrowser readOnly: RO
	self addSubView:
		(SelectionInListView on: aBrowser printItems: true oneItem: RO
			aspect: #category change: #categoryRep: list: #categoryList
			menu: #categoryMenu initialSelection: #categoryRep)
		in: area borderWidth: 1!

addClassView: area on: aBrowser readOnly: RO
	self addSubView:
		(SelectionInListView on: aBrowser printItems: true oneItem: RO
			aspect: #className change: #classRep: list: #classList
			menu: #classMenu initialSelection: #classRep)
		in: area borderWidth: 1!

addMetaView: area on: aBrowser readOnly: ingored
	| mid |
	mid _ (area left + area right) * 0.5.
	self addSubView: (BooleanView on: aBrowser aspect: #meta
			label: 'instance' asText change: #meta: value: false)
		in: (area copy right: mid) borderWidth: 1.
	self addSubView: (BooleanView on: aBrowser aspect: #meta
			label: 'class' asText change: #meta: value: true)
		in: (area copy left: mid) borderWidth: 1!

addMethodView: area on: aBrowser readOnly: RO

	self addSubView:
		(SelectionInListView on: aBrowser printItems: true oneItem: RO
			aspect: #methodName change: #methodName: list: #methodList
			menu: #methodMenu initialSelection: #methodName)
		in: area borderWidth: 1!

addProtocolView: area on: aBrowser readOnly: RO
	self addSubView:
		(SelectionInListView on: aBrowser printItems: true oneItem: RO
			aspect: #protocol change: #protocolRep: list: #protocolList
			menu: #protocolMenu initialSelection: #protocolRep)
		in: area borderWidth: 1!

addSelectorView: area on: aBrowser readOnly: RO
	self addSubView:
		(SelectionInListView on: aBrowser printItems: true oneItem: RO
			aspect: #selector change: #selectorRep: list: #selectorList
			menu: #selectorMenu initialSelection: #selectorRep)
		in: area borderWidth: 1!

addTextView: area on: aBrowser initialSelection: sel
	self addSubView:
			(CodeView on: aBrowser aspect: #text change: #acceptText:from:
				menu: #textMenu initialSelection: sel)
		in: area borderWidth: 1! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BrowserView class
	instanceVariableNames: ''!



!BrowserView class methodsFor: 'preferences'!

{BooleanVar} isMethodSetViewBusy

	MethodSetViewBusy == nil
		ifTrue: [MethodSetViewBusy _ false].
	^MethodSetViewBusy!

{void} methodSetViewBusy: flag {BooleanVar}
	"BrowserView methodSetViewBusy: true"
	"BrowserView methodSetViewBusy: false"

	MethodSetViewBusy _ flag! !

!BrowserView class methodsFor: 'instance creation'!

openCategoryBrowserOn: aBrowser
	"Create and schedule a browser on the category of classes selected by aBrowser or on a hierarchy of classes."

	| topView |
	(topView _ self model: aBrowser label: (aBrowser category, ' Category Browser') minimumSize: 400@250)
		addCategoryView: (0@0 extent: 0.3@0.06) on: aBrowser readOnly: true;
		addClassView: (0@0.06 extent: 0.3@0.28) on: aBrowser readOnly: false;
		addMetaView: (0@0.34 extent: 0.3@0.06) on: aBrowser readOnly: false;
		addProtocolView: (0.3@0 extent: 0.3@0.4) on: aBrowser readOnly: false;
		addSelectorView: (0.6@0 extent: 0.4@0.4) on: aBrowser readOnly: false;
		addTextView: (0@0.4 extent: 1.0@0.6) on: aBrowser initialSelection: nil.
	topView controller open!

openCategoryBrowserOn: aBrowser withController: aController
	"Create and schedule a browser on the category of classes selected by aBrowser 
	or on a hierarchy of classes.  Set the topview's controller to a be aController."

	| topView textView |
	(topView _ self model: aBrowser label: (aBrowser category, ' Category Browser') minimumSize: 400@250)
		addCategoryView: (0@0 extent: 0.3@0.06) on: aBrowser readOnly: true;
		addClassView: (0@0.06 extent: 0.3@0.28) on: aBrowser readOnly: false;
		addMetaView: (0@0.34 extent: 0.3@0.06) on: aBrowser readOnly: false;
		addProtocolView: (0.3@0 extent: 0.3@0.4) on: aBrowser readOnly: false;
		addSelectorView: (0.6@0 extent: 0.4@0.4) on: aBrowser readOnly: false.
	textView _ CodeView
				on: aBrowser
				aspect: #text
				change: #acceptText:from:
				menu: #textMenu
				initialSelection: nil.
	textView controller: aController.
	topView
		addSubView: textView
		in: (0@0.4 extent: 1.0@0.6)
		borderWidth: 1.
	topView controller open!

openClassBrowserOn: aBrowser
	"Create and schedule a browser on the class currently selected by aBrowser."

	| topView |
	(topView _ self model: aBrowser label: (aBrowser className,' Class Browser') minimumSize: 400@250)
		addClassView: (0@0 extent: 0.5@0.1) on: aBrowser readOnly: true;
		addMetaView: (0.5@0 extent: 0.5@0.1) on: aBrowser readOnly: false;
		addProtocolView: (0@0.1 extent: 0.5@0.3) on: aBrowser readOnly: false;
		addSelectorView: (0.5@0.1 extent: 0.5@0.3) on: aBrowser readOnly: false;
		addTextView: (0@0.4 extent: 1.0@0.6) on: aBrowser initialSelection: nil.
	topView controller open!

openClassBrowserOn: aBrowser withController: aController
	"Create and schedule a browser on the class currently selected selected by aBrowser 
	or on a hierarchy of classes.  Set the topview's controller to a be aController."

	| topView textView |
	(topView _ self model: aBrowser label: (aBrowser className,' Class Browser') minimumSize: 400@250)
		addClassView: (0@0 extent: 0.5@0.1) on: aBrowser readOnly: true;
		addMetaView: (0.5@0 extent: 0.5@0.1) on: aBrowser readOnly: false;
		addProtocolView: (0@0.1 extent: 0.5@0.3) on: aBrowser readOnly: false;
		addSelectorView: (0.5@0.1 extent: 0.5@0.3) on: aBrowser readOnly: false.
	textView _ CodeView
				on: aBrowser
				aspect: #text
				change: #acceptText:from:
				menu: #textMenu
				initialSelection: nil.
	textView controller: aController.
	topView
		addSubView: textView
		in: (0@0.4 extent: 1.0@0.6)
		borderWidth: 1.
	topView controller open!

{NOWAIT} openFamilyBrowserOn: aBrowser {FamilyBrowser}
	"Create and schedule a browser on the category of classes selected by aBrowser or on a hierarchy of classes."

	| topView |
	(topView _ self model: aBrowser label: (aBrowser familyCenter name, '''s family') minimumSize: 400@250)
		addClassView: (0@0.0 extent: 0.3@0.34) on: aBrowser readOnly: false;
		addMetaView: (0@0.34 extent: 0.3@0.06) on: aBrowser readOnly: false;
		addProtocolView: (0.3@0 extent: 0.3@0.4) on: aBrowser readOnly: false;
		addSelectorView: (0.6@0 extent: 0.4@0.4) on: aBrowser readOnly: false;
		addTextView: (0@0.4 extent: 1.0@0.6) on: aBrowser initialSelection: nil.
	topView controller open!

openMethodBrowserOn: aBrowser 
	"Create and schedule a browser on the method currently selected by aBrowser."

	| topView |
	(topView _ self
				model: aBrowser
				label: aBrowser selectedClass name, '>>', aBrowser selector
				minimumSize: 250 @ 120)
		addSelectorView: (0 @ 0 extent: 1 @ 0.05)
		on: aBrowser
		readOnly: true;
		addTextView: (0 @ 0.05 extent: 1 @ 0.95)
		on: aBrowser
		initialSelection: nil.
	topView controller open!

openMethodBrowserOn: aBrowser withController: aController 
	"Create and schedule a browser on the method currently selected by aBrowser.  
	Set the topview's controller to a be aController.  The method may contain changes 
	that haven't already been accepted "

	| topView textView |
	topView _ self
				model: aBrowser
				label: aBrowser selectedClass name, '>>', aBrowser selector
				minimumSize: 250 @ 120.
	topView
		addSelectorView: (0 @ 0 extent: 1 @ 0.05)
		on: aBrowser
		readOnly: true.
	textView _ CodeView
				on: aBrowser
				aspect: #text
				change: #acceptText:from:
				menu: #textMenu
				initialSelection: nil.
	textView controller: aController.
	topView
		addSubView: textView
		in: (0 @ 0.05 extent: 1 @ 0.95)
		borderWidth: 1.
	topView controller open!

openMethodSetBrowserOn: aBrowser {MethodSetBrowser} 
	label: label {String}
	initialSelection: pattern {String | Something}
	"Create and schedule a browser on the category of classes selected by aBrowser or on a hierarchy of classes."

	| topView width {Number} |
	topView _ self model: aBrowser label: label minimumSize: 400@250.
	width _ self isMethodSetViewBusy ifTrue: [0.66] ifFalse: [1].
	topView addMethodView: (0 @ 0 extent: width @ 0.25) on: aBrowser readOnly: false.
	self isMethodSetViewBusy 
		ifTrue:
			[topView addClassView: (width @ 0 extent: 0.34 @ 0.11) on: aBrowser readOnly: false.
			topView addMetaView: (width @ 0.11 extent: 0.34 @ 0.03) on: aBrowser readOnly: false.
			topView addProtocolView: (width @ 0.14 extent: 0.34 @ 0.11) on: aBrowser readOnly: false].
	topView addTextView: (0 @ 0.25 extent: 1 @ 0.75) on: aBrowser initialSelection: pattern.
	topView controller open!

openOn: anOrganizer 
	"Create and schedule a browser on an entire collection of organized 
	classes. For example, evaluate"
	"BrowserView openOn: SystemOrganization."

	BrowserView openOnBrowser: (Browser new on: anOrganizer)!

openOn: aBrowser withController: aController
	"Create and schedule a browser on an entire collection of organized 
	classes.   Set the controller for the topview to be aController.
	aController may contain changes that haven't already been accepted."

	| topView textView |
	(topView _ self model: aBrowser label: 'System Browser' minimumSize: 400@250)
		addCategoryView: (0@0 extent: 0.25@0.4) on: aBrowser readOnly: false;
		addClassView: (0.25@0 extent: 0.25@0.34) on: aBrowser readOnly: false;
		addMetaView: (0.25@0.34 extent: 0.25@0.06) on: aBrowser readOnly: false;
		addProtocolView: (0.5@0 extent: 0.25@0.4) on: aBrowser readOnly: false;
		addSelectorView: (0.75@0 extent: 0.25@0.4) on: aBrowser readOnly: false.
	textView _ CodeView 
					on: aBrowser aspect: #text change: #acceptText:from:
					menu: #textMenu initialSelection: nil.
	textView controller: aController.
	topView addSubView: textView in: (0@0.4 extent: 1@0.6) borderWidth: 1.
	topView controller open!

openOnBrowser: aBrowser 
	"Create and schedule a browser on an entire collection of organized 
	classes. For example, evaluate"
	"BrowserView openOnBrowser: (Browser new on: SystemOrganization)"

	| topView topY bottomY metaY |
	topY _ 0.35.
	"change this to re-proportion system browser"
	bottomY _ 1 - topY.
	metaY _ 0.05.
	"change this to re-proportion system browser"
	(topView _ self model: aBrowser label: 'System Browser' minimumSize: 400 @ 250)
		addCategoryView: (0 @ 0 extent: 0.25 @ topY) on: aBrowser readOnly: false;
		addClassView: (0.25 @ 0 extent: 0.25 @ (topY - metaY)) on: aBrowser readOnly: false;
		addMetaView: (0.25 @ (topY - metaY) extent: 0.25 @ metaY) on: aBrowser readOnly: false;
		addProtocolView: (0.5 @ 0 extent: 0.25 @ topY) on: aBrowser readOnly: false;
		addSelectorView: (0.75 @ 0 extent: 0.25 @ topY) on: aBrowser readOnly: false;
		addTextView: (0 @ topY extent: 1.0 @ bottomY) on: aBrowser initialSelection: nil.
	topView icon: (Icon constantNamed: #default).
	topView controller open!

openProtocolBrowserOn: aBrowser
	"Create and schedule a browser on the message category currently selected by aBrowser."

	| topView |
	(topView _ self model: aBrowser label: aBrowser selectedClass name, ' Protocol Browser'
					minimumSize: 400@200)
		addProtocolView: (0@0 extent: 1@0.1) on: aBrowser readOnly: true;
		addSelectorView: (0@0.1 extent: 1@0.3) on: aBrowser readOnly: false;
		addTextView: (0@0.4 extent: 1.0@0.6) on: aBrowser initialSelection: nil.
	topView controller open!

openProtocolBrowserOn: aBrowser withController: aController
	"Create and schedule a browser on the category of messages selected by aBrowser 
	or on a hierarchy of classes.  Set the topview's controller to a be aController."

	| topView textView |
	(topView _ self model: aBrowser label: aBrowser selectedClass name, ' Protocol Browser'
					minimumSize: 400@200)
		addProtocolView: (0@0 extent: 1@0.1) on: aBrowser readOnly: true;
		addSelectorView: (0@0.1 extent: 1@0.3) on: aBrowser readOnly: false.
	textView _ CodeView
				on: aBrowser
				aspect: #text
				change: #acceptText:from:
				menu: #textMenu
				initialSelection: nil.
	textView controller: aController.
	topView
		addSubView: textView
		in: (0@0.4 extent: 1.0@0.6)
		borderWidth: 1.
	topView controller open! !

!BrowserView class methodsFor: 'obsolete: creation'!

openListBrowserOn: aCollection label: labelString
	"Create and schedule a browser on the collection of messages aCollection.  Label the topview labelString."

	self openListBrowserOn: aCollection label: labelString initialSelection: nil!

openListBrowserOn: aCollection {Collection of: String}
	label: label {String}
	initialSelection: pattern {String default: nil}
	"Create and schedule a browser on the collection of messages 
	aCollection. Label the topview labelString. If the collection is empty, 
	print -Nobody- in the System Transcript."

	(EnumerateMethods
		make: (aCollection collect: [:m {String} | (MethodRep make: m)])
		with: 'Stale: ', label
		with: pattern)
			browse! !