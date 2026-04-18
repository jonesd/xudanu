'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:14 pm'!

XnExecutor subclass: #DeleteExecutor
	instanceVariableNames: ''
	classVariableNames: '
		StorageArray {void vector star} 
		StorageHolders {WeakPtrArray} '
	poolDictionaries: ''
	category: 'Xanadu-gchooks'!
DeleteExecutor comment:
'This executor manages objects that need to release non-Heaper storage on finalization.'!

(DeleteExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!DeleteExecutor methodsFor: 'invoking'!

{void} execute: estateIndex {Int32}
	| storage {void star} |
	storage := StorageArray at: estateIndex.
	storage ~~ NULL ifTrue: [
		storage delete].
	StorageArray at: estateIndex put: NULL.! !

!DeleteExecutor methodsFor: 'protected: create'!

create
	super create! !

!DeleteExecutor methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DeleteExecutor class
	instanceVariableNames: ''!

(DeleteExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!DeleteExecutor class methodsFor: 'accessing'!

{void} registerHolder: holder {Heaper} with: storage {void star}
	| slot {Int32} |
	StorageArray == NULL ifTrue: [
		| exec {XnExecutor} |
		'DeleteExecutor::StorageArray = new void* [32];
		memset (DeleteExecutor::StorageArray, 0, 32 * sizeof(void*));' translateOnly.
		[StorageArray := PtrArray nulls: 32] smalltalkOnly.
		exec := DeleteExecutor create.
		StorageHolders := WeakPtrArray make: exec with: 32].
	slot := StorageHolders indexOf: NULL.
	slot == -1 ifTrue: [
		slot := StorageHolders count.
		'void ** newArray = new void* [slot + 16];
		memset(&newArray[slot], 0, 16 * sizeof(void*));
		MEMMOVE(newArray, DeleteExecutor::StorageArray, (int)slot);
		delete DeleteExecutor::StorageArray;
		DeleteExecutor::StorageArray = newArray;' translateOnly.
		[StorageArray := StorageArray copyGrow: 16] smalltalkOnly.
		StorageHolders := (StorageHolders copyGrow: 16) cast: WeakPtrArray].
	StorageArray at: slot put: storage.
	StorageHolders at: slot store: holder.!

{void} unregisterHolder: holder {Heaper} with: storage {void star}
	| slot {Int32} |
	slot := StorageHolders indexOfEQ: holder.
	[slot ~= -1 and: [slot < StorageHolders count and: [(StorageArray at: slot) ~~ storage]]] whileTrue: [
		slot := StorageHolders indexOfEQ: holder with: slot + 1].
	(slot == -1 or: [(StorageArray at: slot) ~~ storage]) ifTrue: [
		Heaper BLAST: #SanityViolation].
	StorageArray at: slot put: NULL.
	StorageHolders at: slot store: NULL.! !

!DeleteExecutor class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	StorageArray := NULL.
	StorageHolders := NULL.! !