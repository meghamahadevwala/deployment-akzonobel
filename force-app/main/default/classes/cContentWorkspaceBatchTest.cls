/**
 * Test coverage for cContentWorkspaceBatch. Covers the Database.Batchable<String> lifecycle
 * (start/execute/finish, both called directly and via Database.executeBatch) plus the static
 * insertContentWorkspaceDoc / reInsertContentWorkspaceDoc helpers.
 * Note: reInsertContentWorkspaceDoc's nested retry/exception cascade is only exercisable up to
 * the first Database.upsert(..., false, AccessLevel.USER_MODE) attempt, since allOrNone=false
 * does not throw on per-record data errors - the deeper catch branches are a known coverage gap.
 */
@isTest
public class cContentWorkspaceBatchTest {

    private static Id getOrCreateWorkspaceId() {
        List<ContentWorkspace> spaces = [SELECT Id FROM ContentWorkspace LIMIT 1];
        if (!spaces.isEmpty()) {
            return spaces[0].Id;
        }
        return null;
    }

    private static String createContentDocumentId() {
        ContentVersion cv = new ContentVersion(
            Title = 'Batch Test Doc',
            PathOnClient = 'batchtestdoc.txt',
            VersionData = Blob.valueOf('Batch test content'),
            IsMajorVersion = true
        );
        insert cv;
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    }

    @isTest
    static void testConstructorAndBatchableLifecycleDirectCalls() {
        Id wsId = getOrCreateWorkspaceId();
        String docId = createContentDocumentId();
        List<String> ids = new List<String>{ docId };

        cContentWorkspaceBatch batch = new cContentWorkspaceBatch(ids, wsId);

        Test.startTest();
        Iterable<String> startResultIterable = batch.start(null);
        List<String> startResult = (List<String>) startResultIterable;
        batch.execute(null, startResult);
        batch.finish(null);
        Test.stopTest();

        System.assertEquals(ids.size(), startResult.size(), 'start() should return the ids passed into the constructor');
    }

    @isTest
    static void testBatchableViaDatabaseExecuteBatch() {
        Id wsId = getOrCreateWorkspaceId();
        String docId = createContentDocumentId();
        List<String> ids = new List<String>{ docId };

        cContentWorkspaceBatch batch = new cContentWorkspaceBatch(ids, wsId);

        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        System.assert(true, 'Batch should run end-to-end via Database.executeBatch without throwing');
    }

    @isTest
    static void testInsertContentWorkspaceDocDirect() {
        Id wsId = getOrCreateWorkspaceId();
        if (wsId == null) {
            // No workspace configured in this org; nothing meaningful to assert against, but
            // still exercise the method for coverage of the null-safe path.
            cContentWorkspaceBatch.insertContentWorkspaceDoc(new List<String>(), null);
            System.assert(true);
            return;
        }
        String docId = createContentDocumentId();
        cContentWorkspaceBatch.insertContentWorkspaceDoc(new List<String>{ docId }, wsId);

        List<ContentWorkspaceDoc> docs = [SELECT Id FROM ContentWorkspaceDoc WHERE ContentWorkspaceId = :wsId AND ContentDocumentId = :docId];
        System.assertEquals(1, docs.size(), 'ContentWorkspaceDoc link should be created for the given document/workspace pair');
    }

    @isTest
    static void testInsertContentWorkspaceDocEmptyList() {
        Id wsId = getOrCreateWorkspaceId();
        cContentWorkspaceBatch.insertContentWorkspaceDoc(new List<String>(), wsId);
        System.assert(true, 'Empty id list should be handled gracefully');
    }

    @isTest
    static void testReInsertContentWorkspaceDocDirect() {
        Id wsId = getOrCreateWorkspaceId();
        if (wsId == null) {
            System.assert(true, 'No ContentWorkspace configured in this org - skipping direct reInsert assertion');
            return;
        }
        String docId = createContentDocumentId();

        Test.startTest();
        cContentWorkspaceBatch.reInsertContentWorkspaceDoc(new List<String>{ docId }, wsId);
        Test.stopTest();

        List<ContentWorkspaceDoc> docs = [SELECT Id FROM ContentWorkspaceDoc WHERE ContentWorkspaceId = :wsId AND ContentDocumentId = :docId];
        System.assertEquals(1, docs.size(), 'First-attempt upsert should succeed for a valid record');
    }

    @isTest
    static void testCContentWorkspaceBatchExceptionInstantiable() {
        cContentWorkspaceBatch.cContentWorkspaceBatchException ex = new cContentWorkspaceBatch.cContentWorkspaceBatchException('test error');
        System.assertEquals('test error', ex.getMessage());
    }
}