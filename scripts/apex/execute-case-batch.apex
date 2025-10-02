// Example script to execute the customizable Case Batch Analyzer
// This script demonstrates different ways to run the batch with various service configurations
// Available services: SPAM (spam detection), LANG (language detection), DRV (case derivation), DOC (document analysis)

// Option 1: Execute with all services enabled (default behavior)
Id batchId1 = EVAL_CaseBatchAnalyzer.executeWithAllServices(1);
System.debug('Batch started with all services: ' + batchId1);

// Option 2: Execute with only SPAM analysis
Id batchId2 = EVAL_CaseBatchAnalyzer.executeSpamOnly(1);
System.debug('Batch started with SPAM only: ' + batchId2);

// Option 3: Execute with only Language analysis
Id batchId3 = EVAL_CaseBatchAnalyzer.executeLanguageOnly(1);
System.debug('Batch started with Language only: ' + batchId3);

// Option 3b: Execute with only Derivation analysis
Id batchId3b = EVAL_CaseBatchAnalyzer.executeDerivationOnly(1);
System.debug('Batch started with Derivation only: ' + batchId3b);

// Option 3c: Execute with only Document analysis
Id batchId3c = EVAL_CaseBatchAnalyzer.executeDocumentOnly(1);
System.debug('Batch started with Document only: ' + batchId3c);

// Option 4: Execute with custom service selection
Set<String> customServices = new Set<String>{'SPAM', 'LANG'};
Id batchId4 = EVAL_CaseBatchAnalyzer.executeWithCustomServices(customServices, 1);
System.debug('Batch started with custom services: ' + batchId4);

// Option 4b: Execute with Document and other services
Set<String> docServices = new Set<String>{'DOC', 'SPAM'};
Id batchId4b = EVAL_CaseBatchAnalyzer.executeWithCustomServices(docServices, 1);
System.debug('Batch started with Document and SPAM services: ' + batchId4b);

// Option 5: Execute with only one specific service
Set<String> singleService = new Set<String>{'SPAM'};
Id batchId5 = EVAL_CaseBatchAnalyzer.executeWithCustomServices(singleService, 1);
System.debug('Batch started with single service: ' + batchId5);

// Option 6: Create instance and modify services dynamically
EVAL_CaseBatchAnalyzer dynamicBatch = new EVAL_CaseBatchAnalyzer();
dynamicBatch.enableService('EVAL'); // Enable additional service if available
dynamicBatch.disableService('LANG'); // Disable a service
Id batchId6 = Database.executeBatch(dynamicBatch, 1);
System.debug('Batch started with dynamic configuration: ' + batchId6);

// Execute batch for specific case IDs
Set<Id> specificCaseIds = new Set<Id>{'500KK000001ctyXYAQ'};

// Option 7: Execute with all services for specific cases
Id batchId7 = EVAL_CaseBatchAnalyzer.executeWithAllServicesForCases(specificCaseIds, 1);
System.debug('Batch started with all services for specific cases: ' + batchId7);

// Option 8: Execute with only SPAM analysis for specific cases
Id batchId8 = EVAL_CaseBatchAnalyzer.executeSpamOnlyForCases(specificCaseIds, 1);
System.debug('Batch started with SPAM only for specific cases: ' + batchId8);

// Option 8b: Execute with only Derivation analysis for specific cases
Id batchId8b = EVAL_CaseBatchAnalyzer.executeDerivationOnlyForCases(specificCaseIds, 1);
System.debug('Batch started with Derivation only for specific cases: ' + batchId8b);

// Option 8c: Execute with only Document analysis for specific cases
Id batchId8c = EVAL_CaseBatchAnalyzer.executeDocumentOnlyForCases(specificCaseIds, 1);
System.debug('Batch started with Document only for specific cases: ' + batchId8c);

// Option 9: Execute with custom services for specific cases
Id batchId9 = EVAL_CaseBatchAnalyzer.executeWithCustomServicesForCases(
    new Set<String>{'SPAM', 'LANG'}, 
    specificCaseIds, 
    1
);
System.debug('Batch started with custom services for specific cases: ' + batchId9);

// Option 9b: Execute with Document and other services for specific cases
Id batchId9b = EVAL_CaseBatchAnalyzer.executeWithCustomServicesForCases(
    new Set<String>{'DOC', 'DRV'}, 
    specificCaseIds, 
    1
);
System.debug('Batch started with Document and Derivation services for specific cases: ' + batchId9b);

// Option 10: Create instance with specific case IDs
EVAL_CaseBatchAnalyzer specificBatch = new EVAL_CaseBatchAnalyzer(specificCaseIds);
Id batchId10 = Database.executeBatch(specificBatch, 1);
System.debug('Batch started with specific cases: ' + batchId10);

System.debug('All batches have been scheduled successfully!');
