'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:14 pm'!

XnExecutor subclass: #CloseExecutor
	instanceVariableNames: ''
	classVariableNames: '
		FDArray {Int32Array} 
		FileDescriptorHolders {WeakPtrArray} '
	poolDictionaries: ''
	category: 'Xanadu-gchooks'!
CloseExecutor comment:
'This executor manages objects that need to close file descriptors on finalization.'!

(CloseExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!CloseExecutor methodsFor: 'protected: create'!

create
	super create! !

!CloseExecutor methodsFor: 'invoking'!

{void} execute: estateIndex {Int32}
	| fd {Int32} |
	fd := FDArray intAt: estateIndex.
	fd ~= -1 ifTrue: [
		[fd close] smalltalkOnly.
		'close((int)fd);' translateOnly.
		FDArray at: estateIndex storeInt: -1]! !

!CloseExecutor methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CloseExecutor class
	instanceVariableNames: ''!

(CloseExecutor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!CloseExecutor class methodsFor: 'accessing'!

{void} registerHolder: holder {Heaper} with: fd {Int32}
	| slot {Int32} |
	FDArray == NULL ifTrue: [
		| exec {XnExecutor} |
		FDArray := Int32Array make: 32.
		exec := CloseExecutor create.
		FileDescriptorHolders := WeakPtrArray make: exec with: 32].
	slot := FileDescriptorHolders indexOf: NULL.
	slot == -1 ifTrue: [
		slot := FDArray count.
		FDArray := (FDArray copyGrow: 16) cast: Int32Array.
		FileDescriptorHolders := (FileDescriptorHolders copyGrow: 16) cast: WeakPtrArray].
	FDArray at: slot storeInt: fd.
	FileDescriptorHolders at: slot store: holder.!

{void} unregisterHolder: holder {Heaper} with: fd {Int32}
	| slot {Int32} |
	slot := FileDescriptorHolders indexOfEQ: holder.
	[slot ~= -1 and: [slot < FDArray count and: [(FDArray intAt: slot) ~= fd]]] whileTrue: [
		slot := FileDescriptorHolders indexOfEQ: holder with: slot + 1].
	(slot == -1 or: [(FDArray intAt: slot) ~= fd]) ifTrue: [
		Heaper BLAST: #SanityViolation].
	FileDescriptorHolders at: slot store: NULL.
	FDArray at: slot storeInt: -1.! !

!CloseExecutor class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	FDArray := NULL.
	FileDescriptorHolders := NULL! !