@isTest
private class PurchaseControllerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Item__c item = new Item__c(
            Name = 'Test Item',
            Type__c = 'Electronics',
            Family__c = 'Office',
            Price__c = 50,
            Available_Quantity__c = 10
        );
        insert item;
    }

    @isTest
    static void testSuccessfulCheckout() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c item = [SELECT Id, Available_Quantity__c FROM Item__c LIMIT 1];

        PurchaseController.CartItemWrapper cartLine = new PurchaseController.CartItemWrapper();
        cartLine.itemId = item.Id;
        cartLine.quantity = 3;
        cartLine.unitCost = 50;

        Test.startTest();
        Id purchaseId = PurchaseController.checkout(
            new List<PurchaseController.CartItemWrapper>{ cartLine },
            acc.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, purchaseId, 'Purchase should be created');

        Item__c updatedItem = [SELECT Available_Quantity__c FROM Item__c WHERE Id = :item.Id];
        System.assertEquals(7, updatedItem.Available_Quantity__c, 'Stock should decrease by 3');

        List<Purchase_Line__c> lines = [SELECT Id FROM Purchase_Line__c WHERE Purchase__c = :purchaseId];
        System.assertEquals(1, lines.size(), 'One purchase line should be created');
    }

    @isTest
    static void testCheckoutFailsWhenNotEnoughStock() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Item__c item = [SELECT Id FROM Item__c LIMIT 1];

        PurchaseController.CartItemWrapper cartLine = new PurchaseController.CartItemWrapper();
        cartLine.itemId = item.Id;
        cartLine.quantity = 999;
        cartLine.unitCost = 50;

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            PurchaseController.checkout(
                new List<PurchaseController.CartItemWrapper>{ cartLine },
                acc.Id
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Should throw when stock is insufficient');
    }

    @isTest
    static void testCheckoutFailsWithEmptyCart() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            PurchaseController.checkout(new List<PurchaseController.CartItemWrapper>(), acc.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Should throw when cart is empty');
    }
}