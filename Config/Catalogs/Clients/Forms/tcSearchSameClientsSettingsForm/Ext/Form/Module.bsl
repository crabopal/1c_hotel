
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("SelLastName") Then
		SelLastName = Parameters.SelLastName;
	EndIf;
	If Parameters.Property("SelFirstName") Then
		SelFirstName = Parameters.SelFirstName;
	EndIf;
	If Parameters.Property("SelSecondName") Then
		SelSecondName = Parameters.SelSecondName;
	EndIf;
	If Parameters.Property("SelDateOfBirth") Then
		SelDateOfBirth = Parameters.SelDateOfBirth;
	EndIf;
	If Parameters.Property("SelIdentityDocumentNumber") Then
		SelIdentityDocumentNumber = Parameters.SelIdentityDocumentNumber;
	EndIf;
	If Parameters.Property("SelIdentityDocumentSeries") Then
		SelIdentityDocumentSeries = Parameters.SelIdentityDocumentSeries;
	EndIf;
	If Parameters.Property("SelPhone") Then
		SelPhone = Parameters.SelPhone;
	EndIf;
	If Parameters.Property("SelEMail") Then
		SelEMail = Parameters.SelEMail;
	EndIf;
	ByLastName = True;
	ByFirstName = True;
	BySecondName = True;
	ByDateOfBirth = True;
	ByPassportNumber = False;
	ByPhone = False;
	ByEMail = False;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DoSearch(Command)
	ActionSearchSameClientsAtServer();
	If SelClientsList.Count() = 0 Then
		ShowMessageBox( , NStr("en='Same clients were not found!';ru='Одинаковых карточек клиентов не найдено!';de='Same clients were not found!'"));
	Else
		ShowMessageBox( , NStr("en='Same clients found count is ';ru='Одинаковых карточек клиентов найдено: ';de='Same clients found count is '") + Format(SelClientsList.Count(), "ND=17; NFD=0; NZ=; NG="));
		Notify("SearchSameClients.Result", SelClientsList, FormOwner);
		Close();
	EndIf;
EndProcedure // DoSearch

#EndRegion    

#Region Private
			  
// -----------------------------------------------------------------------------
&AtServer
Procedure ActionSearchSameClientsAtServer()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AllClients.Ref AS Ref,
	|	AllClients.FullName AS FullName,
	|	AllClients.DateOfBirth AS DateOfBirth
	|FROM
	|	Catalog.Clients AS AllClients
	|		INNER JOIN (SELECT " + 
	?(ByLastName, "Clients.LastName AS LastName, ", "") + 
	?(ByFirstName, "Clients.FirstName AS FirstName, ", "") +  
	?(BySecondName, "Clients.SecondName AS SecondName, ", "") + 
	?(ByDateOfBirth, "Clients.DateOfBirth AS DateOfBirth, ", "") + 
	?(ByPassportNumber, "Clients.IdentityDocumentSeries AS IdentityDocumentSeries, ", "") + 
	?(ByPassportNumber, "Clients.IdentityDocumentNumber AS IdentityDocumentNumber, ", "") + 
	?(ByPhone, "Clients.Phone AS Phone, ", "") + 
	?(ByEMail, "Clients.EMail AS EMail, ", "") + "
	|			1 AS DummyColumn,
	|			COUNT(Clients.Ref) AS Counter
	|		FROM
	|			Catalog.Clients AS Clients
	|		WHERE
	|			(NOT Clients.IsFolder)
	|			AND (NOT Clients.DeletionMark)
	|		
	|		GROUP BY " + 
	?(ByLastName, "Clients.LastName, ", "") + 
	?(ByFirstName, "Clients.FirstName, ", "") + 
	?(BySecondName, "Clients.SecondName, ", "") + 
	?(ByDateOfBirth, "Clients.DateOfBirth, ", "") + 
	?(ByPassportNumber, "Clients.IdentityDocumentSeries, ", "") + 
	?(ByPassportNumber, "Clients.IdentityDocumentNumber, ", "") + 
	?(ByPhone, "Clients.Phone, ", "") + 
	?(ByEMail, "Clients.EMail, ", "") + "
	|			1		
	|		HAVING
	|			COUNT(Clients.Ref) > 1) AS SameClients
	|		ON TRUE " + 
	?(ByLastName, "AND (SameClients.LastName = AllClients.LastName) ", "") + 
	?(ByFirstName, "AND (SameClients.FirstName = AllClients.FirstName) ", "") + 
	?(BySecondName, "AND (SameClients.SecondName = AllClients.SecondName) ", "") + 
	?(ByDateOfBirth, "AND (SameClients.DateOfBirth = AllClients.DateOfBirth AND AllClients.DateOfBirth <> &qEmptyDate) ", "") + 
	?(ByPassportNumber, "AND (SameClients.IdentityDocumentSeries = AllClients.IdentityDocumentSeries) ", "") + 
	?(ByPassportNumber, "AND (SameClients.IdentityDocumentNumber = AllClients.IdentityDocumentNumber AND AllClients.IdentityDocumentNumber <> &qEmptyString) ", "") + 
	?(ByPhone, "AND (SameClients.Phone = AllClients.Phone AND AllClients.Phone <> &qEmptyString) ", "") + 
	?(ByEMail, "AND (SameClients.EMail = AllClients.EMail AND AllClients.EMail <> &qEmptyString) ", "") + "
	|WHERE " + 
		?(IsBlankString(TrimR(SelLastName)), "", "AllClients.LastName LIKE &qLastName AND ") + 
		?(IsBlankString(TrimR(SelFirstName)), "", "AllClients.FirstName LIKE &qFirstName AND ") + 
		?(IsBlankString(TrimR(SelIdentityDocumentNumber)), "", "AllClients.IdentityDocumentNumber = &qIdentityDocNumber AND ") + 
		?(IsBlankString(TrimR(SelIdentityDocumentSeries)), "", "AllClients.IdentityDocumentSeries = &qIdentityDocSeries AND ") + 
		?(IsBlankString(TrimR(SelSecondName)), "", "AllClients.SecondName LIKE &qSecondName AND ") + 
		?(IsBlankString(TrimR(SelPhone)), "", "AllClients.Phone LIKE &qPhone AND ") + 
		?(IsBlankString(TrimR(SelEMail)), "", "AllClients.EMail LIKE &qEMail AND ") + 
		?(ValueIsFilled(SelDateOfBirth), "AllClients.DateOfBirth = &qDateOfBirth AND ", "") + "
	|(NOT AllClients.DeletionMark) AND 
	|(NOT AllClients.IsFolder)";
	vQry.SetParameter("qLastName", TrimR(SelLastName)+"%");
	vQry.SetParameter("qFirstName", TrimR(SelFirstName)+"%");
	vQry.SetParameter("qSecondName", TrimR(SelSecondName)+"%");
	vQry.SetParameter("qIdentityDocNumber", TrimR(SelIdentityDocumentNumber));
	vQry.SetParameter("qIdentityDocSeries", TrimR(SelIdentityDocumentSeries));
	vQry.SetParameter("qPhone", "%"+TrimR(SelPhone)+"%");
	vQry.SetParameter("qEMail", "%"+TrimR(SelEMail)+"%");
	vQry.SetParameter("qDateOfBirth", SelDateOfBirth);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qEmptyString", "");
	vClients = vQry.Execute().Unload();
	If vClients.Count() > 0 Then
		SelClientsList.LoadValues(vClients.UnloadColumn("Ref"));
	Else
		SelClientsList.Clear();
	EndIf;
EndProcedure // ActionSearchSameClientsAtServer

#EndRegion
