# apex-template-merging
Custom Apex utility for merging strings containing merge fields and replacing with values

This utility provides a way to pass a string containing merge fields using `{{ field_name }}` syntax, and getting the SObject record value.

You can use the record's Id for this...

```
String myTemplate = 'Hey {{ FirstName }}, your email address is {{ Email }} and account name is {{ Account.Name }}';

String myResult = MergeFieldUtility.replaceMergeFieldsWithValues (
  myTemplate, // The string to merge
  '0032800000YWeRQ' // The record ID
);
```

...or use the object itself.

```
String myTemplate = 'Hey {{ FirstName }}, your email address is {{ Email }} and account name is {{ Account.Name }}';
Contact myContact = [SELECT Id, Email, Name FROM Contact WHERE Id IN ('0032800000YWeRQ')];

String myResult = MergeFieldUtility.replaceMergeFieldsWithValues (
  myTemplate, // The string to merge
  myContact // The record itself
);
```

Both output the same thing:

```
###[DEBUG]: Hey Ben, your email address is ben@edwards.nz and account name is Edwards Enterprises
```

The second example can be used when you have a list of records in which you want to do the merging. Because you already have the record stored in a variable (in a list, set or map), you can avoid hitting the SOQL governor limit.
