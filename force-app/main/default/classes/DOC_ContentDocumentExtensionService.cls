/**
 * @description Service class for DOC_ContentDocumentExtension object operations
 */
public with sharing class DOC_ContentDocumentExtensionService {
    
    /**
     * @description Creates a document extension record for document analysis
     * @param contentDocumentId The ContentDocument ID
     * @param documentType The type of document
     * @param reason The reason for analysis
     * @param accuracy The accuracy percentage
     * @param summary The analysis summary
     * @param status The analysis status
     * @param caseExtensionId The case extension ID
     * @return DOC_ContentDocumentExtension__c The created or updated record
     */
    public static DOC_ContentDocumentExtension__c createDocumentExtension(
        Id contentDocumentId, 
        String documentType, 
        String reason, 
        Decimal accuracy, 
        String summary, 
        String status,
        Id caseExtensionId
    ) {
        DOC_ContentDocumentExtension__c existingRecord = getExistingDocumentExtension(contentDocumentId, caseExtensionId);
        
        if (existingRecord != null) {
            existingRecord.DOC_type__c = documentType;
            existingRecord.DOC_reason__c = reason;
            existingRecord.DOC_accuracy__c = accuracy;
            existingRecord.DOC_summary__c = summary;
            existingRecord.DOC_status__c = status;
            
            update existingRecord;
            return existingRecord;
        } else {
            DOC_ContentDocumentExtension__c docExtension = new DOC_ContentDocumentExtension__c();
            docExtension.DOC_contentDocumentId__c = contentDocumentId;
            docExtension.DOC_type__c = documentType;
            docExtension.DOC_reason__c = reason;
            docExtension.DOC_accuracy__c = accuracy;
            docExtension.DOC_summary__c = summary;
            docExtension.DOC_status__c = status;
            docExtension.DOM_caseExtension__c = caseExtensionId;
            
            insert docExtension;
            return docExtension;
        }
    }
    
    /**
     * @description Retrieves an existing document extension record by contentDocumentId and caseExtensionId
     * @param contentDocumentId The ContentDocument ID
     * @param caseExtensionId The case extension ID
     * @return DOC_ContentDocumentExtension__c The existing record or null if not found
     */
    public static DOC_ContentDocumentExtension__c getExistingDocumentExtension(Id contentDocumentId, Id caseExtensionId) {
        List<DOC_ContentDocumentExtension__c> existingRecords = [
            SELECT Id, DOC_type__c, DOC_reason__c, DOC_accuracy__c, DOC_summary__c, DOC_status__c
            FROM DOC_ContentDocumentExtension__c 
            WHERE DOC_contentDocumentId__c = :contentDocumentId 
            AND DOM_caseExtension__c = :caseExtensionId
            LIMIT 1
        ];
        
        return existingRecords.isEmpty() ? null : existingRecords[0];
    }
    
    /**
     * @description Retrieves document extensions by Case ID through ContentDocumentLink
     * @param caseId The ID of the Case to search for
     * @return List<DOC_ContentDocumentExtension__c> List of document extensions found
     * @throws IllegalArgumentException When caseId is null
     * @throws DOC_ContentDocumentExtensionServiceException When there's an error during the operation
     */
    public static List<DOC_ContentDocumentExtension__c> getDocumentExtensionsByCase(Id caseId) {
        if (caseId == null) {
            throw new IllegalArgumentException('Case ID cannot be null');
        }
        
        try {
            Set<Id> contentDocumentIds = DOM_ContentDocumentService.getContentDocumentIdsForCase(caseId);
            
            if (contentDocumentIds.isEmpty()) {
                return new List<DOC_ContentDocumentExtension__c>();
            }
            
            return [
                SELECT Id, DOC_contentDocumentId__c, DOC_type__c, DOC_reason__c, 
                       DOC_accuracy__c, DOC_summary__c, DOC_status__c, CreatedDate, DOM_caseExtension__c
                FROM DOC_ContentDocumentExtension__c 
                WHERE DOC_contentDocumentId__c IN :contentDocumentIds
                ORDER BY CreatedDate DESC
            ];
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving document extensions by Case: ' + e.getMessage());
            throw new DOC_ContentDocumentExtensionServiceException('Failed to retrieve document extensions by Case: ' + e.getMessage(), e);
        }
    }
    



    
    /**
     * @description Retrieves a JSON snapshot of DOC_ContentDocumentExtension records by Case ID
     * @param caseId The ID of the Case to get document extensions for
     * @return String JSON representation of document extensions associated with the Case
     * @throws IllegalArgumentException When caseId is null
     * @throws DOC_ContentDocumentExtensionServiceException When there's an error during the operation
     */
    public static String getSnapshotForCaseExtension(Id caseId) {
        if (caseId == null) {
            throw new IllegalArgumentException('Case ID cannot be null');
        }
        
        try {
            List<DOM_CaseExtension__c> caseExtensions = [
                SELECT Id
                FROM DOM_CaseExtension__c
                WHERE DOM_caseId__c = :caseId
                LIMIT 1
            ];
            
            if (caseExtensions.isEmpty()) {
                return buildEmptyDocumentExtensionsJson(caseId);
            }
            
            Id caseExtensionId = caseExtensions[0].Id;
            
            List<DOC_ContentDocumentExtension__c> documentExtensions = [
                SELECT Id, Name, DOC_contentDocumentId__c, DOC_type__c, DOC_reason__c, 
                       DOC_accuracy__c, DOC_summary__c, DOC_status__c, CreatedDate, 
                       LastModifiedDate, DOM_caseExtension__c,
                       ENT_claimant1__c, ENT_claimant1Reason__c, ENT_claimant2__c, ENT_claimant2Reason__c,
                       ENT_representative__c, ENT_representativeReason__c, ENT_firm__c, ENT_firmReason__c,
                       ENT_others__c, ENT_othersReason__c
                FROM DOC_ContentDocumentExtension__c 
                WHERE DOM_caseExtension__c = :caseExtensionId
                ORDER BY CreatedDate DESC
            ];
            
            return buildDocumentExtensionsJson(documentExtensions, caseId);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving document extensions snapshot: ' + e.getMessage());
            throw new DOC_ContentDocumentExtensionServiceException('Failed to retrieve document extensions snapshot: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Builds JSON representation of document extensions
     * @param documentExtensions List of document extensions to convert to JSON
     * @param caseId The Case ID for the snapshot
     * @return String JSON representation of the document extensions
     */
    private static String buildDocumentExtensionsJson(List<DOC_ContentDocumentExtension__c> documentExtensions, Id caseId) {
        Map<String, Object> snapshot = new Map<String, Object>();
        snapshot.put('caseId', caseId);
        snapshot.put('totalDocuments', documentExtensions.size());
        snapshot.put('caseExtensionId', documentExtensions.isEmpty() ? null : documentExtensions[0].DOM_caseExtension__c);
        
        List<Map<String, Object>> documents = new List<Map<String, Object>>();
        for (DOC_ContentDocumentExtension__c docExt : documentExtensions) {
            Map<String, Object> docMap = new Map<String, Object>();
            docMap.put('id', docExt.Id);
            docMap.put('name', docExt.Name);
            docMap.put('contentDocumentId', docExt.DOC_contentDocumentId__c);
            docMap.put('type', docExt.DOC_type__c);
            docMap.put('reason', docExt.DOC_reason__c);
            docMap.put('accuracy', docExt.DOC_accuracy__c);
            docMap.put('summary', docExt.DOC_summary__c);
            docMap.put('status', docExt.DOC_status__c);
            docMap.put('createdDate', docExt.CreatedDate);
            docMap.put('lastModifiedDate', docExt.LastModifiedDate);
            
            Map<String, Object> entityAnalysis = new Map<String, Object>();
            entityAnalysis.put('claimant1', docExt.ENT_claimant1__c);
            entityAnalysis.put('claimant1Reason', docExt.ENT_claimant1Reason__c);
            entityAnalysis.put('claimant2', docExt.ENT_claimant2__c);
            entityAnalysis.put('claimant2Reason', docExt.ENT_claimant2Reason__c);
            entityAnalysis.put('representative', docExt.ENT_representative__c);
            entityAnalysis.put('representativeReason', docExt.ENT_representativeReason__c);
            entityAnalysis.put('firm', docExt.ENT_firm__c);
            entityAnalysis.put('firmReason', docExt.ENT_firmReason__c);
            entityAnalysis.put('others', docExt.ENT_others__c);
            entityAnalysis.put('othersReason', docExt.ENT_othersReason__c);
            docMap.put('entityAnalysis', entityAnalysis);
            
            documents.add(docMap);
        }
        
        snapshot.put('documents', documents);
        
        return JSON.serialize(snapshot);
    }
    
    /**
     * @description Builds empty JSON representation when no CaseExtension is found
     * @param caseId The Case ID for the snapshot
     * @return String Empty JSON representation
     */
    private static String buildEmptyDocumentExtensionsJson(Id caseId) {
        Map<String, Object> snapshot = new Map<String, Object>();
        snapshot.put('caseId', caseId);
        snapshot.put('totalDocuments', 0);
        snapshot.put('caseExtensionId', null);
        snapshot.put('documents', new List<Map<String, Object>>());
        
        return JSON.serialize(snapshot);
    }
    
    /**
     * @description Creates a document extension record for entity analysis
     * @param contentDocumentId The ContentDocument ID
     * @param claimant1 The first claimant
     * @param claimant1Reason The reason for first claimant
     * @param claimant2 The second claimant
     * @param claimant2Reason The reason for second claimant
     * @param representative The representative
     * @param representativeReason The reason for representative
     * @param firm The firm
     * @param firmReason The reason for firm
     * @param others The others
     * @param othersReason The reason for others
     * @param status The analysis status
     * @param caseExtensionId The case extension ID
     * @return DOC_ContentDocumentExtension__c The created or updated record
     */
    public static DOC_ContentDocumentExtension__c createEntityExtension(
        Id contentDocumentId, 
        String claimant1, 
        String claimant1Reason,
        String claimant2, 
        String claimant2Reason,
        String representative, 
        String representativeReason,
        String firm, 
        String firmReason,
        String others, 
        String othersReason,
        String status,
        Id caseExtensionId
    ) {
        DOC_ContentDocumentExtension__c existingRecord = getExistingDocumentExtension(contentDocumentId, caseExtensionId);
        
        if (existingRecord != null) {
            existingRecord.ENT_claimant1__c = claimant1;
            existingRecord.ENT_claimant1Reason__c = claimant1Reason;
            existingRecord.ENT_claimant2__c = claimant2;
            existingRecord.ENT_claimant2Reason__c = claimant2Reason;
            existingRecord.ENT_representative__c = representative;
            existingRecord.ENT_representativeReason__c = representativeReason;
            existingRecord.ENT_firm__c = firm;
            existingRecord.ENT_firmReason__c = firmReason;
            existingRecord.ENT_others__c = others;
            existingRecord.ENT_othersReason__c = othersReason;
            existingRecord.DOC_status__c = status;
            
            update existingRecord;
            return existingRecord;
        } else {
            DOC_ContentDocumentExtension__c docExtension = new DOC_ContentDocumentExtension__c();
            docExtension.DOC_contentDocumentId__c = contentDocumentId;
            docExtension.ENT_claimant1__c = claimant1;
            docExtension.ENT_claimant1Reason__c = claimant1Reason;
            docExtension.ENT_claimant2__c = claimant2;
            docExtension.ENT_claimant2Reason__c = claimant2Reason;
            docExtension.ENT_representative__c = representative;
            docExtension.ENT_representativeReason__c = representativeReason;
            docExtension.ENT_firm__c = firm;
            docExtension.ENT_firmReason__c = firmReason;
            docExtension.ENT_others__c = others;
            docExtension.ENT_othersReason__c = othersReason;
            docExtension.DOC_status__c = status;
            docExtension.DOM_caseExtension__c = caseExtensionId;
            
            insert docExtension;
            return docExtension;
        }
    }

    /**
     * @description Custom exception class for DOC_ContentDocumentExtensionService
     */
    public class DOC_ContentDocumentExtensionServiceException extends Exception {}
}
