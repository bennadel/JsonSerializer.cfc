<cfscript>

component
	output = false
	hint = "I provide a way to serialize complext ColdFusion data values as case-sensitive JavaScript Object Notation (JSON) strings."
	{


	// I return the initialized component.
	public any function init() {

		// Every key is added to the full key list.
		fullKeyList = {};

		// These key lists determine special data serialization.
		booleanKeyList = {};
		integerKeyList = {};
		floatKeyList = {};
		dateKeyList = {};

		// These keys will NOT be used in serialization (ie. the key/value pairs will not be added 
		// to the serialized output).
		blockedKeyList = {};

		// When serializing values, ColdFusion has a tendency to convert strings to numbers if those
		// strings look like numbers. We will prepend the string values with this "conversion blocker"
		// so that we can force ColdFusion to make a string (this gets removed after serialization).
		START_OF_STRING = chr( 2 );

		// Return the initialized component.
		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	// I define the given key without a type. This is here to provide key-casing without 
	// caring about why type of data convertion takes place. Returns serializer.
	public any function asAny( required string key ) {

		return(
			defineKey( fullKeyList, key )
		);

	}


	// I define the given key as a boolean. Returns serializer.
	public any function asBoolean( required string key ) {

		return(
			defineKey( booleanKeyList, key )
		);

	}


	// I define the given key as a date. Returns serializer.
	public any function asDate( required string key ) {

		return(
			defineKey( dateKeyList, key )
		);

	}


	// I define the given key as a float / decimal. Returns serializer.
	public any function asFloat( required string key ) {

		return(
			defineKey( floatKeyList, key )
		);

	}


	// I define the given key as an integer. Returns serializer.
	public any function asInteger( required string key ) {

		return(
			defineKey( integerKeyList, key )
		);

	}


	// I define the given key as a string. Returns serializer.
	public any function asString( required string key ) {

		return( asAny( key ) );

	}


	// I define the key as one that should not be included in the serialized response.
	public any function exclude( required string key ) {

		blockedKeyList[ key ] = true;

		return( this );

	}


	// I serialize the given input as JavaScript Object Notation (JSON) using the case-sensitive
	// values defined in the key-list.
	public string function serialize( required any input ) {

		var preparedInput = prepareInputForSerialization( input );

		var serializedInput = serializeJson( preparedInput );

		// At this point, we have the serialized response; but, the response contains unwanted 
		// artifacts that were required to enforce string value integrity. Those must now be
		// removed, post-serialization.
		var sanitizedResponse = removeStartOfStringMarkers( serializedInput );

		return( sanitizedResponse );

	}


	// ---
	// PRIVATE METHODS.
	// ---


	// I define the given key withihn the given key list.
	private any function defineKey(
		required struct keyList,
		required string key 
		) {

		if ( structKeyExists( fullKeyList, key ) ) {

			throw( 
				type = "DuplicateKey",
				message = "The key [#key#] has already been defined within the serializer.",
				detail = "The current key list is: #structKeyList( fullKeyList, ', ' )#"
			);

		}

		// Add to the appropriate data-type lists.
		keyList[ key ] = key;

		// Add all keys to the full key list as well. NOTE: If the given key list IS the 
		// default key list, we'll get the same key written twice. Not the best thing; but,
		// causes no problems.
		fullKeyList[ key ] = key;

		// Return this reference for method chaining.
		return( this );

	}


	// I return the ISO 8601 time string for the given date. This function assumes that the
	// date is already in the desired timezone. 
	private string function getIsoTimeString(  required date input ) {

		return(
			dateFormat( input, "yyyy-mm-dd" ) & "T" &
			timeFormat( input, "HH:mm:ss.l" ) & "Z"
		);

	}


	// I prepare the given array for serialization. Since the array doesn't have keys, this 
	// function will simply walk the array and prepare each value contained within the array.
	private array function prepareArrayForSerialization( 
		required array input,
		required string closestKey
		) {

		var preparedInput = [];

		for ( var value in input ) {

			arrayAppend(
				preparedInput,
				prepareInputForSerialization( value, closestKey )
			);

		}

		return( preparedInput );

	}


	// I prepare the input for case/value-sensitive serialization.
	private any function prepareInputForSerialization( 
		required any input,
		string closestKey = ""
		) {

		// Convert the response based on its type.
		if ( isArray( input ) ) {

			return(
				prepareArrayForSerialization( input, closestKey )
			);

		} else if ( isStruct( input ) ) {

			// NOTE: No need to pass-in the closestKey since struct will provide its own keys.
			return( 
				prepareStructForSerialization( input )
			);

		} else if ( isQuery( input ) ) {

			// NOTE: No need to pass-in the closestKey since query will provide its own keys.
			return(
				prepareQueryForSerialization( input )
			);

		} else if ( isSimpleValue( input ) ) {

			return(
				prepareSimpleValueForSerialization( input, closestKey )
			);

		}

		// If the input is not a complex type, then we can gain no insight on how it's supposed
		// to be converted (we only get this insight when a KEY is provided). As such, simply
		// pass this through and let ColdFusion handle it as best as possible.
		return( input );

	}


	// Return the key with the appropriate casing (or all lowercase if no case has been provided).
	private string function prepareKeyForSerialization( required string key ) {

		if ( structKeyExists( fullKeyList, key ) ) {

			return( fullKeyList[ key ] );

		} else {

			return( lcase( key ) );


		}

	}


	// I prepare the given query for serialization.
	private array function prepareQueryForSerialization( required query input ) {

		var preparedInput = [];

		for ( var i = 1 ; i <= input.recordCount ; i++ ) {

			arrayAppend(
				preparedInput,
				prepareQueryRowForSerialization( input, i )
			);

		}

		return( preparedInput );

	}


	// I prepare the given query row for serialization. Each query row is converted to a 
	// struct in which the column name is the struct-key, and the row value is the struct-value.
	private struct function prepareQueryRowForSerialization( 
		required query input,
		required numeric rowIndex
		) {

		var preparedInput = {};

		for ( var key in listToArray( input.columnList ) ) {

			// If this key is black-listed, skip it.
			if ( structKeyExists( blockedKeyList, key ) ) {

				continue;

			}

			// Get the appropriate casing for the key.
			var preparedKey = prepareKeyForSerialization( key ); 
				
			preparedInput[ preparedKey ] = prepareInputForSerialization( input[ key ][ rowIndex ], key );

		}

		return( preparedInput );

	}


	// I prepare the given struct for serialization.
	private struct function prepareStructForSerialization( required struct input ) {

		var preparedInput = {};

		for ( var key in input ) {

			// If this key is black-listed, skip it.
			if ( structKeyExists( blockedKeyList, key ) ) {

				continue;

			}

			// Get the appropriate casing for the key.
			var preparedKey = prepareKeyForSerialization( key ); 

			preparedInput[ preparedKey ] = prepareInputForSerialization( input[ key ], key );

		}

		return( preparedInput );

	}


	// I prepare the given simple value for serialization by converting (or attempting to convert
	// it) into the data type defined by the closest key in the contextual data structure.
	private any function prepareSimpleValueForSerialization(
		required any value,
		required string closestKey
		) {

		// If we don't have any known container key, then we have no extra insight into how to 
		// serialize this value. As such, force it to be a string.
		if ( closestKey == "" ) {

			return( START_OF_STRING & value );

		}

		// Check to see if the key was defined in a data-type-specific list. If so, we'll try to
		// convert the value as we copy it over into the prepared input.
		if (
			structKeyExists( integerKeyList, closestKey ) &&
			( isNumeric( value ) || isBoolean( value ) )
			) {

			return( javaCast( "long", value ) );

		} else if (
			structKeyExists( floatKeyList, closestKey ) &&
			( isNumeric( value ) || isBoolean( value ) )
			) {

			return( javaCast( "float", value ) );

		} else if (
			structKeyExists( booleanKeyList, closestKey ) &&
			isBoolean( value )
			) {

			return( javaCast( "boolean", value ) );

		} else if (
			structKeyExists( dateKeyList, closestKey ) &&
			isNumericDate( value )
			) {

			return( getIsoTimeString( value ) );

		} else {

			// Prepend the string-value with the start-of-string marker so that ColdFusion won't 
			// be tempted to serialize the string value as a number.
			return( START_OF_STRING & value );

		}

	}


	// I strip out the start-of-string markers that were used to force ColdFusion to serialize
	// the given value as a string (ie, blocks accidental numeric conversions).
	private string function removeStartOfStringMarkers( required string response ) {

		return(
			response.replaceAll(
				javaCast( "string", START_OF_STRING ),
				javaCast( "string", "" )
			)
		);

	}


}

</cfscript>