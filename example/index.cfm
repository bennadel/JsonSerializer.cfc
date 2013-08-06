<cfscript>
	

	
	serializer = new lib.JsonSerializer()
		.asInteger( "age" )
		.asDate( "dateOfBirth" )
		.asString( "favoriteColor" )
		.asString( "firstName" )
		.asString( "lastName" )
		.asString( "nickName" )
	;

	tricia = {
		firstName = "Tricia",
		lastName = "Smith",
		dateOfBirth = "1975/01/01",
		nickName = "Trish",
		favoriteColor = "333333",
		age = 38
	};

	writeOutput(
		"Tricia: " & 
		serializer.serialize( tricia )
	);


</cfscript>