
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pLanguageCode	 - CatalogRef.Languages	 - Ref
//
Procedure UpdateCountriesList(pLanguageCode) Export
	// Language code
	vLanguageCode = TrimAll(pLanguageCode);
	If IsBlankString(vLanguageCode) Then
		vLanguageCode = "Ru";
	EndIf;
	
	// Archive with country flags
	vFlagsDir = cmTempFilesDir();
	vArchiveName = vFlagsDir + "flags.zip";
	Try
		vFile = New File(vArchiveName);
		If Not tcCommonFunctionOnClientServer.cmExists(vFile) Or Not vFile.IsFile() Then
			Catalogs.Countries.GetTemplate("Flags").Write(vArchiveName);
			// Check that file is copied successfully
			vFile = New File(vArchiveName);
			If tcCommonFunctionOnClientServer.cmExists(vFile) And vFile.IsFile() And vFile.Size() > 0 Then
				// Unzip pngs from archive
				vArchive = New ZipFileReader(vArchiveName);
				vArchive.ExtractAll(vFlagsDir, ZIPRestoreFilePathsMode.DontRestore);
				vArchive.Close();
				// Delete archive
				DeleteFiles(vArchiveName);
			EndIf;
		EndIf;
	Except
	EndTry;
	
	// Do processing  
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vCountriesList = Catalogs.Countries.GetTemplate("CountriesList" + vLanguageCode);
		vCountriesCount = vCountriesList.TableHeight - 1;
		For vInt = 2 To (vCountriesCount + 1) Do
			vCountryCode = Int(Number(vCountriesList.Area(vInt, 1, vInt, 1).Text));
			vCountryRef = Catalogs.Countries.FindByCode(vCountryCode);
			If ValueIsFilled(vCountryRef) Then
				vCountryObj = vCountryRef.GetObject();
			Else
				vCountryObj = Catalogs.Countries.CreateItem();
				vCountryObj.Code = vCountryCode;
			EndIf;
			
			vCountryObj.Description = TrimAll(vCountriesList.Area(vInt, 2, vInt, 2).Text);
			vCountryObj.ISOCode = TrimAll(vCountriesList.Area(vInt, 3, vInt, 3).Text);
			vCountryObj.ISOCode3 = TrimAll(vCountriesList.Area(vInt, 4, vInt, 4).Text);
			vIsVisaNecessary = Upper(TrimAll(vCountriesList.Area(vInt, 5, vInt, 5).Text));
			vCountryObj.IsVisaNecessaryForEntrance = ?(vIsVisaNecessary = "ДА", True, False);
			vLanguageCode = Upper(TrimAll(vCountriesList.Area(vInt, 6, vInt, 6).Text));
			If vLanguageCode = "EN" Then
				vCountryObj.Language = Catalogs.Languages.EN;
			ElsIf vLanguageCode = "RU" Then
				vCountryObj.Language = Catalogs.Languages.RU;
			EndIf;
			vFlagFilePath = vFlagsDir + lower(TrimAll(vCountryObj.ISOCode)) + ".png";
			vFlagFile = New File(vFlagFilePath);
			If tcCommonFunctionOnClientServer.cmExists(vFlagFile) Then
				vPict = New Picture(vFlagFilePath, False);
				vCountryObj.Flag = New ValueStorage(vPict);
			EndIf;

			vCountryObj.Write();
		EndDo;
		CommitTransaction();
	Except       
		RollbackTransaction();
		vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
		Raise vErrorDescription;
	EndTry;
EndProcedure // UpdateCountriesList

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, , pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
