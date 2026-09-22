
#Region FormEventHandlers

// ------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Hotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(Hotel) Then
		Company = Hotel.Company;
	EndIf;
	EditProhibitedDate = BegOfDay(BegOfMonth(CurrentSessionDate()) - 1);
	ApplyFormAppearance();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// ------------------------------------------------------------------------------
&AtClient
Procedure TypeOfDateOnChange(pItem)
	ApplyFormAppearance();
EndProcedure // TypeOfDateOnChange

#EndRegion

#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------
&AtClient
Procedure SetDateChoosen(pCommand)
	If TypeOfDate = 1 Then
		If Not ValueIsFilled(Company) Then   
			vMsg = NStr("en='Company should be filled for this type of operation!'; ru='Для выполнения операции необходимо указать фирму!'; de='Kompanie sollte für diese Typ von Operation ausgefüllt werden!'");
			tcCommonFunctionOnClientServer.UserMessage(vMsg, , "Company");
			Return;
		EndIf;
		If Not tcOnServer.cmAccessRight("Edit", "Catalogs", "Companies") Then   
			vMsg = NStr("en='You have no rights for this operation!'; ru='Нет прав на это действие!'; de='Sie haben keine Rechte an dieser Aktion!'");
			tcCommonFunctionOnClientServer.UserMessage(vMsg, , "Hotel");
			Return;
		EndIf;
	Else
		If Not tcOnServer.cmIsInRole("RightsToChooseHotel") And Not tcOnServer.cmIsInRole("Administrator") Then      
			vMsg = NStr("en='You have no rights for this operation!'; ru='Нет прав на это действие!'; de='Sie haben keine Rechte an dieser Aktion!'");
			tcCommonFunctionOnClientServer.UserMessage(vMsg, , "Hotel");
			Return;
		EndIf;
	EndIf;
	SetDateChoosenAtServer();
	ShowMessageBox(, NStr("en='Success!'; ru='Успешно!'; de='Erfolgreich!'"));
	If TypeOfDate = 1 Then
		RepresentDataChange(Company, DataChangeType.Update);
	Else
		RepresentDataChange(Hotel, DataChangeType.Update);
	EndIf;
	RefreshDataRepresentation();
EndProcedure // SetDateChoosen

#EndRegion

#Region Private

// ------------------------------------------------------------------------------
&AtServer
Procedure ApplyFormAppearance()
	If TypeOfDate = 0 Then
		Items.Company.Visible = False;
		Items.CompanyEditProhibitedDate.Visible = False;
		Items.HotelEditProhibitedDate.Visible = True;
	Else
		Items.Company.Visible = True;
		Items.CompanyEditProhibitedDate.Visible = True;
		Items.HotelEditProhibitedDate.Visible = False;
	EndIf;
EndProcedure // ApplyFormAppearance

// ------------------------------------------------------------------------------
&AtServer
Procedure SetDateChoosenAtServer()
	If TypeOfDate = 1 Then
		vCompanyObj = Company.GetObject();
		vCompanyObj.EditProhibitedDate = EditProhibitedDate;
		vCompanyObj.Write();
	Else
		vHotelObj = Hotel.GetObject();
		vHotelObj.EditProhibitedDate = EditProhibitedDate;
		vHotelObj.Write();
	EndIf;
EndProcedure // SetDateChoosenAtServer

#EndRegion
