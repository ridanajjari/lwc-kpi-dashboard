@IsTest
private class KpiDashboardControllerTest {

    @TestSetup
    static void setup() {
        // Cases
        insert new List<Case>{
            new Case(Subject = 'Open Case 1', Status = 'New',    Origin = 'Email'),
            new Case(Subject = 'Open Case 2', Status = 'New',    Origin = 'Email'),
            new Case(Subject = 'Closed Case', Status = 'Closed', Origin = 'Email')
        };

        // Leads (this month, not converted)
        insert new List<Lead>{
            new Lead(FirstName = 'A', LastName = 'Test', Company = 'Acme'),
            new Lead(FirstName = 'B', LastName = 'Test', Company = 'Acme')
        };

        // Opportunities
        insert new List<Opportunity>{
            new Opportunity(Name = 'Open Deal',      StageName = 'Proposal',    CloseDate = Date.today().addDays(30), Amount = 10000),
            new Opportunity(Name = 'Closed Won Deal',StageName = 'Closed Won',  CloseDate = Date.today(),             Amount = 5000),
            new Opportunity(Name = 'Closed Lost',    StageName = 'Closed Lost', CloseDate = Date.today(),             Amount = 2000)
        };
    }

    @IsTest
    static void testGetKpiDataReturnsCorrectCounts() {
        Test.startTest();
        KpiDashboardController.KpiData data = KpiDashboardController.getKpiData();
        Test.stopTest();

        Assert.isNotNull(data, 'KpiData should not be null');
        Assert.areEqual(2, data.openCases,          'Should count 2 open cases');
        Assert.areEqual(2, data.newLeadsThisMonth,  'Should count 2 new leads this month');
        Assert.areEqual(10000, data.pipelineValue,  'Pipeline should sum open opportunity amounts');
        Assert.areEqual(1, data.closedWonThisMonth, 'Should count 1 Closed Won this month');
    }

    @IsTest
    static void testLeadConversionRateIsZeroWithNoConvertedLeads() {
        Test.startTest();
        KpiDashboardController.KpiData data = KpiDashboardController.getKpiData();
        Test.stopTest();

        Assert.areEqual(0, data.leadConversionRate, 'Conversion rate should be 0 when no leads are converted');
    }

    @IsTest
    static void testEmptyOrgReturnsZeroValues() {
        // Wipe setup data for this isolated scenario
        delete [SELECT Id FROM Case];
        delete [SELECT Id FROM Lead];
        delete [SELECT Id FROM Opportunity];

        Test.startTest();
        KpiDashboardController.KpiData data = KpiDashboardController.getKpiData();
        Test.stopTest();

        Assert.areEqual(0, data.openCases,          'Should be 0 open cases on empty org');
        Assert.areEqual(0, data.pipelineValue,      'Should be 0 pipeline on empty org');
        Assert.areEqual(0, data.leadConversionRate, 'Should be 0 conversion rate on empty org');
    }
}
