/**
 * @description Service class for ContentDocument operations
 */
public with sharing class DOM_ContentDocumentService {
    
    /**
     * @description Retrieves ContentDocument IDs associated with a Case
     * @param caseId The ID of the Case
     * @return Set<Id> Set of ContentDocument IDs
     */
    public static Set<Id> getContentDocumentIdsForCase(Id caseId) {
        if (caseId == null) return new Set<Id>();
        
        List<ContentDocumentLink> links = getBasicContentDocumentLinksForCase(caseId);
        return extractContentDocumentIds(links);
    }
    
    /**
     * @description Retrieves a ContentDocument by ID
     * @param contentDocumentId The ID of the ContentDocument
     * @return ContentDocument The document, or null if not found
     */
    public static ContentDocument getContentDocumentById(Id contentDocumentId) {
        if (contentDocumentId == null) return null;
        
        List<ContentDocument> documents = [
            SELECT Id, Title, FileType
            FROM ContentDocument 
            WHERE Id = :contentDocumentId
            LIMIT 1
        ];
        
        return documents.isEmpty() ? null : documents[0];
    }
    
    /**
     * @description Retrieves ContentDocumentLink records with ContentDocument information for a Case
     * @param caseId The ID of the Case
     * @return List<ContentDocumentLink> List of document links with document information
     */
    public static List<ContentDocumentLink> getContentDocumentLinksForCase(Id caseId) {
        if (caseId == null) return new List<ContentDocumentLink>();
        
        return [
            SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.FileType
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :caseId 
            AND LinkedEntity.Type = 'Case'
            ORDER BY ContentDocument.CreatedDate ASC
        ];
    }
    
    /**
     * @description Retrieves ContentDocumentExtension for a given ContentDocument ID
     * @param contentDocumentId The ID of the ContentDocument
     * @return DOC_ContentDocumentExtension__c The ContentDocumentExtension record or null if not found
     */
    public static DOC_ContentDocumentExtension__c getContentDocumentExtension(Id contentDocumentId) {
        if (contentDocumentId == null) return null;
        
        List<DOC_ContentDocumentExtension__c> extensions = [
            SELECT Id, Name, DOC_contentDocumentId__c, DOC_type__c, DOC_reason__c,
                   DOC_accuracy__c, DOC_summary__c, DOC_status__c, CreatedDate, LastModifiedDate,
                   EVAL_status__c, EVAL_CategorizationKOFeedback__c,
                   ENT_claimant1__c, ENT_claimant1Reason__c, ENT_claimant2__c, ENT_claimant2Reason__c,
                   ENT_representative__c, ENT_representativeReason__c, ENT_firm__c, ENT_firmReason__c,
                   ENT_others__c, ENT_othersReason__c
            FROM DOC_ContentDocumentExtension__c
            WHERE DOC_contentDocumentId__c = :contentDocumentId
            LIMIT 1
        ];
        
        return extensions.isEmpty() ? null : extensions[0];
    }
    
    private static List<ContentDocumentLink> getBasicContentDocumentLinksForCase(Id caseId) {
        return [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :caseId 
            AND LinkedEntity.Type = 'Case'
        ];
    }

    private static Set<Id> extractContentDocumentIds(List<ContentDocumentLink> links) {
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            contentDocumentIds.add(link.ContentDocumentId);
        }
        return contentDocumentIds;
    }
}
