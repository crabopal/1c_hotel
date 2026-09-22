
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Filter by hotel
	If Not Parameters.Filter.Property("Hotel") Then		
		vArray = New Array;
		vArray.Add(SessionParameters.CurrentHotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel", vArray);
	Else
		vArray = New Array;   
		If ValueIsFilled(Parameters.Filter.Hotel) Then
			vArray.Add(Parameters.Filter.Hotel);		  
		Else
			vArray.Add(SessionParameters.CurrentHotel);		
		EndIf; 
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel", vArray);
	EndIf;
	// Filter by customer and contract
	vAgent = SessionParameters.CurrentUser.Customer;
	If ValueIsFilled(vAgent) Then
		Parameters.Filter.Insert("Customer", vAgent);
	Else	
		If Parameters.Filter.Property("Customer") And ValueIsFilled(Parameters.Filter.Customer) Then
			vCustArray = New Array;
			vCustArray.Add(Parameters.Filter.Customer);		
			vCustArray.Add(Catalogs.Customers.EmptyRef());
			Parameters.Filter.Insert("Customer", vCustArray);
		EndIf;	
		If Parameters.Filter.Property("Contract") And ValueIsFilled(Parameters.Filter.Contract) Then		
			vContrArray = New Array;
			vContrArray.Add(Parameters.Filter.Contract);		
			vContrArray.Add(Catalogs.Contracts.EmptyRef());
			Parameters.Filter.Insert("Contract", vContrArray);
		EndIf;	
	EndIf;
EndProcedure // OnCreateAtServer      

#EndRegion
