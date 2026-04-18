'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:27 pm'!

Heaper subclass: #PrimRemovedObject
	instanceVariableNames: ''
	classVariableNames: 'TheRemovedObject {Heaper} '
	poolDictionaries: ''
	category: 'Xanadu-primtab'!
PrimRemovedObject comment:
'A single instance of this exists as a marker for slots in PrimTables where entries have been removed.
This object lives on the GC heap to keep weak arrays happy'!

(PrimRemovedObject getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #EQ; add: #NO.GC; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!PrimRemovedObject methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimRemovedObject class
	instanceVariableNames: ''!

(PrimRemovedObject getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #EQ; add: #NO.GC; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!PrimRemovedObject class methodsFor: 'accessing'!

{Heaper wimpy INLINE} make
	
	^ TheRemovedObject! !

!PrimRemovedObject class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	TheRemovedObject _ PrimRemovedObject create.!

linkTimeNonInherited
	TheRemovedObject _ NULL! !