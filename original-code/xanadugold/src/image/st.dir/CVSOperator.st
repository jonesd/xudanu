'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:14 pm'!

Object subclass: #CVSOperator
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Browser'!

(CVSOperator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!CVSOperator methodsFor: 'accessing'!

{NOWAIT} cvsClass: cls {Class}
	"cls is necessarily a (non-meta) Class.  Apply this CVS operator to it and all methods contained within it"

	self subclassResponsibility!

{NOWAIT} cvsMethod: sel {Symbol} in: cls {Behavior}
	"Apply this CVS operator to this method"

	self subclassResponsibility!

{NOWAIT} cvsModule: cta {CxxTreeAssociation}
	"mod is an item in the CxxBrowser outline tree.  Apply this CVS operator to it and all classes & methods contained within it"

	self subclassResponsibility!

{NOWAIT} cvsProtocol: prot {Symbol} in: cls {Behavior}
	"Apply this CVS operator to all methods contained within this protocol"

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CVSOperator class
	instanceVariableNames: ''!

(CVSOperator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!CVSOperator class methodsFor: 'menu / creation'!

{CVSOperator | nil} fetchCheckout

	^CVSCheckout fetchNew!

{CVSOperator | nil} fetchCommit

	^CVSCommit fetchNew!

{CVSOperator | nil} fetchDiff

	^CVSDiff fetchNew!

{CVSOperator | nil} fetchFromMenu

	| sel {Symbol} |
	sel _ (PopUpMenu fromArray: #(
		('save'			fetchSave			'Xu: Save the selected item and all below it into our local CVS source tree (not the repository)')
		('load'			fetchLoad			'Xu: Load (or re-load) the selected item and all below it from our local CVS source tree')
		-
		('commit'		fetchCommit		'Xu: Commit the selected item and all below it to the repository.)
		('update'		fetchUpdate		'Xu: Update the selected item and all below it from the repository.)
		('checkout'	fetchCheckout	'Xu: ???')
		('diff'			fetchDiff			'Xu: Three way diff of my current state of the selected item and the repositories current state of the selected item against our common ancestor.')
		('log'			fetchLog			'Xu: ???')
		('revert'		fetchRevert		'Xu: Revert the selected item and all below it to the state in the repository (losing any private changes to them I may have done).'))) startUp.
		
	(sel	== nil or: [sel = 0]) ifTrue:
		[^nil].
	^self perform: sel!

{CVSOperator | nil} fetchLoad

	^CVSLoad fetchNew!

{CVSOperator | nil} fetchLog

	^CVSLog fetchNew!

{CVSOperator | nil} fetchRevert

	^CVSRevert fetchNew!

{CVSOperator | nil} fetchSave

	^CVSSave fetchNew!

{CVSOperator | nil} fetchUpdate

	^CVSUpdate fetchNew! !