public with sharing class PurchaseController {

    public class CartItemWrapper {
        @AuraEnabled public Id itemId;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal unitCost;
    }

    @AuraEnabled
    public static Id checkout(List<CartItemWrapper> cartItems, Id accountId) {
        if (cartItems == null || cartItems.isEmpty()) {
            throw new AuraHandledException('Cart is empty.');
        }

        Set<Id> itemIds = new Set<Id>();
        for (CartItemWrapper c : cartItems) {
            itemIds.add(c.itemId);
        }

        Map<Id, Item__c> itemsMap = new Map<Id, Item__c>(
            [SELECT Id, Available_Quantity__c FROM Item__c WHERE Id IN :itemIds]
        );

        for (CartItemWrapper c : cartItems) {
            Item__c dbItem = itemsMap.get(c.itemId);
            if (dbItem == null || dbItem.Available_Quantity__c < c.quantity) {
                throw new AuraHandledException('Not enough stock for item: ' + c.itemId);
            }
        }

        Purchase__c purchase = new Purchase__c(
            Client__c = accountId
        );
        insert purchase;

        List<Purchase_Line__c> lines = new List<Purchase_Line__c>();
        List<Item__c> itemsToUpdate = new List<Item__c>();

        for (CartItemWrapper c : cartItems) {
            lines.add(new Purchase_Line__c(
                Purchase__c = purchase.Id,
                Item__c = c.itemId,
                Amount__c = c.quantity,
                Unit_Cost__c = c.unitCost
            ));

            Item__c dbItem = itemsMap.get(c.itemId);
            dbItem.Available_Quantity__c -= c.quantity;
            itemsToUpdate.add(dbItem);
        }

        insert lines;
        update itemsToUpdate;

        return purchase.Id;
    }
}