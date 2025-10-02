/**
 * @description Apex class for grounding Case data in Prompt Templates
 * This class retrieves complete Case information including CaseExtension and ContentDocumentExtension data
 */
public with sharing class APP_CaseDocumentGrounding {
    
    /**
     * @description Invocable method that retrieves complete Case information for Prompt Templates
     * @param requests List of Request objects containing Case information
     * @return List<Response> List of Response objects with formatted prompt data
     */
    @InvocableMethod
    public static List<Response> getCaseSnapshot(List<Request> requests) {
        Request input = requests[0];
        List<Response> responses = new List<Response>();
        Response output = new Response();
        responses.add(output);
        
        try {
            String caseSnapshot = DOM_CaseService.getSnapshotWithExtension(input.case_1.Id);
            output.Prompt = caseSnapshot;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in APP_CaseDocumentGrounding: ' + e.getMessage());
            output.Prompt = 'Error retrieving case snapshot: ' + e.getMessage();
        }
        
        return responses;
    }
    
    /**
     * @description Request class for the invocable method
     */
    public class Request {
        @InvocableVariable(required=true)
        public Case case;
    }
    
    /**
     * @description Response class for the invocable method
     */
    public class Response {
        @InvocableVariable
        public String Prompt;
    }
}
