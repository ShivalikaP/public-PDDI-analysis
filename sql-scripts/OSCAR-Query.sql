
	--Script to Parse Map OSCAR Dataset to Drugbank
	--Added 8/20/2014 By Serkan  


	--Insert Manually Mapped Records with previously Missing DrugbankID
	SELECT DISTINCT
		   [ATC_CODE]
		  ,[Generic_Name] as OSCAR_Name 
		  ,[DrugName]
		  ,[PreferredSubstance]	  
		  ,[Rx_CUI] 
		  ,[DrugbankID]
		  ,[RXNorm]
		  ,[Drugbank_CA]
		  ,[Drugbank_Bio2rdf]
	INTO PDDI_Databases.[dbo].[OSCAR_Drugbank_Mappings] 
	FROM PDDI_Databases.[dbo].[OSCAR_ATCs_Missing_Drugbank] a
		LEFT JOIN PDDI_Databases.[dbo].[OSCAR_ATCs_Missing_With_DrugbankID] b ON b.[RXNorm] = a.purl


	INSERT INTO PDDI_Databases.[dbo].[OSCAR_Drugbank_Mappings] 
	SELECT DISTINCT
		   [ATC]
		  ,[DrugName] as OSCAR_Name  
		  ,[DrugbankName] as [DrugName]
		  ,null as[PreferredSubstance] 
		  ,null as [Rx_CUI] 
		  ,[drugbankid]
		  ,null as [RXNorm]
		  ,'http://www.drugbank.ca/drugs/' +convert(varchar,[DrugbankID])as [Drugbank_CA]
		  ,'http://bio2rdf.org/drugbank:' +convert(varchar,[DrugbankID])as [Drugbank_Bio2rdf]
	  FROM PDDI_Databases.[dbo].[OSCAR_Drugs]
	  WHERE [drugbankid] IS NOT NULL 


	--Populate DrugbankID
	UPDATE PDDI_Databases.[dbo].[OSCAR_Drugbank_Mappings]
	SET [DrugbankID] = RIGHT([Drugbank_CA], Charindex('/',REVERSE([Drugbank_CA]))-1)  
	WHERE [DrugbankID] IS NULL AND [Drugbank_CA] IS NOT NULL

		
	--Update Drugbank IDs where QIan populated, 70
	UPDATE b
	SET b.[Alternate_DrugName]=q.[Alternative Drug Names],
		b.[Alternate_ATC_CODE]=q.[Alternative ATC],
		b.[DrugBankID] = q.[DrugBankID],
		b.[IsFromQian]=1,
		b.[Drugbank_CA]='http://www.drugbank.ca/drugs/' +convert(varchar,q.[DrugbankID]),
		b.[Drugbank_Bio2rdf]='http://bio2rdf.org/drugbank:' +convert(varchar,q.[DrugbankID])
	FROM PDDI_Databases.[dbo].[OSCAR_Drugbank_Mappings] b
		INNER JOIN [PDDI_Databases].[dbo].[OSCAR_ATCs_Missing_FromQian] q ON q.DrugName = b.DrugName
																			 AND q.Rx_CUI = b.Rx_CUI
	Where b.[DrugBankID] IS  NULL AND q.[DrugBankID] IS NOT NULL

	 
	--Update Drugbank IDs where QIan populated for generics, 6
	UPDATE b
	SET b.[Alternate_DrugName]=q.[Alternative Drug Names],
		b.[Alternate_ATC_CODE]=q.[Alternative ATC],
		b.[DrugBankID] = q.[DrugBankID],
		b.[IsFromQian]=1,
		b.[Drugbank_CA]='http://www.drugbank.ca/drugs/' +convert(varchar,q.[DrugbankID]),
		b.[Drugbank_Bio2rdf]='http://bio2rdf.org/drugbank:' +convert(varchar,q.[DrugbankID]),
		b.DrugName = q.DrugName
	FROM PDDI_Databases.[dbo].[OSCAR_Drugbank_Mappings] b
		INNER JOIN [PDDI_Databases].[dbo].[OSCAR_ATCs_Missing_FromQian] q ON q.GenericName = b.OSCAR_Name
																			 AND b.[ATC_CODE]=q.ATC_CODE
	Where b.[DrugBankID] IS NULL AND q.[DrugBankID] IS NOT NULL
		AND b.DrugName is null
		 
	
	--Alternate ATC COde Update QIan populated, 1
	UPDATE b
	SET b.[Alternate_DrugName]=a.[Alternative Drug Names],
		b.[Alternate_ATC_CODE]=a.[Alternative ATC],
		b.[DrugBankID] = m.[DrugBankID],
		b.[IsFromQian]=1,
		b.[Drugbank_CA]='http://www.drugbank.ca/drugs/' +convert(varchar,m.[DrugbankID]),
		b.[Drugbank_Bio2rdf]='http://bio2rdf.org/drugbank:' +convert(varchar,m.[DrugbankID])  
	FROM PDDI_Databases.[dbo].[OSCAR_Drugbank_Mappings] b
		INNER JOIN [PDDI_Databases].[dbo].[OSCAR_ATCs_Missing_FromQian] a ON a.DrugName=b.DrugName
		INNER JOIN [PDDI_Databases].[dbo].[DrugbankATCMapping] m ON  a.[Alternative ATC] like '%'+m.Atc +'%'
	WHERE a.[DrugBankID] is null and [Alternative ATC] is not null 
    

	-- Update these Drugs where generic matches the drugname - 5 recs 
	UPDATE b
	SET b.drugname=q.drugname,
		b.[DrugBankID] = q.[DrugBankID],
		b.[IsFromQian]=1,
		b.[Drugbank_CA]='http://www.drugbank.ca/drugs/' +convert(varchar,q.[DrugbankID]),
		b.[Drugbank_Bio2rdf]='http://bio2rdf.org/drugbank:' +convert(varchar,q.[DrugbankID])  
	FROM PDDI_Databases.[dbo].[OSCAR_Drugbank_Mappings] b
		INNER JOIN [PDDI_Databases].[dbo].[OSCAR_ATCs_Missing_FromQian] q ON q.GenericName = b.OSCAR_Name 
	Where b.[DrugBankID] IS NULL AND q.[DrugBankID] IS NOT NULL
		AND b.DrugName is null AND (q.DrugName is null OR q.DrugName  LIKE '%?%')
		 
		 
		  

