@isTest
public class MergeFieldUtilityTest {
	@isTest public static void test_merge() {

		Profile user_profile = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId()];
        User test_user = new User(FirstName = 'testeruser',
		                          UserName = 'testeruser@testmergefieldutilityuser.com', 
		                          LastName = 'testmergefieldutilityuser', 
		                          Email = 'testeruser@testmergefieldutilityuser.com', 
		                          Alias= 'tst',
		                          CommunityNickname = 'testeruser',
		                          LanguageLocaleKey='en_US', 
		                          LocalesIdKey='en_US', 
		                          ProfileId = user_profile.Id,
		                          TimezonesidKey='America/Los_Angeles',
		                          EmailEncodingKey='UTF-8'
		                          );
        insert test_user;

        System.runAs(test_user) {
			Account a = new Account(Name='Test Account');
			insert a;
        }

		String template = 'The account name is {{ Name }} and it\'s owner\'s Id is {{ Owner.Name }}';

		Account a = [SELECT Id, Name, Owner.Name FROM Account LIMIT 1];
		
		Test.startTest();
		String result1 = MergeFieldUtility.replaceMergeFieldsWithValues(template, a.Id);
		String result2 = MergeFieldUtility.replaceMergeFieldsWithValues(template, a);
		Test.stopTest();

		System.debug(a.Owner.Name);

		System.assert(result1 == result2);
		System.assertEquals(true, result1.contains('Test Account') && result1.contains('testeruser testmergefieldutilityuser'));
		System.assertEquals(true, result2.contains('Test Account') && result2.contains('testeruser testmergefieldutilityuser'));
	}
}