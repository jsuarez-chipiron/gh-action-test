/**
 * @description Service class for EmailMessage object operations
 */
public with sharing class DOM_EmailMessageService {
    
    /**
     * @description Retrieves email messages related to a specific case for snapshot
     * @param caseId The Case ID to get emails for
     * @return String JSON representation of email messages
     * @throws IllegalArgumentException When caseId is null
     * @throws DOM_EmailMessageServiceException When there's an error during the operation
     */
    public static String getSnapshotForCase(Id caseId) {
        if (caseId == null) {
            throw new IllegalArgumentException('Case ID cannot be null');
        }
        
        try {
            List<EmailMessage> emailMessages = [
                SELECT Id, Subject, TextBody, HtmlBody, FromAddress, ToAddress, 
                       CcAddress, BccAddress, MessageDate, Status, Incoming,
                       CreatedDate, LastModifiedDate
                FROM EmailMessage 
                WHERE RelatedToId = :caseId 
                AND Incoming = true
                ORDER BY CreatedDate DESC
            ];
            
            return buildEmailMessagesJson(emailMessages, caseId);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving email messages snapshot: ' + e.getMessage());
            throw new DOM_EmailMessageServiceException('Failed to retrieve email messages snapshot: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Builds JSON representation of email messages
     * @param emailMessages List of email messages to convert to JSON
     * @param caseId The Case ID for the snapshot
     * @return String JSON representation of the email messages
     */
    private static String buildEmailMessagesJson(List<EmailMessage> emailMessages, Id caseId) {
        Map<String, Object> snapshot = new Map<String, Object>();
        snapshot.put('caseId', caseId);
        snapshot.put('totalEmails', emailMessages.size());
        
        List<Map<String, Object>> emails = new List<Map<String, Object>>();
        for (EmailMessage email : emailMessages) {
            Map<String, Object> emailMap = new Map<String, Object>();
            emailMap.put('id', email.Id);
            emailMap.put('subject', email.Subject);
            emailMap.put('textBody', email.TextBody);
            emailMap.put('htmlBody', email.HtmlBody);
            emailMap.put('fromAddress', email.FromAddress);
            emailMap.put('toAddress', email.ToAddress);
            emailMap.put('ccAddress', email.CcAddress);
            emailMap.put('bccAddress', email.BccAddress);
            emailMap.put('messageDate', email.MessageDate);
            emailMap.put('status', email.Status);
            emailMap.put('incoming', email.Incoming);
            emailMap.put('createdDate', email.CreatedDate);
            emailMap.put('lastModifiedDate', email.LastModifiedDate);
            emails.add(emailMap);
        }
        
        snapshot.put('emails', emails);
        
        return JSON.serialize(snapshot);
    }
    
    /**
     * @description Custom exception class for DOM_EmailMessageService
     */
    public class DOM_EmailMessageServiceException extends Exception {}
}
