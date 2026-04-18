'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:12 pm'!

ServerChunk subclass: #ExecutePromiseFile
	instanceVariableNames: '
		myReadName {char star}
		myWriteName {char star}
		myManager {PromiseManager NOCOPY}
		myConnection {Connection NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!
ExecutePromiseFile comment:
'Read client requests from one files and write the results to another file.'!

(ExecutePromiseFile getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!ExecutePromiseFile methodsFor: 'operate'!

{BooleanVar} execute
	"Execute the action defined by this thunk."

	myManager handleRequest.
	self thingToDo.  "Check whether the read file is Empty."
	^true! !

!ExecutePromiseFile methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartPromises: rcvr {Rcvr unused}
	| readStream {XnReadStream} writeStream {XnWriteStream} |
	readStream _ XnReadFile make: myReadName.
	writeStream _ XnWriteFile make: myWriteName.
	myManager _ PromiseManager make: (PairPortal make: readStream with: writeStream).
	myConnection _ Connection make: FeServer.  self thingToDo.  "This should be unnecessary."! !

!ExecutePromiseFile methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myReadName _ receiver receiveString.
	myWriteName _ receiver receiveString.
	self restartPromises: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendString: myReadName.
	xmtr sendString: myWriteName.! !