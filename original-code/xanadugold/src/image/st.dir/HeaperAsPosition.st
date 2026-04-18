'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:29 pm'!

UnOrdered subclass: #HeaperAsPosition
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Unordered'!
HeaperAsPosition comment:
'A position in a HeaperSpace that represents the identity of some particular Heaper.  See class comment in HeaperSpace.'!

(HeaperAsPosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!HeaperAsPosition methodsFor: 'testing'!

{UInt32} actualHashForEqual

	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper} 
	self subclassResponsibility! !

!HeaperAsPosition methodsFor: 'accessing'!

{XnRegion INLINE} asRegion

	^HeaperRegion make.HeaperAsPosition: self!

{CoordinateSpace} coordinateSpace
	self subclassResponsibility!

{Heaper} heaper
	"Return the underlying Heaper whose identity (as a position) I 
	represent. 
	
	It is considered good form not to use this message. There is some 
	controversy as to whether it will go away in the future. If you 
	know of any good reason why it should stick around please let us 
	know."

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HeaperAsPosition class
	instanceVariableNames: ''!

(HeaperAsPosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!HeaperAsPosition class methodsFor: 'pseudo constructors'!

{HeaperAsPosition} make: heaper {Heaper}
	"Return a HeaperAsPosition which represents the identity of this Heaper.  The resulting HeaperAsPosition will strongly retain the original Heaper against garbage collection (though not of course against manual deletion).  See wimpyAsPosition"
	
	^StrongAsPosition create: heaper! !