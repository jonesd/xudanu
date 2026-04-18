'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:01 pm'!

Heaper subclass: #MailIndex
	instanceVariableNames: '
		documentInternal {XuText}
		sortKeys {IntegerTable}
		displayKeys {IntegerTable}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-import'!

(MailIndex getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!MailIndex methodsFor: 'create'!

create: sortKeysArg {IntegerTable} 
	super create.
	[TapestryAppModel , KeyMaster] USES.
	documentInternal _ ((Application fluidGet user cast: UserModel) keyMaster makeEmptyWaldo: (Sequence string: 'XuText') with: NULL with: true)
				cast: XuText.
				"documentInternal _ (((((Application fluidGet user) cast: UserModel) 
	keyMaster) makeWaldo: (Sequence string: 'XuText')  with: NULL with: true) cast: XuText )."
	sortKeys _ sortKeysArg.
	displayKeys _ sortKeysArg!

create: sortKeysArg {IntegerTable} with: displayKeysArg {IntegerTable} 

	super create.
	[KeyMaster] USES.
	documentInternal _ ((Application fluidGet user cast: UserModel) keyMaster makeEmptyWaldo: (Sequence string: 'XuText') with: NULL with: true)
				cast: XuText.
	sortKeys _ sortKeysArg.
	displayKeys _ displayKeysArg! !

!MailIndex methodsFor: 'store'!

{void} store: item{MailItem}
 
"store the item in the index , this means cons up a piece of text to represent it and insert that into the index and link it to the document, presumably the DocumentModel is the appropriate thing for this"
| text {UInt8Array} putAt {IntegerVar} |
 
	  
	putAt _ IntegerVar0.
	text _ item consUpText: displayKeys.
	[[documentInternal insert: IntegerVar0 with: (MuWordArray make.charVector: (text  gutsOf basicCast: #char star))]
		valueNowOrOnUnwindDo:
			(UInt8Array bomb.ReleaseGuts: text)] translateOnly.
	[documentInternal insert: IntegerVar0 with: (MuWordArray make.charVector: text  asString).] smalltalkOnly.
	XuLink make: documentInternal keyMaster
		with: (ImmuSet make with: (LinkEnd
			make: documentInternal keyMaster
			with: (IntegerRegion make: putAt with: ( text count ))
			with: documentInternal))
		with: (XuText make: documentInternal keyMaster
			with: 'jump') 
		with: ( ImmuSet make  with: (LinkEnd
			make: documentInternal keyMaster
			with: (item document cast: PassageModel) xuText))
		with: (XuText make: documentInternal keyMaster
			with: 'junk')
		with:( Vend getLinkTypeID:  ( UInt8Array string: 'jump')  )  .! !

!MailIndex methodsFor: 'accessing'!

{XuText} document 
	^documentInternal! !

!MailIndex methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MailIndex class
	instanceVariableNames: ''!

(MailIndex getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!MailIndex class methodsFor: 'pseudoconstructors'!

make:  sortKeysArg {IntegerTable}  
	^self create:  sortKeysArg!

make:  sortKeysArg {IntegerTable} with: displayKeysArg {IntegerTable}
	^self create:  sortKeysArg   with: displayKeysArg! !