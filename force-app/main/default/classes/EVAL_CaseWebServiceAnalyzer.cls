/**
 * REST service for analyzing cases and returning relevant information.
 * Allows executing different types of analysis (DOC, SPAM, LANG, DRV, ENT) on specific cases.
 * 
 * HTTP Error Codes:
 * - 400 Bad Request: Missing case ID or invalid analysis type
 * - 404 Not Found: Case not found in the system
 * - 500 Internal Server Error: Internal server error during processing
 */
@RestResource(urlMapping='/EVAL_CaseWebServiceAnalyzer/*')
global with sharing class EVAL_CaseWebServiceAnalyzer {
    
    /**
     * HTTP GET method that analyzes a specific case and returns its information.
     * 
     * @description Executes the specified analysis type on the case and returns
     *              the case information along with the analysis results.
     * 
     * @param caseId ID of the case to analyze (extracted from URL)
     * @param analysisType Type of analysis to perform (DOC, SPAM, LANG, DRV, ENT, ENT_AGG)
     * 
     * @return JSON response with case details and analysis results
     * 
     * @throws 400 Bad Request when:
     *         - caseId is not provided or is empty
     *         - analysisType is not provided or is invalid
     *         - analysisType is not one of: DOC, SPAM, LANG, DRV, ENT, ENT_AGG
     * 
     * @throws 404 Not Found when:
     *         - The provided caseId does not correspond to any existing case
     * 
     * @throws 500 Internal Server Error when:
     *         - An unexpected exception occurs during processing
     *         - Database query error
     *         - JSON response serialization error
     * 
     * @example
     * GET /services/apexrest/EVAL_CaseWebServiceAnalyzer/500KK000001csnRYAQ?analysisType=ENT
     * 
     * Successful response (200):
     * {
     *   "caseId": "500KK000001csnRYAQ",
     *   "caseExtension": { ... },
     *   "caseNumber": "64616370",
     *   "subject": "Case subject",
     *   "status": "Closed",
     *   "analysisType": "ENT",
     *   "analysisStatus": "success",
     *   "analysisMessage": "Entity analysis initiated"
     * }
     */
    @HttpGet
    global static void getCase() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String caseId = extractCaseIdFromRequest(req);
            String analysisType = extractAnalysisTypeFromRequest(req);
            
            if (isInvalidCaseId(caseId)) {
                sendErrorResponse(res, 400, 'ID de caso requerido');
                return;
            }
            
            if (isInvalidAnalysisType(analysisType)) {
                sendErrorResponse(res, 400, 'Tipo de análisis requerido. Valores válidos: DOC, SPAM, LANG, DRV, ENT, ENT_AGG');
                return;
            }
            
            Case caseRecord = retrieveCaseById(caseId);
            
            if (isCaseNotFound(caseRecord)) {
                sendErrorResponse(res, 404, 'Caso no encontrado');
                return;
            }
            
            AnalysisResult analysisResult = performAnalysisByType(caseRecord, analysisType);
            Map<String, Object> responseData = buildResponseData(caseRecord, analysisResult, analysisType);
            
            sendSuccessResponse(res, responseData);
            
        } catch (Exception e) {
            sendErrorResponse(res, 500, 'Error interno: ' + e.getMessage());
        }
    }
    
    private static String extractCaseIdFromRequest(RestRequest req) {
        return req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
    }
    
    private static String extractAnalysisTypeFromRequest(RestRequest req) {
        return req.params.get('analysisType');
    }
    
    private static Boolean isInvalidCaseId(String caseId) {
        return caseId == null || caseId == '';
    }
    
    private static Boolean isInvalidAnalysisType(String analysisType) {
        if (String.isBlank(analysisType)) {
            return true;
        }
        Set<String> validTypes = new Set<String>{'DOC', 'SPAM', 'LANG', 'DRV', 'ENT', 'ENT_AGG'};
        return !validTypes.contains(analysisType.toUpperCase());
    }
    
    private static Case retrieveCaseById(String caseId) {
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Status, Description 
            FROM Case 
            WHERE Id = :caseId 
            LIMIT 1
        ];
        return cases.isEmpty() ? null : cases[0];
    }
    
    private static Boolean isCaseNotFound(Case caseRecord) {
        return caseRecord == null;
    }
    
    private static AnalysisResult performAnalysisByType(Case caseRecord, String analysisType) {
        AnalysisResult result = new AnalysisResult();
        result.status = 'success';
        result.message = getAnalysisMessage(analysisType);
        result.caseExtension = null;
        
        try {
            switch on analysisType.toUpperCase() {
                when 'DOC' {
                    result.caseExtension = DOC_DocumentService.analyzeForDocumentsAndPersist(caseRecord);
                }
                when 'SPAM' {
                    result.caseExtension = SPAM_SpamService.analyzeForSpamAndPersist(caseRecord);
                }
                when 'LANG' {
                    result.caseExtension = LANG_LangService.analyzeForLanguageAndPersist(caseRecord);
                }
                when 'DRV' {
                    result.caseExtension = DRV_CaseDerivationService.analyzeForDerivationAndPersist(caseRecord);
                }
                when 'ENT' {
                    result.caseExtension = ENT_EntityService.analyzeForEntitiesAndPersist(caseRecord);
                }
                when 'ENT_AGG' {
                    result.caseExtension = ENT_EntityService.analyzeAggregatedEntities(caseRecord);
                }
            }
        } catch (Exception analysisException) {
            result.status = 'error';
            result.message = 'Error en análisis ' + analysisType + ': ' + analysisException.getMessage();
        }
        
        return result;
    }
    
    private static String getAnalysisMessage(String analysisType) {
        switch on analysisType.toUpperCase() {
            when 'DOC' {
                return 'Análisis de documentos iniciado';
            }
            when 'SPAM' {
                return 'Análisis de spam completado';
            }
            when 'LANG' {
                return 'Análisis de idioma completado';
            }
            when 'DRV' {
                return 'Análisis de derivación completado';
            }
            when 'ENT' {
                return 'Análisis de entidades iniciado';
            }
            when 'ENT_AGG' {
                return 'Análisis agregado de entidades completado';
            }
            when else {
                return 'Análisis completado';
            }
        }
    }
    
    private static Map<String, Object> buildResponseData(Case caseRecord, AnalysisResult analysisResult, String analysisType) {
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put('caseId', caseRecord.Id);
        responseMap.put('caseExtension', analysisResult.caseExtension);
        responseMap.put('caseNumber', caseRecord.CaseNumber);
        responseMap.put('subject', caseRecord.Subject);
        responseMap.put('status', caseRecord.Status);
        responseMap.put('analysisType', analysisType.toUpperCase());
        responseMap.put('analysisStatus', analysisResult.status);
        responseMap.put('analysisMessage', analysisResult.message);
        return responseMap;
    }
    
    private static void sendSuccessResponse(RestResponse res, Map<String, Object> data) {
        String jsonResponse = JSON.serialize(data);
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(jsonResponse);
    }
    
    private static void sendErrorResponse(RestResponse res, Integer statusCode, String errorMessage) {
        Map<String, Object> errorMap = new Map<String, Object>();
        errorMap.put('error', true);
        errorMap.put('message', errorMessage);
        errorMap.put('statusCode', statusCode);
        
        String jsonResponse = JSON.serialize(errorMap);
        res.statusCode = statusCode;
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(jsonResponse);
    }
    
    private class AnalysisResult {
        public String status;
        public String message;
        public DOM_CaseExtension__c caseExtension;
    }
}
