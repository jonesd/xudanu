'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:30 pm'!

Thunk subclass: #SpareStageSpace
	instanceVariableNames: '
		myCruftedSnarfCount {Int32}
		myFlocksPerSnarf {Int32}'
	classVariableNames: '
		CruftedSnarfCount {Int32} 
		FlocksPerSnarf {Int32} '
	poolDictionaries: ''
	category: 'Xanadu-packer'!

(SpareStageSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!SpareStageSpace methodsFor: 'execute'!

{void} execute
	CruftedSnarfCount := myCruftedSnarfCount.
	FlocksPerSnarf := myFlocksPerSnarf.! !

!SpareStageSpace methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCruftedSnarfCount _ receiver receiveInt32.
	myFlocksPerSnarf _ receiver receiveInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: myCruftedSnarfCount.
	xmtr sendInt32: myFlocksPerSnarf.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SpareStageSpace class
	instanceVariableNames: ''!

(SpareStageSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!SpareStageSpace class methodsFor: 'smalltalk: init'!

linkTimeNonInherited
	CruftedSnarfCount := 7.
	FlocksPerSnarf := 100.! !

!SpareStageSpace class methodsFor: 'accessing'!

{Int32} cruftedSnarfsGuess
	^ CruftedSnarfCount!

{Int32} flocksPerSnarfGuess
	^ FlocksPerSnarf! !