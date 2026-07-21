@isTest
private class ItemControllerTest {

    @TestSetup
    static void setup() {
        Item__c item = new Item__c(
            Name = 'Test Laptop',
            Description__c = 'A test laptop for unit tests',
            Type__c = 'Electronics',
            Family__c = 'Office',
            Price__c = 999,
            Available_Quantity__c = 10
        );
        insert item;
    }

    @isTest
    static void testGetItemsNoFilter() {
        Test.startTest();
        List<Item__c> results = ItemController.getItems('', null, null);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return the one seeded item');
    }

    @isTest
    static void testGetItemsWithSearch() {
        Test.startTest();
        List<Item__c> results = ItemController.getItems('Laptop', null, null);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Search by name should find the item');
    }

    @isTest
    static void testGetItemsWithFilters() {
        Test.startTest();
        List<Item__c> results = ItemController.getItems('', 'Electronics', 'Office');
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Type/Family filters should match');
    }

    @isTest
    static void testCreateItemAsManager() {
        User managerUser = createTestUser(true);

        Test.startTest();
        System.runAs(managerUser) {
            Item__c newItem = new Item__c(
                Name = 'New Item',
                Description__c = 'desc',
                Type__c = 'Electronics',
                Family__c = 'Office',
                Price__c = 100,
                Available_Quantity__c = 5
            );
            Id newId = ItemController.createItem(newItem);
            System.assertNotEquals(null, newId, 'Item should be created by manager');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateItemAsNonManagerFails() {
        User regularUser = createTestUser(false);

        Test.startTest();
        System.runAs(regularUser) {
            Item__c newItem = new Item__c(
                Name = 'Blocked Item',
                Type__c = 'Electronics',
                Family__c = 'Office',
                Price__c = 50,
                Available_Quantity__c = 3
            );
            Boolean exceptionThrown = false;
            try {
                ItemController.createItem(newItem);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            System.assert(exceptionThrown, 'Non-manager should not be able to create items');
        }
        Test.stopTest();
    }

    private static User createTestUser(Boolean isManager) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User' + Math.random(),
            Email = 'testuser' + Math.random() + '@example.com',
            Username = 'testuser' + Math.random() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            Is_Manager__c = isManager
        );
        insert u;

        // присваивание permission set, чтобы дать доступ к Item__c
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Item_Purchase_Tool_Access' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);

        return u;
    }
}