
# JsonSerializer.cfc - Data Serialization Utility for ColdFusion

by [Ben Nadel][1]

ColdFusion is a case insensitive language. However, it often has to communicate
with languages, like JavaScript, that are not case sensitive. During the data
serialization workflow, this mismatch of casing can cause a lot of headaches, 
especially when ColdFusion is your API-back-end to a rich-client JavaScript 
front-end application. 

JsonSerializer.cfc is a ColdFusion component that helps ease this transition by
performing the serialization to JavaScript Object Notation (JSON) using a set 
of developer-defined rules for case-management and data-conversion-management. 
Essentially, you can tell the serializer what case to use, no matter what case
the data currently has. 

## Methods

* asAny( key ) - Simply defines the key-casing, without any data conversion.
* asBoolean( key ) - Attempts to force the value to be a true boolean.
* asDate( key ) - Converts the date to an ISO 8601 time string.
* asFloat( key ) - Attempts to force the value to be a true float.
* asInteger( key ) - Attempts to force the value to be a true integer.
* asString( key ) - Forces the value to be a string (including numeric values).
* exclude( key ) - Will exclude the key from the serialization process.

## All-or-Nothing 

The keys are defined using an all-or-nothing approach. By that, I mean that the
serializer doesn't care where it encounters a key - if it matches, it will be
given the explicitly defined casing. So, if you want to use "id" in one place
and "ID" in another place within the same data-structure, you're out of luck.
Both keys will match "id" and will be given the same case.


[1]: http://www.bennadel.com