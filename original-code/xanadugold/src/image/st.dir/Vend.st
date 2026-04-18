'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:03 pm'!

Heaper subclass: #Vend
	instanceVariableNames: ''
	classVariableNames: '
		fontTableInternal {HashTable} 
		linkTypesInternal {HashTable} '
	poolDictionaries: ''
	category: 'Xanadu-vendor'!

(Vend getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Vend class
	instanceVariableNames: ''!

(Vend getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Vend class methodsFor: 'smalltalk: smalltalk initialization'!

linkTimeNonInherited
fontTableInternal _ NULL.
		linkTypesInternal _ NULL! !

!Vend class methodsFor: 'vending'!

{ID} getLinkTypeID: key {UInt8Array}
	| tmp {ID} km {KeyMaster} |

	[DocumentModel] USES.
	
	linkTypesInternal = NULL ifTrue:
		[fontTableInternal _ NULL.
		linkTypesInternal _   HashTable make.CoordinateSpace: SequenceSpace make.	
		km _ ((Application fluidGet user) cast: UserModel) keyMaster.
		linkTypesInternal
			at: (Sequence string: 'jump')
			introduce: (LinkTypeDescription linkType: km
									 with: (XuText make: km with.charVector: 'from')
									 with: (XuText make: km with.charVector: 'to'))].
	 tmp _ (linkTypesInternal fetch: (Sequence string: key)) cast: ID. 
	  
	^tmp! !