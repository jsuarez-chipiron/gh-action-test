/**
 * @description Batch Apex class to analyze cases using various services.
 * This batch processes cases in batches of size 1 and calls configurable services
 * to analyze each case based on configuration.
 */
global class EVAL_CaseBatchAnalyzer implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    // Configuration for which services to run
    private Set<String> enabledServices;
    
    // Optional list of specific case IDs to process
    private Set<Id> specificCaseIds;
    
    /**
     * @description Constructor with custom services enabled
     * @param services Set of services to enable ('SPAM', 'LANG', etc.)
     */
    global EVAL_CaseBatchAnalyzer(Set<String> services) {
        this.enabledServices = new Set<String>(services);
        this.specificCaseIds = null;
    }
    
    /**
     * @description Constructor with custom services enabled and specific case IDs
     * @param services Set of services to enable ('SPAM', 'LANG', etc.)
     * @param caseIds Set of specific case IDs to process (optional, null for all cases)
     */
    global EVAL_CaseBatchAnalyzer(Set<String> services, Set<Id> caseIds) {
        this.enabledServices = new Set<String>(services);
        this.specificCaseIds = caseIds != null ? new Set<Id>(caseIds) : null;
    }
    
    /**
     * @description Constructor with default services enabled
     */
    global EVAL_CaseBatchAnalyzer() {
        this(new Set<String>{'SPAM', 'LANG', 'DRV', 'DOC'});
    }
    
    /**
     * @description Constructor with default services and specific case IDs
     * @param caseIds Set of specific case IDs to process (optional, null for all cases)
     */
    global EVAL_CaseBatchAnalyzer(Set<Id> caseIds) {
        this(new Set<String>{'SPAM', 'LANG', 'DRV', 'DOC'}, caseIds);
    }
    
    /**
     * @description Start method that returns a query locator for cases.
     * Retrieves cases with Id, Subject, and Description fields.
     * 
     * @param bc The batchable context
     * @return Database.QueryLocator Query locator for cases
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Subject, Description FROM Case';
        if (specificCaseIds != null && !specificCaseIds.isEmpty()) {
            query += ' WHERE Id IN :specificCaseIds';
        }
        return Database.getQueryLocator(query);
    }
    
    /**
     * @description Execute method that processes each batch of cases.
     * For each case, calls the enabled services based on configuration.
     * 
     * @param bc The batchable context
     * @param caseList List of cases to process
     */
    global void execute(Database.BatchableContext bc, List<Case> caseList) {
        for (Case caseRecord : caseList) {
            if (enabledServices.contains('SPAM')) {
                SPAM_SpamService.analyzeForSpamAndPersist(caseRecord);
            }
            
            if (enabledServices.contains('LANG')) {
                LANG_LangService.analyzeForLanguageAndPersist(caseRecord);
            }
            
            if (enabledServices.contains('DRV')) {
                DRV_CaseDerivationService.analyzeForDerivationAndPersist(caseRecord);
            }
            
            if (enabledServices.contains('DOC')) {
                DOC_DocumentService.analyzeForDocumentsAndPersist(caseRecord);
            }
        }
    }
    
    /**
     * @description Finish method that executes after all batches are processed.
     * Can be used for post-processing tasks like sending notifications.
     * 
     * @param bc The batchable context
     */
    global void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'Case Analysis Batch completed successfully with services: ' + enabledServices);
    }
    
    /**
     * @description Get the currently enabled services
     * @return Set<String> Set of enabled service names
     */
    global Set<String> getEnabledServices() {
        return new Set<String>(enabledServices);
    }
    
    /**
     * @description Enable a specific service
     * @param serviceName Name of the service to enable
     */
    global void enableService(String serviceName) {
        enabledServices.add(serviceName);
    }
    
    /**
     * @description Disable a specific service
     * @param serviceName Name of the service to disable
     */
    global void disableService(String serviceName) {
        enabledServices.remove(serviceName);
    }
    
    /**
     * @description Execute batch with all services enabled
     * @param batchSize Size of each batch (default: 1)
     */
    global static Id executeWithAllServices(Integer batchSize) {
        EVAL_CaseBatchAnalyzer batch = new EVAL_CaseBatchAnalyzer();
        return Database.executeBatch(batch, batchSize != null ? batchSize : 1);
    }
    
    /**
     * @description Execute batch with only SPAM analysis
     * @param batchSize Size of each batch (default: 1)
     */
    global static Id executeSpamOnly(Integer batchSize) {
        EVAL_CaseBatchAnalyzer batch = new EVAL_CaseBatchAnalyzer(new Set<String>{'SPAM'});
        return Database.executeBatch(batch, batchSize != null ? batchSize : 1);
    }
    
    /**
     * @description Execute batch with only Language analysis
     * @param batchSize Size of each batch (default: 1)
     */
    global static Id executeLanguageOnly(Integer batchSize) {
        EVAL_CaseBatchAnalyzer batch = new EVAL_CaseBatchAnalyzer(new Set<String>{'LANG'});
        return Database.executeBatch(batch, batchSize != null ? batchSize : 1);
    }
    
    /**
     * @description Execute batch with only Derivation analysis
     * @param batchSize Size of each batch (default: 1)
     */
    global static Id executeDerivationOnly(Integer batchSize) {
        EVAL_CaseBatchAnalyzer batch = new EVAL_CaseBatchAnalyzer(new Set<String>{'DRV'});
        return Database.executeBatch(batch, batchSize != null ? batchSize : 1);
    }
    
    /**
     * @description Execute batch with only Document analysis
     * @param batchSize Size of each batch (default: 1)
     */
    global static Id executeDocumentOnly(Integer batchSize) {
        EVAL_CaseBatchAnalyzer batch = new EVAL_CaseBatchAnalyzer(new Set<String>{'DOC'});
        return Database.executeBatch(batch, batchSize != null ? batchSize : 1);
    }
    
    /**
     * @description Execute batch with custom service selection
     * @param services Set of services to enable
     * @param batchSize Size of each batch (default: 1)
     */
    global static Id executeWithCustomServices(Set<String> services, Integer batchSize) {
        EVAL_CaseBatchAnalyzer batch = new EVAL_CaseBatchAnalyzer(services);
        return Database.executeBatch(batch, batchSize != null ? batchSize : 1);
    }
    
    /**
     * @description Execute batch with all services enabled for specific case IDs
     * @param caseIds Set of specific case IDs to process
     * @param batchSize Size of each batch (default: 1)
     */
    global static Id executeWithAllServicesForCases(Set<Id> caseIds, Integer batchSize) {
        EVAL_CaseBatchAnalyzer batch = new EVAL_CaseBatchAnalyzer(caseIds);
        return Database.executeBatch(batch, batchSize != null ? batchSize : 1);
    }
    
    /**
     * @description Execute batch with only SPAM analysis for specific case IDs
     * @param caseIds Set of specific case IDs to process
     * @param batchSize Size of each batch (default: 1)
     */
    global static Id executeSpamOnlyForCases(Set<Id> caseIds, Integer batchSize) {
        EVAL_CaseBatchAnalyzer batch = new EVAL_CaseBatchAnalyzer(new Set<String>{'SPAM'}, caseIds);
        return Database.executeBatch(batch, batchSize != null ? batchSize : 1);
    }
    
    /**
     * @description Execute batch with only Language analysis for specific case IDs
     * @param caseIds Set of specific case IDs to process
     * @param batchSize Size of each batch (default: 1)
     */
    global static Id executeLanguageOnlyForCases(Set<Id> caseIds, Integer batchSize) {
        EVAL_CaseBatchAnalyzer batch = new EVAL_CaseBatchAnalyzer(new Set<String>{'LANG'}, caseIds);
        return Database.executeBatch(batch, batchSize != null ? batchSize : 1);
    }
    
    /**
     * @description Execute batch with only Derivation analysis for specific case IDs
     * @param caseIds Set of specific case IDs to process
     * @param batchSize Size of each batch (default: 1)
     */
    global static Id executeDerivationOnlyForCases(Set<Id> caseIds, Integer batchSize) {
        EVAL_CaseBatchAnalyzer batch = new EVAL_CaseBatchAnalyzer(new Set<String>{'DRV'}, caseIds);
        return Database.executeBatch(batch, batchSize != null ? batchSize : 1);
    }
    
    /**
     * @description Execute batch with only Document analysis for specific case IDs
     * @param caseIds Set of specific case IDs to process
     * @param batchSize Size of each batch (default: 1)
     */
    global static Id executeDocumentOnlyForCases(Set<Id> caseIds, Integer batchSize) {
        EVAL_CaseBatchAnalyzer batch = new EVAL_CaseBatchAnalyzer(new Set<String>{'DOC'}, caseIds);
        return Database.executeBatch(batch, batchSize != null ? batchSize : 1);
    }
    
    /**
     * @description Execute batch with custom services for specific case IDs
     * @param services Set of services to enable
     * @param caseIds Set of specific case IDs to process
     * @param batchSize Size of each batch (default: 1)
     */
    global static Id executeWithCustomServicesForCases(Set<String> services, Set<Id> caseIds, Integer batchSize) {
        EVAL_CaseBatchAnalyzer batch = new EVAL_CaseBatchAnalyzer(services, caseIds);
        return Database.executeBatch(batch, batchSize != null ? batchSize : 1);
    }
}
