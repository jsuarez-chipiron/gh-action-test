/**
 * @description Service class for DOM_CaseExtension object operations
 */
public with sharing class DOM_CaseExtensionService {
    
    /**
     * @description Updates or creates language detection information for a case extension
     * @param caseRecord The case record to update language information for
     * @param lang The language detected for the case
     * @param reason The reason for the language detection
     * @return DOM_CaseExtension__c The updated or created case extension record
     * @throws IllegalArgumentException When caseRecord is null or caseRecord.Id is null
     * @throws DOM_CaseExtensionServiceException When there's an error during the operation
     */
    public static DOM_CaseExtension__c updateLangInformation(Case caseRecord, String lang, String reason, Decimal accuracy) {
        if (caseRecord == null || caseRecord.Id == null) {
            throw new IllegalArgumentException('Case record cannot be null and must have an Id');
        }
        
        try {
            // TODO: review if this query can be optimized
            List<DOM_CaseExtension__c> existingExtensions = [
                SELECT Id, DOM_caseId__c, LANG_lang__c, LANG_reason__c
                FROM DOM_CaseExtension__c 
                WHERE DOM_caseId__c = :caseRecord.Id
                LIMIT 1
            ];
            
            DOM_CaseExtension__c caseExtension;
            
            if (!existingExtensions.isEmpty()) {
                caseExtension = existingExtensions[0];
            } else {
                caseExtension = new DOM_CaseExtension__c();
                caseExtension.DOM_caseId__c = caseRecord.Id;
            }
            
            caseExtension.LANG_lang__c = lang;
            caseExtension.LANG_reason__c = reason;
            caseExtension.LANG_accuracy__c = accuracy;
            caseExtension.DOM_Status__c = DOM_Config.LANG_EXTENSION_STATUS;
            
            upsert caseExtension;
            
            return caseExtension;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating language information: ' + e.getMessage());
            throw new DOM_CaseExtensionServiceException('Failed to update language information: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Updates or creates spam detection information for a case extension
     * @param caseRecord The case record to update spam information for
     * @param isSpam Whether the case is classified as spam
     * @param spamReason The reason for spam classification
     * @param spamAccuracy The accuracy score for spam classification
     * @return DOM_CaseExtension__c The updated or created case extension record
     * @throws IllegalArgumentException When caseRecord is null or caseRecord.Id is null
     * @throws DOM_CaseExtensionServiceException When there's an error during the operation
     */
    public static DOM_CaseExtension__c updateSpamInformation(Case caseRecord, Boolean isSpam, String spamReason, Decimal spamAccuracy) {
        if (caseRecord == null || caseRecord.Id == null) {
            throw new IllegalArgumentException('Case record cannot be null and must have an Id');
        }
        
        try {
            List<DOM_CaseExtension__c> existingExtensions = [
                SELECT Id, DOM_caseId__c, SPAM_isSpam__c, SPAM_Reason__c, SPAM_Accuracy__c
                FROM DOM_CaseExtension__c 
                WHERE DOM_caseId__c = :caseRecord.Id
                LIMIT 1
            ];
            
            DOM_CaseExtension__c caseExtension;
            
            if (!existingExtensions.isEmpty()) {
                caseExtension = existingExtensions[0];
            } else {
                caseExtension = new DOM_CaseExtension__c();
                caseExtension.DOM_caseId__c = caseRecord.Id;
            }
            
            caseExtension.SPAM_isSpam__c = isSpam;
            caseExtension.SPAM_Reason__c = spamReason;
            caseExtension.SPAM_Accuracy__c = spamAccuracy;
            caseExtension.DOM_Status__c = DOM_Config.SPAM_EXTENSION_STATUS;
            
            upsert caseExtension;
            
            return caseExtension;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating spam information: ' + e.getMessage());
            throw new DOM_CaseExtensionServiceException('Failed to update spam information: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Updates or creates derivation information for a case extension
     * @param caseRecord The case record to update derivation information for
     * @param isDerivated Whether the case has been derived
     * @param derivatedTo The destination where the case has been derived to
     * @param reason The reason for the derivation
     * @param accuracy The accuracy score for the derivation decision
     * @return DOM_CaseExtension__c The updated or created case extension record
     * @throws IllegalArgumentException When caseRecord is null or caseRecord.Id is null
     * @throws DOM_CaseExtensionServiceException When there's an error during the operation
     */
    public static DOM_CaseExtension__c updateDerivationInformation(Case caseRecord, Boolean isDerivated, String derivatedTo, String reason, Decimal accuracy) {
        if (caseRecord == null || caseRecord.Id == null) {
            throw new IllegalArgumentException('Case record cannot be null and must have an Id');
        }
        
        try {
            List<DOM_CaseExtension__c> existingExtensions = [
                SELECT Id, DOM_caseId__c, DRV_isDerivated__c, DRV_derivatedTo__c, DRV_Reason__c, DRV_Accuracy__c
                FROM DOM_CaseExtension__c 
                WHERE DOM_caseId__c = :caseRecord.Id
                LIMIT 1
            ];
            
            DOM_CaseExtension__c caseExtension;
            
            if (!existingExtensions.isEmpty()) {
                caseExtension = existingExtensions[0];
            } else {
                caseExtension = new DOM_CaseExtension__c();
                caseExtension.DOM_caseId__c = caseRecord.Id;
            }
            
            caseExtension.DRV_isDerivated__c = isDerivated;
            caseExtension.DRV_derivatedTo__c = derivatedTo;
            caseExtension.DRV_Reason__c = reason;
            caseExtension.DRV_Accuracy__c = accuracy;
            caseExtension.DOM_Status__c = DOM_Config.DRV_EXTENSION_STATUS;
            
            upsert caseExtension;
            
            return caseExtension;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating derivation information: ' + e.getMessage());
            throw new DOM_CaseExtensionServiceException('Failed to update derivation information: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Updates or creates document analysis information for a case extension
     * @param caseRecord The case record to update document analysis information for
     * @param totalDocuments The total number of documents to analyze
     * @return DOM_CaseExtension__c The updated or created case extension record
     * @throws IllegalArgumentException When caseRecord is null or caseRecord.Id is null
     * @throws DOM_CaseExtensionServiceException When there's an error during the operation
     */
    public static DOM_CaseExtension__c updateDocumentInformation(Case caseRecord, Integer totalDocuments) {
        if (caseRecord == null || caseRecord.Id == null) {
            throw new IllegalArgumentException('Case record cannot be null and must have an Id');
        }
        
        try {
            List<DOM_CaseExtension__c> existingExtensions = [
                SELECT Id, DOM_caseId__c, DOC_toAnalyse__c, DOC_status__c
                FROM DOM_CaseExtension__c 
                WHERE DOM_caseId__c = :caseRecord.Id
                LIMIT 1
            ];
            
            DOM_CaseExtension__c caseExtension;
            
            if (!existingExtensions.isEmpty()) {
                caseExtension = existingExtensions[0];
            } else {
                caseExtension = new DOM_CaseExtension__c();
                caseExtension.DOM_caseId__c = caseRecord.Id;
            }
            
            caseExtension.DOC_toAnalyse__c = totalDocuments;
            caseExtension.DOC_status__c = 'Pending';
            caseExtension.DOC_analysedOK__c = 0;
            caseExtension.DOC_analysedKO__c = 0;
            
            upsert caseExtension;
            
            return caseExtension;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating document analysis information: ' + e.getMessage());
            throw new DOM_CaseExtensionServiceException('Failed to update document analysis information: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Updates progress metrics for document analysis
     * @param caseExtensionId The ID of the case extension to update
     * @param isSuccess Whether the analysis was successful
     * @return DOM_CaseExtension__c The updated case extension record
     * @throws IllegalArgumentException When caseExtensionId is null
     * @throws DOM_CaseExtensionServiceException When there's an error during the operation
     */
    public static DOM_CaseExtension__c updateDocumentInformationProgress(Id caseExtensionId, Boolean isSuccess) {
        if (caseExtensionId == null) {
            throw new IllegalArgumentException('Case Extension ID cannot be null');
        }
        
        try {
            DOM_CaseExtension__c caseExtension = getCaseExtensionById(caseExtensionId);
            
            if (caseExtension == null) {
                throw new DOM_CaseExtensionServiceException('Case Extension not found: ' + caseExtensionId);
            }
            
            if (isSuccess) {
                caseExtension.DOC_analysedOK__c = (caseExtension.DOC_analysedOK__c == null ? 0 : caseExtension.DOC_analysedOK__c) + 1;
            } else {
                caseExtension.DOC_analysedKO__c = (caseExtension.DOC_analysedKO__c == null ? 0 : caseExtension.DOC_analysedKO__c) + 1;
            }
            
            updateCompletionStatus(caseExtension);
            update caseExtension;
            
            return caseExtension;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating document analysis progress: ' + e.getMessage());
            throw new DOM_CaseExtensionServiceException('Failed to update document analysis progress: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Retrieves a case extension by ID
     * @param caseExtensionId The ID of the case extension
     * @return DOM_CaseExtension__c The case extension record, or null if not found
     */
    private static DOM_CaseExtension__c getCaseExtensionById(Id caseExtensionId) {
        List<DOM_CaseExtension__c> caseExtensions = [
            SELECT Id, DOC_analysedOK__c, DOC_analysedKO__c, DOC_status__c, DOC_toAnalyse__c
            FROM DOM_CaseExtension__c 
            WHERE Id = :caseExtensionId
            LIMIT 1
        ];
        
        return caseExtensions.isEmpty() ? null : caseExtensions[0];
    }
    
    /**
     * @description Updates the completion status based on progress
     * @param caseExtension The case extension to update
     */
    private static void updateCompletionStatus(DOM_CaseExtension__c caseExtension) {
        Integer totalToAnalyse = caseExtension.DOC_toAnalyse__c != null ? Integer.valueOf(caseExtension.DOC_toAnalyse__c) : 0;
        Integer analysedOK = caseExtension.DOC_analysedOK__c != null ? Integer.valueOf(caseExtension.DOC_analysedOK__c) : 0;
        Integer analysedKO = caseExtension.DOC_analysedKO__c != null ? Integer.valueOf(caseExtension.DOC_analysedKO__c) : 0;
        
        if (analysedOK + analysedKO >= totalToAnalyse) {
            caseExtension.DOC_status__c = 'Completed';
        } else if (analysedOK + analysedKO > 0) {
            caseExtension.DOC_status__c = 'In Progress';
        }
    }

    /**
     * @description Retrieves a JSON snapshot of CaseExtension with associated ContentDocumentExtensions by Case ID
     * @param caseId The ID of the Case to get snapshot for
     * @return String JSON representation of CaseExtension with associated ContentDocumentExtensions
     * @throws IllegalArgumentException When caseId is null
     * @throws DOM_CaseExtensionServiceException When there's an error during the operation
     */
    public static String getSnapshotForCaseExtension(Id caseId) {
        if (caseId == null) {
            throw new IllegalArgumentException('Case ID cannot be null');
        }
        
        try {
            List<DOM_CaseExtension__c> caseExtensions = [
                SELECT Id, Name, DOM_caseId__c, DOM_Status__c, CreatedDate, LastModifiedDate,
                       SPAM_isSpam__c, SPAM_Reason__c, SPAM_Accuracy__c,
                       LANG_lang__c, LANG_reason__c, LANG_accuracy__c,
                       DRV_isDerivated__c, DRV_derivatedTo__c, DRV_Reason__c, DRV_Accuracy__c,
                       DOC_toAnalyse__c, DOC_status__c, DOC_analysedOK__c, DOC_analysedKO__c
                FROM DOM_CaseExtension__c 
                WHERE DOM_caseId__c = :caseId
                LIMIT 1
            ];
            
            if (caseExtensions.isEmpty()) {
                return buildEmptyCaseExtensionJson(caseId);
            }
            
            DOM_CaseExtension__c caseExtension = caseExtensions[0];
            String documentExtensionsJson = DOC_ContentDocumentExtensionService.getSnapshotForCaseExtension(caseId);
            
            return buildCaseExtensionJson(caseExtension, documentExtensionsJson);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving CaseExtension snapshot: ' + e.getMessage());
            throw new DOM_CaseExtensionServiceException('Failed to retrieve CaseExtension snapshot: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Builds JSON representation of CaseExtension with document extensions
     * @param caseExtension The CaseExtension record
     * @param documentExtensionsJson JSON representation of document extensions
     * @return String JSON representation
     */
    private static String buildCaseExtensionJson(DOM_CaseExtension__c caseExtension, String documentExtensionsJson) {
        Map<String, Object> snapshot = new Map<String, Object>();
        

        snapshot.put('id', caseExtension.Id);
        snapshot.put('name', caseExtension.Name);
        snapshot.put('caseId', caseExtension.DOM_caseId__c);
        snapshot.put('status', caseExtension.DOM_Status__c);
        snapshot.put('createdDate', caseExtension.CreatedDate);
        snapshot.put('lastModifiedDate', caseExtension.LastModifiedDate);
        

        Map<String, Object> spamAnalysis = new Map<String, Object>();
        spamAnalysis.put('isSpam', caseExtension.SPAM_isSpam__c);
        spamAnalysis.put('reason', caseExtension.SPAM_Reason__c);
        spamAnalysis.put('accuracy', caseExtension.SPAM_Accuracy__c);
        snapshot.put('spamAnalysis', spamAnalysis);
        

        Map<String, Object> languageAnalysis = new Map<String, Object>();
        languageAnalysis.put('language', caseExtension.LANG_lang__c);
        languageAnalysis.put('reason', caseExtension.LANG_reason__c);
        languageAnalysis.put('accuracy', caseExtension.LANG_accuracy__c);
        snapshot.put('languageAnalysis', languageAnalysis);
        

        Map<String, Object> derivationAnalysis = new Map<String, Object>();
        derivationAnalysis.put('isDerivated', caseExtension.DRV_isDerivated__c);
        derivationAnalysis.put('derivatedTo', caseExtension.DRV_derivatedTo__c);
        derivationAnalysis.put('reason', caseExtension.DRV_Reason__c);
        derivationAnalysis.put('accuracy', caseExtension.DRV_Accuracy__c);
        snapshot.put('derivationAnalysis', derivationAnalysis);
        

        Map<String, Object> documentAnalysis = new Map<String, Object>();
        documentAnalysis.put('toAnalyse', caseExtension.DOC_toAnalyse__c);
        documentAnalysis.put('status', caseExtension.DOC_status__c);
        documentAnalysis.put('analysedOK', caseExtension.DOC_analysedOK__c);
        documentAnalysis.put('analysedKO', caseExtension.DOC_analysedKO__c);
        snapshot.put('documentAnalysis', documentAnalysis);
        
        Map<String, Object> documentExtensions = (Map<String, Object>) JSON.deserializeUntyped(documentExtensionsJson);
        snapshot.put('contentDocumentExtensions', documentExtensions);
        
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
     * @description Safely converts a decimal to a displayable format
     * @param value The decimal value to convert
     * @return String Formatted decimal or 'N/A' if null
     */
    private static String getSafeDecimal(Decimal value) {
        return value != null ? String.valueOf(value) : 'N/A';
    }
    
    /**
     * @description Builds empty JSON representation when no CaseExtension is found
     * @param caseId The Case ID for the snapshot
     * @return String Empty JSON representation
     */
    private static String buildEmptyCaseExtensionJson(Id caseId) {
        Map<String, Object> snapshot = new Map<String, Object>();
        
        snapshot.put('id', null);
        snapshot.put('name', null);
        snapshot.put('caseId', caseId);
        snapshot.put('status', 'No CaseExtension found for this Case');
        snapshot.put('createdDate', null);
        snapshot.put('lastModifiedDate', null);
        

        Map<String, Object> spamAnalysis = new Map<String, Object>();
        spamAnalysis.put('isSpam', null);
        spamAnalysis.put('reason', null);
        spamAnalysis.put('accuracy', null);
        snapshot.put('spamAnalysis', spamAnalysis);
        
        Map<String, Object> languageAnalysis = new Map<String, Object>();
        languageAnalysis.put('language', null);
        languageAnalysis.put('reason', null);
        languageAnalysis.put('accuracy', null);
        snapshot.put('languageAnalysis', languageAnalysis);
        
        Map<String, Object> derivationAnalysis = new Map<String, Object>();
        derivationAnalysis.put('isDerivated', null);
        derivationAnalysis.put('derivatedTo', null);
        derivationAnalysis.put('reason', null);
        derivationAnalysis.put('accuracy', null);
        snapshot.put('derivationAnalysis', derivationAnalysis);
        
        Map<String, Object> documentAnalysis = new Map<String, Object>();
        documentAnalysis.put('toAnalyse', null);
        documentAnalysis.put('status', null);
        documentAnalysis.put('analysedOK', null);
        documentAnalysis.put('analysedKO', null);
        snapshot.put('documentAnalysis', documentAnalysis);
        
        String documentExtensionsJson = DOC_ContentDocumentExtensionService.getSnapshotForCaseExtension(caseId);
        Map<String, Object> documentExtensions = (Map<String, Object>) JSON.deserializeUntyped(documentExtensionsJson);
        snapshot.put('contentDocumentExtensions', documentExtensions);
        
        return JSON.serialize(snapshot);
    }

    /**
     * @description Retrieves CaseExtension with associated ContentDocumentExtensions by Case ID
     * @param caseId The ID of the Case to get CaseExtension and ContentDocumentExtensions for
     * @return DOM_CaseExtension__c CaseExtension instance with associated ContentDocumentExtensions
     * @throws IllegalArgumentException When caseId is null
     * @throws DOM_CaseExtensionServiceException When there's an error during the operation
     */
    public static DOM_CaseExtension__c getCaseExtensionWithDocuments(Id caseId) {
        if (caseId == null) {
            throw new IllegalArgumentException('Case ID cannot be null');
        }
        
        try {
            List<DOM_CaseExtension__c> caseExtensions = [
                SELECT Id, Name, DOM_caseId__c, DOM_Status__c, CreatedDate, LastModifiedDate,
                       SPAM_isSpam__c, SPAM_Reason__c, SPAM_Accuracy__c,
                       LANG_lang__c, LANG_reason__c, LANG_accuracy__c,
                       DRV_isDerivated__c, DRV_derivatedTo__c, DRV_Reason__c, DRV_Accuracy__c,
                       DOC_toAnalyse__c, DOC_status__c, DOC_analysedOK__c, DOC_analysedKO__c,
                       (SELECT Id, Name, DOC_contentDocumentId__c, DOC_type__c, DOC_reason__c, 
                               DOC_accuracy__c, DOC_summary__c, DOC_status__c, CreatedDate, 
                               LastModifiedDate, DOM_caseExtension__c
                        FROM Content_Document_Extensions__r
                        ORDER BY CreatedDate DESC)
                FROM DOM_CaseExtension__c 
                WHERE DOM_caseId__c = :caseId
                LIMIT 1
            ];
            
            if (caseExtensions.isEmpty()) {
                return null;
            }
            
            return caseExtensions[0];
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving CaseExtension with documents: ' + e.getMessage());
            throw new DOM_CaseExtensionServiceException('Failed to retrieve CaseExtension with documents: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Updates aggregated entity information for a case extension
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
     * @throws DOM_CaseExtensionServiceException When there's an error during the operation
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
            List<DOM_CaseExtension__c> existingExtensions = [
                SELECT Id, DOM_caseId__c, ENT_claimant1__c, ENT_claimant1Reason__c,
                       ENT_claimant2__c, ENT_claimant2Reason__c, ENT_representative__c, ENT_representativeReason__c,
                       ENT_firm__c, ENT_firmReason__c, ENT_others__c, ENT_othersReason__c
                FROM DOM_CaseExtension__c 
                WHERE DOM_caseId__c = :caseRecord.Id
                LIMIT 1
            ];
            
            DOM_CaseExtension__c caseExtension;
            
            if (!existingExtensions.isEmpty()) {
                caseExtension = existingExtensions[0];
            } else {
                caseExtension = new DOM_CaseExtension__c();
                caseExtension.DOM_caseId__c = caseRecord.Id;
            }
            
            caseExtension.ENT_claimant1__c = claimant1;
            caseExtension.ENT_claimant1Reason__c = claimant1Reason;
            caseExtension.ENT_claimant2__c = claimant2;
            caseExtension.ENT_claimant2Reason__c = claimant2Reason;
            caseExtension.ENT_representative__c = representative;
            caseExtension.ENT_representativeReason__c = representativeReason;
            caseExtension.ENT_firm__c = firm;
            caseExtension.ENT_firmReason__c = firmReason;
            caseExtension.ENT_others__c = others;
            caseExtension.ENT_othersReason__c = othersReason;
            caseExtension.DOM_Status__c = 'ENT';
            
            upsert caseExtension;
            
            return caseExtension;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating aggregated entity information: ' + e.getMessage());
            throw new DOM_CaseExtensionServiceException('Failed to update aggregated entity information: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Custom exception class for DOM_CaseExtensionService
     */
    public class DOM_CaseExtensionServiceException extends Exception {}

    /**
     * @description Retrieves AI metrics for a given case
     * @param aCase The case record to retrieve AI metrics for
     * @return DOM_CaseExtension__c The case extension record with AI metrics
     * @throws IllegalArgumentException When aCase is null or aCase.Id is null
     * @throws DOM_CaseExtensionServiceException When there's an error during the operation
     */
    public static DOM_CaseExtension__c retrieveAIMetricsByCase(Case aCase) {
        if (aCase == null || aCase.Id == null) {
            throw new IllegalArgumentException('Case record cannot be null and must have an Id');
        }

        try {
            List<DOM_CaseExtension__c> existingExtensions = [
                SELECT Id, DOM_caseId__c, SPAM_isSpam__c, SPAM_Reason__c, SPAM_Accuracy__c,
                          LANG_lang__c, LANG_reason__c, LANG_accuracy__c, 
                          DRV_isDerivated__c, DRV_derivatedTo__c, DRV_Reason__c, DRV_Accuracy__c,
                          DOM_Status__c
                FROM DOM_CaseExtension__c 
                WHERE DOM_caseId__c = :aCase.Id
                LIMIT 1
            ];

            if (!existingExtensions.isEmpty()) {
                return existingExtensions[0];
            } else {
                return null;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving AI metrics: ' + e.getMessage());
            throw new DOM_CaseExtensionServiceException('Failed to retrieve AI metrics: ' + e.getMessage(), e);
        }
    }
}