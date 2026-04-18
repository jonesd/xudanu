'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:28 pm'!

FeDetector subclass: #FeStatusDetector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-detect'!
FeStatusDetector comment:
'Is notified of changes in the capability of a Work object.'!

(FeStatusDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeStatusDetector methodsFor: 'triggering'!

{void CLIENT} grabbed: work {FeWork} with: author {ID} with: reason {IntegerVar}
	"Essential. The Work has been grabbed, or regrabbed."
	
	self subclassResponsibility!

{void CLIENT} released: work {FeWork} with: reason {IntegerVar}
	"Essential. The revise capability of the Work has been lost."
	
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeStatusDetector class
	instanceVariableNames: ''!

(FeStatusDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeStatusDetector class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Int32 CLIENT INLINE} EDIT.U.PERMISSION.U.CHANGED
{Int32 CLIENT INLINE} KEYMASTER.U.CHANGED
{Int32 CLIENT INLINE} SIGNATURE.U.AUTHORITY.CHANGED
{void NOWAIT CLIENT} grabbed: work {PrWork} with: author {PrID} with: reason {PrInteger}
{void NOWAIT CLIENT} released: work {PrWork} with: reason {PrInteger}
"! !

!FeStatusDetector class methodsFor: 'constants'!

{Int32 CLIENT INLINE} EDIT.U.PERMISSION.U.CHANGED
	"The reason for the change was a change in the permissions required to edit the Work"
	
	^4!

{Int32 CLIENT INLINE} KEYMASTER.U.CHANGED
	"The reason for the change was a change in authority of the KeyMaster in the Work"
	
	^2!

{Int32 CLIENT INLINE} SIGNATURE.U.AUTHORITY.CHANGED
	"The reason for the change was a change in signature authority of the CurrentAuthor"
	
	^1! !