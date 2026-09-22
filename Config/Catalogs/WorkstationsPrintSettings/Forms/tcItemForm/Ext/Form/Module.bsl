// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	PageSizeFillChoiceList();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintFormsListOnStartEdit(pItem, pNewRow, pClone)
	vCurRow = Items.PrintFormsList.CurrentData;
	If Not vCurRow = Undefined Then
		If pNewRow And Not pClone Then
			vCurRow.IsActive = True;
			vCurRow.PrintDirection = PredefinedValue("Enum.PrintDirections.Screen");
			vCurRow.PageOrientation = PredefinedValue("Enum.PageOrientations.Portrait");
			vCurRow.FitToPage = False;
			vCurRow.PrintScale = 100;
			vCurRow.Copies = 1;
			vCurRow.Collate = False;
			vCurRow.CopiesPerPage = PredefinedValue("Enum.CopiesPerPage.One");
			vCurRow.BlackAndWhite = False;
			vCurRow.TopMargin = 10;
			vCurRow.BottomMargin = 10;
			vCurRow.LeftMargin = 10;
			vCurRow.RightMargin = 10;
			vCurRow.HeaderSize = 10;
			vCurRow.FooterSize = 10;
		EndIf;
	EndIf;
EndProcedure // PrintFormsListOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintFormsListFileSaveCatalogStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	tcOnClientWorkWithFiles.cmChooseDirectoryOnClient("FileSaveCatalog", Items.PrintFormsList.CurrentData, False);
EndProcedure // PrintFormsListFileSaveCatalogStartChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure PageSizeFillChoiceList()
	vList = Items.PrintFormsListPageSize.ChoiceList;
	vList.Clear();
	vList.Add("Custom");
	vList.Add("Letter"); 
	vList.Add("Letter Small");
	vList.Add("Tabloid"); 
	vList.Add("Ledger"); 
	vList.Add("Legal"); 
	vList.Add("Statement");
	vList.Add("Executive"); 
	vList.Add("A3"); 
	vList.Add("A4");
	vList.Add("A4 Small");
	vList.Add("A5"); 
	vList.Add("B4"); 
	vList.Add("B5"); 
	vList.Add("Folio"); 
	vList.Add("Quarto"); 
	vList.Add("10x14"); 
	vList.Add("11x17"); 
	vList.Add("Note"); 
	vList.Add("Envelope #9"); 
	vList.Add("Envelope #10"); 
	vList.Add("Envelope #11"); 
	vList.Add("Envelope #12"); 
	vList.Add("Envelope #14"); 
	vList.Add("C size sheet"); 
	vList.Add("D size sheet"); 
	vList.Add("E size sheet"); 
	vList.Add("Envelope DL"); 
	vList.Add("Envelope C5"); 
	vList.Add("Envelope C3"); 
	vList.Add("Envelope C4");
	vList.Add("Envelope C6"); 
	vList.Add("Envelope C65"); 
	vList.Add("Envelope B4"); 
	vList.Add("Envelope B5"); 
	vList.Add("Envelope B6"); 
	vList.Add("Envelope"); 
	vList.Add("Envelope Monarch");
	vList.Add("6 3/4 Envelope"); 
	vList.Add("US Std Fanfold"); 
	vList.Add("German Std Fanfold");
	vList.Add("German Legal Fanfold");
	vList.Add("B4 (ISO)"); 
	vList.Add("Japanese Postcard");
	vList.Add("9x11"); 
	vList.Add("10x11"); 
	vList.Add("15x11"); 
	vList.Add("Envelope Invite");
	vList.Add("Letter Extra"); 
	vList.Add("Legal Extra"); 
	vList.Add("Tabloid Extra"); 
	vList.Add("A4 Extra"); 
	vList.Add("Letter Transverse"); 
	vList.Add("A4 Transverse"); 
	vList.Add("Letter Extra Transverse");
	vList.Add("Super A"); 
	vList.Add("Super B"); 
	vList.Add("Letter Plus"); 
	vList.Add("A4 Plus"); 
	vList.Add("A5 Transverse"); 
	vList.Add("B5 (JIS) Transverse"); 
	vList.Add("A3 Extra"); 
	vList.Add("A5 Extra"); 
	vList.Add("B5 (ISO) Extra"); 
	vList.Add("A2"); 
	vList.Add("A3 Transverse"); 
	vList.Add("A3 Extra Transverse"); 
	vList.Add("Japanese Double Postcard"); 
	vList.Add("A6"); 
	vList.Add("Japanese Envelope Kaku #2"); 
	vList.Add("Japanese Envelope Kaku #3"); 
	vList.Add("Japanese Envelope Chou #3"); 
	vList.Add("Japanese Envelope Chou #4"); 
	vList.Add("Letter Rotated"); 
	vList.Add("A3 Rotated"); 
	vList.Add("A4 Rotated"); 
	vList.Add("A5 Rotated"); 
	vList.Add("B4 (JIS) Rotated"); 
	vList.Add("B5 (JIS) Rotated"); 
	vList.Add("Japanese Postcard Rotated"); 
	vList.Add("Double Japanese Postcard Rotated");
	vList.Add("A6 Rotated"); 
	vList.Add("Japanese Envelope Kaku #2 Rotated"); 
	vList.Add("Japanese Envelope Kaku #3 Rotated"); 
	vList.Add("Japanese Envelope Chou #3 Rotated"); 
	vList.Add("Japanese Envelope Chou #4 Rotated"); 
	vList.Add("B6 (JIS)"); 
	vList.Add("B6 (JIS) Rotated"); 
	vList.Add("12x11"); 
	vList.Add("Japanese Envelope You #4"); 
	vList.Add("Japanese Envelope You #4 Rotated"); 
	vList.Add("P 16k"); 
	vList.Add("P 32k"); 
	vList.Add("P 32k(Big)"); 
	vList.Add("PRC Envelope #1"); 
	vList.Add("PRC Envelope #2"); 
	vList.Add("PRC Envelope #3"); 
	vList.Add("PRC Envelope #4"); 
	vList.Add("PRC Envelope #5"); 
	vList.Add("PRC Envelope #6"); 
	vList.Add("PRC Envelope #7"); 
	vList.Add("PRC Envelope #8"); 
	vList.Add("PRC Envelope #9"); 
	vList.Add("PRC Envelope #10"); 
	vList.Add("P 16k Rotated"); 
	vList.Add("P 32k Rotated"); 
	vList.Add("P 32kbig Rotated"); 
	vList.Add("PRC Envelope #1 Rotated"); 
	vList.Add("PRC Envelope #2 Rotated"); 
	vList.Add("PRC Envelope #3 Rotated"); 
	vList.Add("PRC Envelope #4 Rotated"); 
	vList.Add("PRC Envelope #5 Rotated"); 
	vList.Add("PRC Envelope #6 Rotated"); 
	vList.Add("PRC Envelope #7 Rotated"); 
	vList.Add("PRC Envelope #8 Rotated");
	vList.Add("PRC Envelope #9 Rotated"); 
	vList.Add("PRC Envelope #10 Rotated");
EndProcedure // PageSizeFillChoiceList
