'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:48 pm'!

SwitchView subclass: #BooleanView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'!
BooleanView comment:
'BooleanView is a "pluggable" view of a Boolean value. The notion of pluggable views is an experiment in user interface design. The idea is to provide a view which can be plugged onto any object, rather than having to define a new subclass specific to every kind of object which needs to be viewed. The chief mechanism is a set of selectors, which can be thought of as an adaptor to convert the generic textView operations (such as interrogateModel) into model-specific operations (such as metaclassSelected).  See the creation messages in the class for an explication of the various parameters. Browse senders of the creation messages in the class for examples in the system.'!


!BooleanView methodsFor: 'updating'!

interrogateModel
	^ (model perform: selector) = arguments first!

update: aspect
	aspect == selector ifTrue: [super update: aspect]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BooleanView class
	instanceVariableNames: ''!


!BooleanView class methodsFor: 'instance creation'!

on: model aspect: aspect label: label change: changeSel value: onValue
	"Create a 'pluggable' (see class comment) switchView viewing anObject.
	aspect is sent to read the current boolean value in the model.
		It is also used as the changed: parameter for this view.
	changeSel is sent to inform anObject of new boolean value for the model."
	| view args |
	view _ self new.
	view model: model.
	view selector: aspect; arguments: (args _ Array with: onValue).
	view controller selector: changeSel; arguments: args.
	view label: label asParagraph.
	^view! !