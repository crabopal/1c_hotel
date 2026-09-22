
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	// Update tax rate if neccessary
	If ValueIsFilled(Object.Ref) Then
		vVATRateParams = cmGetVATRateParams(Object.Ref, CurrentSessionDate());
		If vVATRateParams.TaxRate <> Object.TaxRate Then
			Object.TaxRate = vVATRateParams.TaxRate;
			If vVATRateParams.NoVAT <> Object.NoVAT Then
				Object.NoVAT = vVATRateParams.NoVAT;
			EndIf;
			Modified = True;
		EndIf;
		If vVATRateParams.TaxGroup <> Object.TaxGroup And vVATRateParams.TaxGroup <> 0 Then
			Object.TaxGroup = vVATRateParams.TaxGroup;
			Modified = True;
		EndIf;
		If vVATRateParams.Description <> Object.Description And Not IsBlankString(vVATRateParams.Description) Then
			Object.Description = vVATRateParams.Description;
			Modified = True;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
