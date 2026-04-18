'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:06 pm'!

STDocumentWindowModel subclass: #STPassageWindowModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!



!STPassageWindowModel methodsFor: 'windowing'!

{void} attachPanesTo: top {StandardSystemView} below: line {Float}
	"attach passage and link panes to the top view"
	top addSubView: (FMVCScrolledView make: self window documentBuilding)
		in: (0@line corner: 0.6@1)
		borderWidth: 1.
	top addSubView: (FMVCScrolledView make: self window referencesBuilding)
		in: (0.6@line corner: 1@1)
		borderWidth: 1! !

!STPassageWindowModel methodsFor: 'create'!

create: window {WindowModel}
	super create: window! !

!STPassageWindowModel methodsFor: 'menus'!

yellowButtonMenu
	^PopUpMenu longForm:
			'(save as [saveAs]
			change description [setDescription])
			(link format:
				(short [shortLinkFormat]
				two line [twoLineFormat]
				readers [readerLinkFormat]
				full [fullLinkFormat])
			(Link/Sensor creator [linkMaker])
			(Fe:
				(Edit:
					(Undo [undo]
					 Redo [redo]
					 Trace Forward [traceForward]
					 Trace Back [traceBack]
					 Move [move]
					 Cut [cut]
					 Paste [paste]
					 Clear [clear]
					 SelectAll [selectAll]
					 ItemSelect File Links? [itemSelectFileLinks]
					)
				
				File:
					( New [new]
					Open [open]
					Close [close]
					Save As [saveAs]
					Revert To Saved [revertToSaved]
					Rename [rename]
					Delete:
						( Bullshit Delete:
							( Item [bullshitDeleteItem]
							)	
						  Delete Document: 
						  ( Previous Versions [previousVersionsDocument]
						  	  This Versions [thisVersionDocument]
						  	  All Versions [allVersionsDocument]
						  	  All but this Version [allButThisVersionDocument]
						  	 )
						  Delete References:
						  	( Previous Versions [previousVersionsReferences:]
						  	  This Versions [thisVersionReferences:]
						  	  All Versions [allVersionsReferences:]
						  	  All but this Version [allButThisVersionReferences:]
						  	 )
						  Delete Links:
						  	( Delete Links ... [DeleteLinks]
						  	)
						)
					Export [export]
					Import ... [import]
					)
				
				Preferences:
					(Experimental:
						(Item [itemExperimental]
						)
					
					Random:
						( New Inclusion List [newInclusionList]
						  Contain Selection Item [containSelectionItem]
						  Convert Passage to IL [convertPassageToIL]
						  Reference Selection [referenceSelection]
						  Edit Filters [editFilters]
						)
					
					Debugging:
						(Item [debuggingItem]
						)
					
					Settings:
						(Password [password]
						 Filter [filter]
						 Link Types [linkTypes]
						 Groups [groups]
						)
					)
			
				Arrange:
					(Trailing WIndows:
						( Depth 1[depth1]
						  Depth 2 [depth2]
						  Depth 3 [depth3]
						  Depth 4 [depth4]
						  Depth 5 [depth5]
						  Infinity [infinity]
						)
					
					Link Display:
						(Edge [edge]
						 Panel [panel]
						 End [end]
						)
					
					Version Style:
						(Walkers Style [walkersStyle]
						 Change Bars [changeBars]
						Parallel Text Face [parallelTextFace]
						 Mark Up [markUp]
					
					Expand Headlines [expandHeadlines]
					Collapse Headlines [collapseHeadlines]
					Show Headlines [showHeadlines]
					Hide Headlines [hideHeadlines]
					Show Reference Status Bar [showReferenceStatusBar]
					Hide Reference Status Bar [hideReferenceStatusBar]
					)
				Create:
					(New Passage:
						( Refuted By Refutes [refutedByRefutes]
						 Refutes Refuted By [refutesRefutedBy]
						 Cited by Cites [citedByCites]
						 Cites Cited by [citesCitedby]
						)
					New Composition:
					 Refuted By Refutes [refutedByRefutes2]
						 Refutes Refuted By [refutesRefutedBy2]
						 Cited by Cites [citedByCites2]
						 Cites Cited by [citesCitedby2]
						)
					
					New Sensor :
						( Item [newSensorItem])
					
					New Link End [newLinkEnd])
				
				Compose:
					(Compose Link Ends:
						(Depth 1 [depth1Compose]
						 Depth 2 [depth2Compose]
						 Depth 3 [depth3Compose]
						)
					
					Include Link Ends:
						( Depth 1 [depth1IncludeLinkEnds]
						 Depth 2 [depth2IncludeLinkEnds]
						 Depth 3 [depth3IncludeLinkEnds]
						)
					Include Target [includeTarget]
					Switch to Containment [switchToContainment]
					Switch to Reference [switchToReference]
					)
				Formats:
					(Font Marcs:
						(Font:
							(Chicago [chicagoFontMarcs]
							 Geniva [genivaFontMarcs]
							 Courier [courierFontMarcs]
							 )
						Size:
							(9 [size9Marcs]
							 10 [size10Marcs]
							 12 [size12Marcs]
							 14 [size14Marcs]
							)
						Style:
							(Bold [boldStyleMarcs]
							 Italic [italicStyleMarcs]
							 Underline [underlineStyleMarcs]
							)
						)
						Font:
							(Font ... [fontPanel]
							Larger [larger]
							Smaller [smaller]
							Heavier [heavier]
							Lighter [lighter])
						
						
					
					Paragraph Style [paragraphStyle]
					DocumentStyle:
					 	 ( foo [fooDocumentStyle]
					 	 )
					 
					 Paragraph Styles ... [paragraphStyles]
					)
				
				Print... [printPanel]
				Font ...  [fontPanel]
				 
				Comparison:
					(Item [comparisonItem]
					)
				
				Hide [Hide]
				Quit [Quit]))
					
			'
		shortForm:
			'(save as [saveAs]
			change description [setDescription])
			(link format:
				(short [shortLinkFormat]
				two line [twoLineFormat]
				readers [readerLinkFormat]
				full [fullLinkFormat])
			(Link/Sensor creator [linkMaker])
			(Fe:
				(Edit:
					(Undo [undo]
					 Redo [redo]
					 Trace Forward [traceForward]
					 Trace Back [traceBack]
					 Move [move]
					 Cut [cut]
					 Paste [paste]
					 Clear [clear]
					 SelectAll [selectAll]
					 ItemSelect File Links? [itemSelectFileLinks]
					)
				
				File:
					( New [new]
					Open [open]
					Close [close]
					Save As [saveAs]
					Revert To Saved [revertToSaved]
					Rename [rename]
					Delete:
						( Bullshit Delete:
							( Item [bullshitDeleteItem]
							)	
						  Delete Document: 
						  ( Previous Versions [previousVersionsDocument]
						  	  This Versions [thisVersionDocument]
						  	  All Versions [allVersionsDocument]
						  	  All but this Version [allButThisVersionDocument]
						  	 )
						  Delete References:
						  	( Previous Versions [previousVersionsReferences:]
						  	  This Versions [thisVersionReferences:]
						  	  All Versions [allVersionsReferences:]
						  	  All but this Version [allButThisVersionReferences:]
						  	 )
						  Delete Links:
						  	( Delete Links ... [DeleteLinks]
						  	)
						)
					Export [export]
					Import [import]
					)
				
				Preferences:
					(Experimental:
						(Item [itemExperimental]
						)
					
					Random:
						( New Inclusion List [newInclusionList]
						  Contain Selection Item [containSelectionItem]
						  Convert Passage to IL [convertPassageToIL]
						  Reference Selection [referenceSelection]
						  Edit Filters [editFilters]
						)
					
					Debugging:
						(Item [debuggingItem]
						)
					
					Settings:
						(Password [password]
						 Filter [filter]
						 Link Types [linkTypes]
						 Groups [groups]
						)
					)
			
				Arrange:
					(Trailing WIndows:
						( Depth 1[depth1]
						  Depth 2 [depth2]
						  Depth 3 [depth3]
						  Depth 4 [depth4]
						  Depth 5 [depth5]
						  Infinity [infinity]
						)
					
					Link Display:
						(Edge [edge]
						 Panel [panel]
						 End [end]
						)
					
					Version Style:
						(Walkers Style [walkersStyle]
						 Change Bars [changeBars]
						Parallel Text Face [parallelTextFace]
						 Mark Up [markUp]
					
					Expand Headlines [expandHeadlines]
					Collapse Headlines [collapseHeadlines]
					Show Headlines [showHeadlines]
					Hide Headlines [hideHeadlines]
					Show Reference Status Bar [showReferenceStatusBar]
					Hide Reference Status Bar [hideReferenceStatusBar]
					)
				Create:
					(New Passage:
						( Refuted By Refutes [refutedByRefutes]
						 Refutes Refuted By [refutesRefutedBy]
						 Cited by Cites [citedByCites]
						 Cites Cited by [citesCitedby]
						)
					New Composition:
					 Refuted By Refutes [refutedByRefutes2]
						 Refutes Refuted By [refutesRefutedBy2]
						 Cited by Cites [citedByCites2]
						 Cites Cited by [citesCitedby2]
						)
					
					New Sensor :
						( Item [newSensorItem])
					
					New Link End [newLinkEnd])
				
				Compose:
					(Compose Link Ends:
						(Depth 1 [depth1Compose]
						 Depth 2 [depth2Compose]
						 Depth 3 [depth3Compose]
						)
					
					Include Link Ends:
						( Depth 1 [depth1IncludeLinkEnds]
						 Depth 2 [depth2IncludeLinkEnds]
						 Depth 3 [depth3IncludeLinkEnds]
						)
					Include Target [includeTarget]
					Switch to Containment [swithcToContainment]
					Switch to Reference [switchToReference]
					)
				Formats:
					(Font Marcs:
						(Font:
							(Chicago [chicagoFontMarcs]
							 Geniva [genivaFontMarcs]
							 Courier [courierFontMarcs]
							 )
						Size:
							(9 [size9Marcs]
							 10 [size10Marcs]
							 12 [size12Marcs]
							 14 [size14Marcs]
							)
						Style:
							(Bold [boldStyleMarcs]
							 Italic [italicStyleMarcs]
							 Underline [underlineStyleMarcs]
							)
						)
						(Font:
							Font ... [fontPanel]
							Larger [larger]
							Smaller [smaller]
							Heavier [heavier]
							Lighter [lighter]
						)
						
					
					Paragraph Style [paragraphStyle]
					DocumentStyle:
					 	 ( foo [fooDocumentStyle]
					 	 )
					 
					 Paragraph Styles ... [paragraphStyles]
					)
				
				Print... [printPanel]
				Font  [fontPanel]
				 
				Comparison:
					(Item [comparisonItem]
					)
				
				Hide [Hide]
				Quit [Quit]))
					
			'!

yellowButtonMenusaved
	^PopUpMenu longForm:
			'(save as [saveAs]
			change description [setDescription])
			(link format:
				(short [shortLinkFormat]
				two line [twoLineFormat]
				readers [readerLinkFormat]
				full [fullLinkFormat])
			(Link/Sensor creator [linkMaker])'
		shortForm:
			'(save as [saveAs]
			change description [setDescription])
			(link format:
				(short [shortLinkFormat]
				two line [twoLineFormat]
				readers [readerLinkFormat]
				full [fullLinkFormat])
			(Link/Sensor creator [linkMaker])'! !