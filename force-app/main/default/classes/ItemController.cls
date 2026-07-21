public with sharing class ItemController {

    @AuraEnabled(cacheable=true)
    public static List<Item__c> getItems(String searchTerm, String type, String family) {
        String searchPattern = '%' + searchTerm + '%';

       String query = 'SELECT Id, Name, Description__c, Type__c, Family__c, Image__c, Price__c, Available_Quantity__c ' +
                        'FROM Item__c WHERE (Name LIKE :searchPattern OR Description__c LIKE :searchPattern)';

        if (String.isNotBlank(type)) {
            query += ' AND Type__c = :type';
        }
        if (String.isNotBlank(family)) {
            query += ' AND Family__c = :family';
        }

        query += ' ORDER BY Name';

        return Database.query(query);
    }

    @AuraEnabled
    public static Id createItem(Item__c newItem) {
        if (!isCurrentUserManager()) {
            throw new AuraHandledException('Only managers can create items.');
        }
        insert newItem;
        return newItem.Id;
    }

   @AuraEnabled(cacheable=true)
    public static Boolean isCurrentUserManager() {
        User currentUser = [SELECT Is_Manager__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return currentUser.Is_Manager__c;
    }
}