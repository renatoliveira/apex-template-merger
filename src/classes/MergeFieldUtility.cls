/**
* @author Ben Edwards (ben@edwards.nz)
* @date 2016-08-25
* @description Take a given string with merge fields and replace with values
**/
public class MergeFieldUtility {
	
	// The Pattern used for all merging. This is the {{ Field__c }} syntax.
	// You can replace this with your own merge sync (eg. <? Field__c ?> or {!Field__c}
	private static Pattern thePattern() {
		return Pattern.compile('\\{\\{([^}]*)\\}\\}');
	}

	/**
	 * Passing the record directly with fields. No need for Id.
	 * Useful if we already have the values, or if we want to avoid SOQL
	 * while doing this operation over multiple records.
	 * 
	 * @param  stringToMerge String with values to merge.
	 * @param  record        Record with values to merge into the string
	 * @return               Returns the string with all merge fields replaced with values
	 */
	public static String replaceMergeFieldsWithValues (String stringToMerge, SObject record) {
		return replaceMergeFieldsWithValues(stringToMerge, null, record);
	}

	/**
	 * If we don't have the record, then we pass the Id so the class
	 * can do the heavy work.
	 * @param  stringToMerge String with values to merge.
	 * @param  recordId      Id of the record which contains the values we need to replace.
	 * @return               Returns the string with all merge fields replaced with values
	 */
	public static String replaceMergeFieldsWithValues (String stringToMerge, String recordId) {
		return replaceMergeFieldsWithValues(stringToMerge, recordId, null);
	}

	/**
	*   @author Ben Edwards (ben@edwards.nz)
	*   @description Generate the string with the replaced values
	*   @return Returns the string with all merge fields replaced with values
	**/
	public static String replaceMergeFieldsWithValues (String stringToMerge, String recordId, SObject record) {
		
		// Get the object name based on the recordId
		String objectName;
		if (recordId != null) {
			objectName = ((Id) recordId).getSObjectType().getDescribe().getName();
		}
		else {
			objectName = ((Id) record.Id).getSObjectType().getDescribe().getName();
		}

		// The matcher which returns the matched fields from the given string
		Matcher theMatcher = thePattern().matcher(stringToMerge);
		
		// Query for the SObject and all related fields, if the record wasn't passed already
		SObject theRecord;

		if (record == null) {
			theRecord = getRecord (thePattern, stringToMerge, objectName, recordId);
		}
		else {
			theRecord = record;
		}
		
		// Iterate over each match
		while (theMatcher.find()) {

			// Get the field name based on the match
			String mergeField = theMatcher.group(1).trim();

			// The following logic is a bit ugly. The idea is to support getting parent fields for the object
			// This allows to go 5 levels high. If anyone knows a better way to do this, please let me know.
			// Eg. {{ Case.Contact.Account.Name }}
			// Eg2. {{ Child__r.Parent__r.Email }}

			// Need to determine if there is a relationship in the field. This decides how many levels up to go
			List<String> objectsAndField = mergeField.split('\\.');

			// If there's no relationship
			if (objectsAndField.size() == 1) {

				// Replace the matching field name with the value
				stringToMerge = stringToMerge.replace('{{ ' + mergeField + ' }}', String.valueOf(theRecord.get(mergeField)));
			}
			// Otherwise, need to go up levels depending on how many levels there are
			else if (objectsAndField.size() > 1) {

				// This is a very non-elegant way of merging in parent objects
				// But I couldn't work out a better way to do it, so this is the best we have
				// Supports up to 5 parent objects
				if (objectsAndField.size() == 2) {
					stringToMerge = stringToMerge.replace('{{ ' + mergeField + ' }}', String.valueOf(theRecord.getSObject(objectsAndField[0]).get(objectsAndField[1])));
				}
				else if (objectsAndField.size() == 3) {
					stringToMerge = stringToMerge.replace('{{ ' + mergeField + ' }}', String.valueOf(theRecord.getSObject(objectsAndField[0]).getSObject(objectsAndField[1]).get(objectsAndField[2])));
				}
				else if (objectsAndField.size() == 4) {
					stringToMerge = stringToMerge.replace('{{ ' + mergeField + ' }}', String.valueOf(theRecord.getSObject(objectsAndField[0]).getSObject(objectsAndField[1]).getSObject(objectsAndField[2]).get(objectsAndField[3])));
				}
				else if (objectsAndField.size() == 5) {
					stringToMerge = stringToMerge.replace('{{ ' + mergeField + ' }}', String.valueOf(theRecord.getSObject(objectsAndField[0]).getSObject(objectsAndField[1]).getSObject(objectsAndField[2]).getSObject(objectsAndField[3]).get(objectsAndField[4])));
				}
			}
		}
		
		// Return the string with all the merge fields replaced with their values, yay!
		return stringToMerge;
	}


	/**
	*   @author Ben Edwards (ben@edwards.nz)
	*   @description Do a dynamic SOQL query to get the record and required fields for the merging
	*   @return Return the SObject record
	**/
	private static SObject getRecord (String stringToMerge, String objectName, String recordId) {

		// The set of fields to query for
		Set<String> fieldsForQuery = new Set<String>();

		// The matcher which returns the matched fields from the given string
		Matcher theMatcher = thePattern().matcher(stringToMerge);

		// Loop through each match
		while (theMatcher.find()) {

			// Add the field name to the set
			fieldsForQuery.add(theMatcher.group(1).trim());
		}

		// Build the query. The set of fields needs to be converted to a list to use String.join()
		String theQuery = 'SELECT ' + String.join(new List<String>(fieldsForQuery), ',');
		theQuery += ' FROM ' + objectName;
		theQuery += ' WHERE Id = \'' +  recordId + '\'';

		// Execute the query and record the record
		return Database.query(theQuery);
	}
}