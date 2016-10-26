@isTest
public class MergeFieldUtilityTest {
	@isTest public static void test_merge() {
		Account a = new Account(Name='Test Account');
		insert a;

		String template = 'The account name is {{ Name }} and it\'s owner\'s Id is {{ OwnerId }}';

		a = [SELECT Id, Name, OwnerId FROM Account WHERE Id = :a.Id];
		
		Test.startTest();
		String result1 = MergeFieldUtility.replaceMergeFieldsWithValues(template, a.Id);
		String result2 = MergeFieldUtility.replaceMergeFieldsWithValues(template, a);
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assertNotEquals(null, result2);
	}
}