/********************************************************/
--Get Results
/*******************************************************/

	--Mapped Dataset -- in total 10325 PDDIs    
	SELECT DISTINCT	  
			CONVERT(varchar,di.affectingdrug) 
			+'$'+b1.[name] 
			+'$'+dm1.[DrugbankID]    
			+'$'+dm1.[Drugbank_Bio2rdf]  
			+'$'+CONVERT(varchar,di.affecteddrug)  
			+'$'+b2.[name]  
			+'$'+dm2.[DrugbankID] 		 
			+'$'+dm2.[Drugbank_Bio2rdf]  
			+'$'+[effect]
			+'$'+[significance]
			+'$'+[evidence]
			+'$'+CONVERT(varchar,[comment] ) 
	FROM [PDDI_Databases].[dbo].[OSCAR_Interactions] di
		INNER JOIN  [PDDI_Databases].[dbo].[OSCAR_Drugbank_Mappings] dm1 ON dm1.OSCAR_Name = CONVERT(varchar,di.affectingdrug)
		INNER JOIN  [PDDI_Databases].[dbo].[OSCAR_Drugbank_Mappings] dm2 ON dm2.OSCAR_Name = CONVERT(varchar,di.affecteddrug)
		INNER JOIN  [PDDI_Databases].[dbo].[DrugbankATCMapping] b1 ON b1.[DrugbankID] = dm1.[DrugbankID]
		INNER JOIN  [PDDI_Databases].[dbo].[DrugbankATCMapping] b2 ON b2.[DrugbankID] = dm2.[DrugbankID]
	WHERE dm1.[DrugbankID] IS NOT NULL 
		AND dm2.[DrugbankID] IS NOT NULL 



	--Mapped Dataset -- in total 10325 PDDIs    
	SELECT DISTINCT	  
			CONVERT(varchar,di.affectingdrug) 
			+'$'+b1.[name] 
			+'$'+dm1.[DrugbankID]    
			+'$'+dm1.[Drugbank_Bio2rdf]  
			+'$'+CONVERT(varchar,di.affecteddrug)  
			+'$'+b2.[name]  
			+'$'+dm2.[DrugbankID] 		 
			+'$'+dm2.[Drugbank_Bio2rdf]  
			+'$'+[effect]
			+'$'+[significance]
			+'$'+[evidence]
			+'$'+CONVERT(varchar,[comment] ) 
	FROM [PDDI_Databases].[dbo].[OSCAR_Interactions] di
		INNER JOIN  [PDDI_Databases].[dbo].[OSCAR_Drugbank_Mappings] dm1 ON dm1.OSCAR_Name = CONVERT(varchar,di.affectingdrug)
		INNER JOIN  [PDDI_Databases].[dbo].[OSCAR_Drugbank_Mappings] dm2 ON dm2.OSCAR_Name = CONVERT(varchar,di.affecteddrug)
		INNER JOIN  [PDDI_Databases].[dbo].[DrugbankATCMapping] b1 ON b1.[DrugbankID] = dm1.[DrugbankID]
		INNER JOIN  [PDDI_Databases].[dbo].[DrugbankATCMapping] b2 ON b2.[DrugbankID] = dm2.[DrugbankID]
 

