
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("CheckOutCleaningCount") Then
		SelCheckOutCleaningCount = Parameters.CheckOutCleaningCount;	
	Else
		SelCheckOutCleaningCount = 0;	
	EndIf;
	If Parameters.Property("RegularCleaningCount") Then
		SelRegularCleaningCount = Parameters.RegularCleaningCount;	
	Else
		SelRegularCleaningCount = 0;	
	EndIf;
	If Parameters.Property("RepairEndCleaningCount") Then
		SelRepairEndCleaningCount = Parameters.RepairEndCleaningCount;	
	Else
		SelRepairEndCleaningCount = 0;	
	EndIf;
	If Parameters.Property("VacantRoomCleaningCount") Then
		SelVacantRoomCleaningCount = Parameters.VacantRoomCleaningCount;	
	Else
		SelVacantRoomCleaningCount = 0;	
	EndIf;
	If Parameters.Property("OtherOperationsCount") Then
		SelOtherOperationsCount = Parameters.OtherOperationsCount;	
	Else
		SelOtherOperationsCount = 0;	
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion    

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionExecute(pCommand)
	Close(New Structure("CheckOutCleaningCount, RegularCleaningCount, RepairEndCleaningCount, VacantRoomCleaningCount, OtherOperationsCount",
						 SelCheckOutCleaningCount, SelRegularCleaningCount, SelRepairEndCleaningCount, SelVacantRoomCleaningCount, SelOtherOperationsCount));
EndProcedure // ActionExecute

#EndRegion
