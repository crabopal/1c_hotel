// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Filter.Property("Hotel") Then		
		vArray = New Array;
		vArray.Add(SessionParameters.CurrentHotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel", vArray);
	EndIf;	
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure ListOnGetDataAtServer(pItemName, pSettings, pRows)
	// Colors and other appearances
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		vSignAppearance = vRowValue.Appearance.Get("Type");
		If vSignAppearance <> Undefined Then
			vSignText = "";
			If vRowValue.Data["Type"] = AccountType.Active Then
				vSignText = NStr("en='Dt'; de='Dt'; ru='Дт'");
			ElsIf vRowValue.Data["Type"] = AccountType.Passive Then
				vSignText = NStr("en='Cr'; de='Kt'; ru='Кт'");
			EndIf;
			vSignAppearance.SetParameterValue("Text", vSignText);
		EndIf;
	EndDo;
EndProcedure // ListOnGetDataAtServer
