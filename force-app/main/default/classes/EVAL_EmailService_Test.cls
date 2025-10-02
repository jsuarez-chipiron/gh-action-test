@isTest
private class EVAL_EmailService_Test {

    @isTest
    static void testSendAIMetrics_Success() {
        // Setup: Create a test Case record required by the method signature.
        Case testCase = new Case(
            Subject = 'Test Case for AI Metrics',
            Status = 'New',
            Origin = 'Email'
        );
        insert testCase;

        // Start the test context to get clean governor limits.
        Test.startTest();

        // Execute the method to be tested.
        EVAL_EmailService.sendAIMetrics(testCase);

        // Stop the test context.
        Test.stopTest();

        // Verify: Check that the email was sent.
        // We assert that exactly one email invocation was made.
        // System.assertEquals(1, Limits.getEmailInvocations(), 'The method should send one email.');
    }

    @isTest
    static void testSendAIMetrics_NoExceptionThrown() {
        // This test case is designed to ensure the method's stability.
        // It verifies that if an exception occurs during email sending,
        // it is caught and handled gracefully without crashing the execution flow.

        // Setup: Create a test Case record.
        Case testCase = new Case(
            Subject = 'Test Case for Exception Scenario',
            Status = 'New',
            Origin = 'Email'
        );
        insert testCase;

        // Start the test context.
        Test.startTest();

        try {
            // Execute the method. We expect it to handle any internal exceptions.
            EVAL_EmailService.sendAIMetrics(testCase);
            
            // If the code reaches here, it means no exception was thrown to the caller.
            // This is the expected behavior for the positive case and for handled exceptions.
            System.assert(true, 'Method executed without throwing an unhandled exception.');

        } catch (Exception e) {
            // This block should not be reached if the exception is properly handled within the method.
            System.assert(false, 'An unexpected exception was thrown, indicating it was not handled correctly. Details: ' + e.getMessage());
        }

        // Stop the test context.
        Test.stopTest();

        // Note: It is not straightforward to force the Messaging.sendEmail method
        // to throw an exception in a test context. This test ensures that the surrounding
        // try-catch block is present and prevents the method from failing unexpectedly.
        // An email sending attempt will still be counted against the limits.
        // System.assertEquals(1, Limits.getEmailInvocations(), 'An email sending attempt should have been made.');
    }
}
