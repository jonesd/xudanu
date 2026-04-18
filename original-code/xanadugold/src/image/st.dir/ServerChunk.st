'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:34 pm'!

Heaper subclass: #ServerChunk
	instanceVariableNames: '
		myFluidSpace {char star}
		myEndingState {Int32}'
	classVariableNames: 'SecretEmulsion {Emulsion} '
	poolDictionaries: ''
	category: 'Xanadu-rcmain'!
ServerChunk comment:
'This is the superclass for all the Chunks.  Chunks represent pieces of the server that run for a while, then return control.  Subclasses include Listeners that wait for input.    When manually destroyed, this class flags itself for cleanup after any current
request is finished--myEnding state is alive, alive in request, destruction requested, and ready for destruction.'!

(ServerChunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!ServerChunk methodsFor: 'protected: accessing'!

{BooleanVar} destroyOKIfRequested
	(myEndingState == ServerChunk inRequestFlag or: [myEndingState == ServerChunk destroyRequestedFlag]) ifTrue: [
		myEndingState := ServerChunk destroyReadyFlag.
		^ true]
	ifFalse: [^false]!

{BooleanVar} destroyPending
	^ myEndingState == ServerChunk destroyRequestedFlag.!

{void} inRequest
	myEndingState := ServerChunk inRequestFlag.!

{void} notInRequest
	myEndingState == ServerChunk destroyRequestedFlag
		ifTrue: [myEndingState := ServerChunk destroyReadyFlag]
		ifFalse: [myEndingState == ServerChunk inRequestFlag ifTrue: [myEndingState := ServerChunk aliveFlag]]! !

!ServerChunk methodsFor: 'testing'!

{BooleanVar} shouldDestroy
	"Returns TRUE if this chunk wants to be deleted after deregistration."
	^ myEndingState == ServerChunk destroyReadyFlag! !

!ServerChunk methodsFor: 'accessing'!

{BooleanVar} execute
	"Attempt to execute another chunk.  Return whether there is more to be done."

	self subclassResponsibility.!

{char star} fluidSpace

	^myFluidSpace.!

{char star} fluidSpace: aFluidSpace {char star}

	^myFluidSpace _ aFluidSpace.! !

!ServerChunk methodsFor: 'protected: destruct'!

{void} destruct
	"ServerChunks are destroyed explicitly in the server loop."
	| saveChunk {ServerChunk} |
	(myFluidSpace ~~ NULL) ifTrue: [
		saveChunk _ CurrentChunk.
		CurrentChunk _ self.
		ServerChunk emulsion destructAll.
		CurrentChunk _ saveChunk.].
	ServerLoop removeChunk: self.
	ChunkCleaner beClean.
	super destruct.! !

!ServerChunk methodsFor: 'creation'!

create

	super create.
	myFluidSpace _ NULL.
	myEndingState := Int32Zero.!

{void} destroy
	(myEndingState == ServerChunk aliveFlag or: [myEndingState == ServerChunk destroyReadyFlag])
		ifTrue: [super destroy]
		ifFalse: [
			myEndingState == ServerChunk destroyRequestedFlag ifTrue: [Heaper BLAST: #AlreadyDestroyed].
			myEndingState := ServerChunk destroyRequestedFlag]! !

!ServerChunk methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ServerChunk class
	instanceVariableNames: ''!

(ServerChunk getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!ServerChunk class methodsFor: 'accessing'!

{Emulsion} emulsion
	[SecretEmulsion == nil ifTrue: [SecretEmulsion _ NULL]] smalltalkOnly.
	(SecretEmulsion == NULL) ifTrue: [
		SecretEmulsion _ ListenerEmulsion new create].
	^SecretEmulsion.! !

!ServerChunk class methodsFor: 'smalltalk: init'!

cleanupGarbage
	SecretEmulsion _ NULL!

linkTimeNonInherited
	ServerChunk defineGlobal: #CurrentChunk with: NULL.
	SecretEmulsion _ NULL.! !

!ServerChunk class methodsFor: 'protected: accessing'!

{Int32 INLINE} aliveFlag
	^ Int32Zero!

{Int32 INLINE} destroyReadyFlag
	^ 3!

{Int32 INLINE} destroyRequestedFlag
	^ 2!

{Int32 INLINE} inRequestFlag
	^ 1! !