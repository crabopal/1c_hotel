
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	cmSetFormItemsStandarts(Items, Catalogs.ResourceTypes.GetTemplate("Template"));
EndProcedure

#EndRegion
