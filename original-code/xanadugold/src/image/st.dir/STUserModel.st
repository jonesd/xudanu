'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:08 pm'!

UserModel subclass: #STUserModel
	instanceVariableNames: '
		myPermissionsMenu {VariableModel of: PopUpMenu}
		myFiltersMenu {VariableModel of: PopUpMenu}
		myLinkTypesMenu {VariableModel of: PopUpMenu}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!

(STUserModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!STUserModel methodsFor: 'accessing'!

{VariableModel of: PopUpMenu} filtersMenu
	^myFiltersMenu!

{VariableModel of: PopUpMenu} linkTypesMenu
	^myLinkTypesMenu!

{VariableModel of: PopUpMenu} permissionsMenu
	^myPermissionsMenu! !

!STUserModel methodsFor: 'create'!

create: km {KeyMaster}
	super create: km.
	self setupLinkTypesMenu.
	myPermissionsMenu _ VariableModel make.
	myPermissionsMenu setValue: (PopUpTextMenu parseFromArray: #(('Xanadu') ('Hugh') ('Roger'))).
	"VariableTable2MenuSchnert create: self userDirectory
clubNames
		with: myPermissionsMenu
		with: [ :name {PackOBits} |
			(name convert: XuWordArray) asString]."
	
	myFiltersMenu _ VariableModel make.
	myFiltersMenu setValue: (PopUpTextMenu parseFromArray: #(('Links') ('Variants') ('HooHah'))).
	"ListModel2MenuSchnert create: self filters
		with: myFiltersMenu
		with: [ :filter {TapestryFilter} |
			(filter name asDataTable cast: XuWordArray) asString]"! !

!STUserModel methodsFor: 'private: setup'!

setupLinkTypesMenu

	myLinkTypesMenu := VariableModel make.
	myLinkTypesMenu setValue: (PopUpTextMenu parseFromArray: #(('biz') ('baz'))).
	"ListModel2MenuSchnert create: self linkTypes
		with: myLinkTypesMenu
		with: [ :id {ID} | | type {LinkTypeDescription} left {String} right {String} |
			type := LinkTypeDescription defaultDescription: self keyMaster with: id.
			left := (type leftLabel asDataTable cast: XuWordArray) asString.
			right := (type rightLabel asDataTable cast: XuWordArray) asString.
			left , ' ... ' , right , '
' , right , ' ... ' , left]."! !