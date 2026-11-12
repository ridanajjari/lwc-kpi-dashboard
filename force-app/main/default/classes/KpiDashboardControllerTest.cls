@IsTest
private class KpiDashboardControllerTest {
  @TestSetup
  static void setup() {
    // Cases
    insert new List<Case>{
      new Case(Subject = 'Open Case 1', Status = 'New', Origin = 'Email'),
      new Case(Subject = 'Open Case 2', Status = 'New', Origin = 'Email'),
      new Case(Subject = 'Closed Case', Status = 'Closed', Origin = 'Email')
    };

    // Leads (this month, not converted)
    insert new List<Lead>{
      new Lead(FirstName = 'A', LastName = 'Test', Company = 'Acme'),
      new Lead(FirstName = 'B', LastName = 'Test', Company = 'Acme')
    };

    // Opportunities
    insert new List<Opportunity>{
      new Opportunity(
        Name = 'Open Deal',
        StageName = 'Proposal',
        CloseDate = Date.today().addDays(30),
        Amount = 10000
      ),
      new Opportunity(
        Name = 'Closed Won Deal',
        StageName = 'Closed Won',
        CloseDate = Date.today(),
        Amount = 5000
      ),
      new Opportunity(
        Name = 'Closed Won Last Month',
        StageName = 'Closed Won',
        CloseDate = Date.today().toStartOfMonth().addDays(-1),
        Amount = 7000
      ),
      new Opportunity(
        Name = 'Closed Won Next Month',
        StageName = 'Closed Won',
        CloseDate = Date.today().toStartOfMonth().addMonths(1),
        Amount = 8000
      ),
      new Opportunity(
        Name = 'Closed Lost',
        StageName = 'Closed Lost',
        CloseDate = Date.today(),
        Amount = 2000
      )
    };
  }

  @IsTest
  static void testGetKpiDataReturnsCorrectCounts() {
    Test.startTest();
    KpiDashboardController.KpiData data = KpiDashboardController.getKpiData();
    Test.stopTest();

    Assert.isNotNull(data, 'KpiData should not be null');
    Assert.isNotNull(
      data.generatedAt,
      'generatedAt should carry the server timestamp'
    );
    Assert.areEqual(2, data.openCases, 'Should count 2 open cases');
    Assert.areEqual(
      2,
      data.newLeadsThisMonth,
      'Should count 2 new leads this month'
    );
    Assert.areEqual(
      10000,
      data.pipelineValue,
      'Pipeline should sum open opportunity amounts'
    );
    Assert.areEqual(
      1,
      data.closedWonThisMonth,
      'Should count 1 Closed Won this month'
    );
  }

  @IsTest
  static void testClosedWonUsesIsWonAndThisMonth() {
    // Setup has three won deals (last, this and next month) and one lost deal
    // this month: only the won deal closing this month may be counted.
    Test.startTest();
    KpiDashboardController.KpiData data = KpiDashboardController.getKpiData();
    Test.stopTest();

    Assert.areEqual(
      1,
      data.closedWonThisMonth,
      'Won deals closing last month or next month must be excluded'
    );
  }

  @IsTest
  static void testLeadsCreatedLastMonthAreExcluded() {
    Lead oldLead = new Lead(
      FirstName = 'C',
      LastName = 'Old',
      Company = 'Acme'
    );
    insert oldLead;
    Test.setCreatedDate(
      oldLead.Id,
      Datetime.newInstance(
        Date.today().toStartOfMonth().addDays(-1),
        Time.newInstance(12, 0, 0, 0)
      )
    );

    Test.startTest();
    KpiDashboardController.KpiData data = KpiDashboardController.getKpiData();
    Test.stopTest();

    Assert.areEqual(
      2,
      data.newLeadsThisMonth,
      'A lead created last month must not be counted'
    );
  }

  @IsTest
  static void testLeadAggregateSplitsConvertedAndUnconverted() {
    // Convert one of the two setup leads: 1 unconverted + 1 converted = 50%
    Lead toConvert = [SELECT Id FROM Lead WHERE FirstName = 'A' LIMIT 1];
    LeadStatus convertedStatus = [
      SELECT ApiName
      FROM LeadStatus
      WHERE IsConverted = TRUE
      LIMIT 1
    ];
    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(toConvert.Id);
    lc.setConvertedStatus(convertedStatus.ApiName);
    lc.setDoNotCreateOpportunity(true);
    Database.LeadConvertResult result = Database.convertLead(lc);
    Assert.isTrue(result.isSuccess(), 'Lead conversion should succeed');

    Test.startTest();
    KpiDashboardController.KpiData data = KpiDashboardController.getKpiData();
    Test.stopTest();

    Assert.areEqual(
      1,
      data.newLeadsThisMonth,
      'Only the unconverted lead counts as a new lead'
    );
    Assert.areEqual(
      50.0,
      data.leadConversionRate,
      'One converted out of two leads created this month is 50%'
    );
  }

  @IsTest
  static void testLeadConversionRateIsZeroWithNoConvertedLeads() {
    Test.startTest();
    KpiDashboardController.KpiData data = KpiDashboardController.getKpiData();
    Test.stopTest();

    Assert.areEqual(
      0,
      data.leadConversionRate,
      'Conversion rate should be 0 when no leads are converted'
    );
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

    Assert.areEqual(0, data.openCases, 'Should be 0 open cases on empty org');
    Assert.areEqual(0, data.pipelineValue, 'Should be 0 pipeline on empty org');
    Assert.areEqual(
      0,
      data.leadConversionRate,
      'Should be 0 conversion rate on empty org'
    );
  }

  @IsTest
  static void testUserModeBlocksUserWithoutObjectAccess() {
    // A Minimum Access user has no read access to Case, Lead or Opportunity.
    // In user mode the query must fail instead of silently running in
    // system mode.
    Profile minimumAccess = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Minimum Access - Salesforce'
      LIMIT 1
    ];
    String uniqueName = 'kpi.min.' + Crypto.getRandomInteger() + '@example.com';
    User restricted = new User(
      Alias = 'kpimin',
      Email = uniqueName,
      Username = uniqueName,
      LastName = 'Restricted',
      ProfileId = minimumAccess.Id,
      TimeZoneSidKey = 'GMT',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    insert restricted;

    Boolean blocked = false;
    System.runAs(restricted) {
      Test.startTest();
      try {
        KpiDashboardController.getKpiData();
      } catch (System.SecurityException e) {
        blocked = true;
      }
      Test.stopTest();
    }

    Assert.isTrue(
      blocked,
      'User mode should reject a user without object permissions'
    );
  }
}
