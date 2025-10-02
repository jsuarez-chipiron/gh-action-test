/**
 * @description Service class for Case object operations
 */
public with sharing class DOM_CaseService {
    
    /**
     * @description Retrieves incoming email messages related to a specific case for spam analysis
     * @param caseRecord The case record to get emails for
     * @return List<EmailMessage> List of incoming email messages related to the case
     * @throws IllegalArgumentException When caseRecord is null or caseRecord.Id is null
     * @throws DOM_CaseServiceException When there's an error executing the SOQL query or retrieving the emails
     */
    public static List<EmailMessage> getEmailsForCase(Case caseRecord) {
        if (caseRecord == null || caseRecord.Id == null) {
            throw new IllegalArgumentException('Case record cannot be null and must have an Id');
        }
        
        try {
            if (emailsCache != null) {
                System.debug('FROM CACHE');
                return emailsCache;
            }

            emailsCache = [
                SELECT Id, Subject, TextBody, HtmlBody, FromAddress, ToAddress, 
                       CcAddress, BccAddress, MessageDate, Status, Incoming,
                       CreatedDate, LastModifiedDate
                FROM EmailMessage 
                WHERE RelatedToId = :caseRecord.Id 
                AND Incoming = true
                ORDER BY CreatedDate DESC
            ];

                System.debug('FROM DB');
            
            return emailsCache;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving emails for case: ' + e.getMessage());
            throw new DOM_CaseServiceException('Failed to retrieve emails for case: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Updates language detection information for a case and its extension
     * @param caseRecord The case record to update language information for
     * @param lang The language detected
     * @param reason The reason for the language detection
     * @return DOM_CaseExtension__c The updated or created case extension record
     * @throws IllegalArgumentException When caseRecord is null or caseRecord.Id is null
     * @throws DOM_CaseServiceException When there's an error during the operation
     */
    public static DOM_CaseExtension__c updateLangInformation(Case caseRecord, String lang, String reason, Decimal accuracy) {
        if (caseRecord == null || caseRecord.Id == null) {
            throw new IllegalArgumentException('Case record cannot be null and must have an Id');
        }
        
        try {
            return DOM_CaseExtensionService.updateLangInformation(caseRecord, lang, reason, accuracy);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating language information for case: ' + e.getMessage());
            throw new DOM_CaseServiceException('Failed to update language information for case: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Updates spam detection information for a case and its extension
     * @param caseRecord The case record to update spam information for
     * @param isSpam Whether the case is classified as spam
     * @param spamReason The reason for spam classification
     * @param spamAccuracy The accuracy score for spam classification
     * @return DOM_CaseExtension__c The updated or created case extension record
     * @throws IllegalArgumentException When caseRecord is null or caseRecord.Id is null
     * @throws DOM_CaseServiceException When there's an error during the operation
     */
    public static DOM_CaseExtension__c updateSpamInformation(Case caseRecord, Boolean isSpam, String spamReason, Decimal spamAccuracy) {
        if (caseRecord == null || caseRecord.Id == null) {
            throw new IllegalArgumentException('Case record cannot be null and must have an Id');
        }
        
        try {
            return DOM_CaseExtensionService.updateSpamInformation(caseRecord, isSpam, spamReason, spamAccuracy);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating spam information for case: ' + e.getMessage());
            throw new DOM_CaseServiceException('Failed to update spam information for case: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Updates derivation information for a case and its extension
     * @param caseRecord The case record to update derivation information for
     * @param isDerivated Whether the case has been derived
     * @param derivatedTo The destination where the case has been derived to
     * @param reason The reason for the derivation
     * @param accuracy The accuracy score for the derivation decision
     * @return DOM_CaseExtension__c The updated or created case extension record
     * @throws IllegalArgumentException When caseRecord is null or caseRecord.Id is null
     * @throws DOM_CaseServiceException When there's an error during the operation
     */
    public static DOM_CaseExtension__c updateDerivationInformation(Case caseRecord, Boolean isDerivated, String derivatedTo, String reason, Decimal accuracy) {
        if (caseRecord == null || caseRecord.Id == null) {
            throw new IllegalArgumentException('Case record cannot be null and must have an Id');
        }
        
        try {
            return DOM_CaseExtensionService.updateDerivationInformation(caseRecord, isDerivated, derivatedTo, reason, accuracy);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating derivation information for case: ' + e.getMessage());
            throw new DOM_CaseServiceException('Failed to update derivation information for case: ' + e.getMessage(), e);
        }
        }
    
    /**
     * @description Updates document analysis information for a case and its extension
     * @param caseRecord The case record to update document analysis information for
     * @param totalDocuments The total number of documents to analyze
     * @return DOM_CaseExtension__c The updated or created case extension record
     * @throws IllegalArgumentException When caseRecord is null or caseRecord.Id is null
     * @throws DOM_CaseServiceException When there's an error during the operation
     */
    public static DOM_CaseExtension__c updateDocumentInformation(Case caseRecord, Integer totalDocuments) {
        if (caseRecord == null || caseRecord.Id == null) {
            throw new IllegalArgumentException('Case record cannot be null and must have an Id');
        }
        
        try {
            return DOM_CaseExtensionService.updateDocumentInformation(caseRecord, totalDocuments);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating document analysis information for case: ' + e.getMessage());
            throw new DOM_CaseServiceException('Failed to update document analysis information for case: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Updates aggregated entity information for a case
     * @param caseRecord The case record to update entity information for
     * @param claimant1 The aggregated claimant1 information
     * @param claimant1Reason The reason for claimant1 identification
     * @param claimant2 The aggregated claimant2 information
     * @param claimant2Reason The reason for claimant2 identification
     * @param representative The aggregated representative information
     * @param representativeReason The reason for representative identification
     * @param firm The aggregated firm information
     * @param firmReason The reason for firm identification
     * @param others The aggregated others information
     * @param othersReason The reason for others identification
     * @return DOM_CaseExtension__c The updated case extension record
     * @throws IllegalArgumentException When caseRecord is null or caseRecord.Id is null
     * @throws DOM_CaseServiceException When there's an error during the operation
     */
    public static DOM_CaseExtension__c updateAggregatedEntityInformation(Case caseRecord, String claimant1, String claimant1Reason,
                                                        String claimant2, String claimant2Reason,
                                                        String representative, String representativeReason,
                                                        String firm, String firmReason,
                                                        String others, String othersReason) {
        if (caseRecord == null || caseRecord.Id == null) {
            throw new IllegalArgumentException('Case record cannot be null and must have an Id');
        }
        
        try {
            return DOM_CaseExtensionService.updateAggregatedEntityInformation(
                caseRecord, claimant1, claimant1Reason, claimant2, claimant2Reason,
                representative, representativeReason, firm, firmReason, others, othersReason
            );
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating aggregated entity information for case: ' + e.getMessage());
            throw new DOM_CaseServiceException('Failed to update aggregated entity information for case: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Retrieves Case with associated CaseExtension information as JSON
     * @param caseId The ID of the Case to get information for
     * @return String JSON representation of Case with CaseExtension information
     * @throws IllegalArgumentException When caseId is null
     * @throws DOM_CaseServiceException When there's an error during the operation
     */
    public static String getSnapshotWithExtension(Id caseId) {
        if (caseId == null) {
            throw new IllegalArgumentException('Case ID cannot be null');
        }
        
        try {
            Case caseRecord = retrieveCaseInformation(caseId);
            String caseExtensionJson = DOM_CaseExtensionService.getSnapshotForCaseExtension(caseId);
            String emailMessagesJson = DOM_EmailMessageService.getSnapshotForCase(caseId);
            
            return buildCaseSnapshotJson(caseRecord, caseExtensionJson, emailMessagesJson);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving case with extension: ' + e.getMessage());
            throw new DOM_CaseServiceException('Failed to retrieve case with extension: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Retrieves Case information by ID
     * @param caseId The ID of the Case to retrieve
     * @return Case The Case record with relevant fields
     * @throws DOM_CaseServiceException When Case is not found or error occurs
     */
    private static Case retrieveCaseInformation(Id caseId) {
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Description, Status, Priority, Origin, 
                   Type, Reason, CreatedDate, LastModifiedDate, ClosedDate,
                   OwnerId, Owner.Name, ContactId, Contact.Name, AccountId, Account.Name
            FROM Case 
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        if (cases.isEmpty()) {
            throw new DOM_CaseServiceException('Case not found with ID: ' + caseId);
        }
        
        return cases[0];
    }

    /**
     * @description Custom exception class for DOM_CaseService
     */
    public class DOM_CaseServiceException extends Exception {}

    /**
     * @description Cache for email messages related to cases
     */
    public static List<EmailMessage> emailsCache = null;
    
    /**
     * @description Builds JSON representation of Case with CaseExtension and Email information
     * @param caseRecord The Case record
     * @param caseExtensionJson The CaseExtension JSON string
     * @param emailMessagesJson The EmailMessages JSON string
     * @return String JSON representation
     */
    private static String buildCaseSnapshotJson(Case caseRecord, String caseExtensionJson, String emailMessagesJson) {
        Map<String, Object> snapshot = new Map<String, Object>();
        

        Map<String, Object> caseInfo = new Map<String, Object>();
        caseInfo.put('id', caseRecord.Id);
        caseInfo.put('caseNumber', caseRecord.CaseNumber);
        caseInfo.put('subject', caseRecord.Subject);
        caseInfo.put('description', caseRecord.Description);
        caseInfo.put('status', caseRecord.Status);
        caseInfo.put('priority', caseRecord.Priority);
        caseInfo.put('origin', caseRecord.Origin);
        caseInfo.put('type', caseRecord.Type);
        caseInfo.put('reason', caseRecord.Reason);
        caseInfo.put('createdDate', caseRecord.CreatedDate);
        caseInfo.put('lastModifiedDate', caseRecord.LastModifiedDate);
        caseInfo.put('closedDate', caseRecord.ClosedDate);
        

        Map<String, Object> ownerInfo = new Map<String, Object>();
        ownerInfo.put('id', caseRecord.OwnerId);
        ownerInfo.put('name', caseRecord.Owner?.Name);
        caseInfo.put('owner', ownerInfo);
        

        Map<String, Object> contactInfo = new Map<String, Object>();
        contactInfo.put('id', caseRecord.ContactId);
        contactInfo.put('name', caseRecord.Contact?.Name);
        caseInfo.put('contact', contactInfo);
        

        Map<String, Object> accountInfo = new Map<String, Object>();
        accountInfo.put('id', caseRecord.AccountId);
        accountInfo.put('name', caseRecord.Account?.Name);
        caseInfo.put('account', accountInfo);
        
        snapshot.put('case', caseInfo);
        

        Map<String, Object> caseExtension = (Map<String, Object>) JSON.deserializeUntyped(caseExtensionJson);
        snapshot.put('caseExtension', caseExtension);
        

        Map<String, Object> emailMessages = (Map<String, Object>) JSON.deserializeUntyped(emailMessagesJson);
        snapshot.put('emailMessages', emailMessages);
        
        return JSON.serialize(snapshot);
    }
    
    /**
     * @description Safely converts a string to a displayable format
     * @param value The string value to convert
     * @return String Safe string value or 'N/A' if null/empty
     */
    private static String getSafeString(String value) {
        return String.isNotBlank(value) ? value : 'N/A';
    }
    
    /**
     * @description Formats a date for display
     * @param dateValue The date to format
     * @return String Formatted date or 'N/A' if null
     */
    private static String formatDate(DateTime dateValue) {
        return dateValue != null ? dateValue.format('yyyy-MM-dd HH:mm:ss') : 'N/A';
    }
}