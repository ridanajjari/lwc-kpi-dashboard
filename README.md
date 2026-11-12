# LWC KPI Dashboard (Salesforce)

A Lightning Web Component I built to show five Sales and Service KPIs on a Salesforce Home page or App page. No AppExchange license needed.

---

## What it does

Standard Salesforce dashboards need reports built first. I wanted managers to get a quick KPI snapshot right on their home page instead. The values load when the page opens and are queried again from the server when the user clicks **Refresh**. The footer shows the server time at which the values were computed.

---

## KPIs

All queries run `WITH USER_MODE` in a `with sharing` class, so the running user's sharing, object and field permissions apply. "This month" uses the SOQL `THIS_MONTH` date literal (running user's time zone).

| Metric                               | Source                                                                         |
| ------------------------------------ | ------------------------------------------------------------------------------ |
| Open Cases                           | `Case`, `IsClosed = false`                                                     |
| Open Pipeline                        | `Opportunity`, `IsClosed = false`, `SUM(Amount)`, shown in the user's currency |
| New Leads This Month (Not Converted) | `Lead`, `CreatedDate = THIS_MONTH`, `IsConverted = false`                      |
| Lead Conversion Rate (This Month)    | Converted / all leads with `CreatedDate = THIS_MONTH`                          |
| Closed Won (This Month)              | `Opportunity`, `IsWon = true`, `CloseDate = THIS_MONTH`                        |

I get both Lead figures from one aggregate query (`COUNT(Id)` grouped by `IsConverted`), so the controller runs four SOQL queries per call.

One thing to know about currency: `SUM(Amount)` comes back in the org's corporate currency, and I format it with the running user's currency code. In a single-currency org these are the same. In a multi-currency org where they differ, the symbol may not match the amount.

---

## Screenshot

TODO: real screenshot

<!-- Replace this line with a screenshot of the component on a Home page, e.g. ![KPI Dashboard](docs/screenshot.png) -->

---

## Project structure

```
force-app/main/default/
├── classes/
│   ├── KpiDashboardController.cls           # with sharing, cacheable=true, 4 SOQL queries WITH USER_MODE
│   └── KpiDashboardControllerTest.cls       # 7 test methods
├── labels/
│   └── CustomLabels.labels-meta.xml         # All user-facing strings
├── lwc/kpiDashboard/
│   ├── kpiDashboard.html                    # Loading / error / data states, lightning-formatted-number
│   ├── kpiDashboard.js                      # @wire + refreshApex, Custom Labels, user currency
│   ├── kpiDashboard.css                     # CSS grid, SLDS styling hooks for colours
│   ├── kpiDashboard.js-meta.xml             # Exposed to Home and App pages
│   └── __tests__/kpiDashboard.test.js       # Jest tests (5)
└── permissionsets/
    └── KPI_Dashboard_User.permissionset-meta.xml  # Apex class access
```

---

## Setup

```bash
git clone https://github.com/ridanajjari/lwc-kpi-dashboard.git
cd lwc-kpi-dashboard
sf org login web --alias my-org
sf project deploy start --source-dir force-app --target-org my-org --wait 30
sf org assign permset --name KPI_Dashboard_User --target-org my-org
sf apex run test --target-org my-org --class-names KpiDashboardControllerTest --code-coverage --result-format human --wait 30
```

The permission set only gives access to the Apex class. Since the queries run in user mode, users also need read access to Case, Lead and Opportunity (including `Opportunity.Amount`) through their profile or another permission set.

Local tooling (needs Node.js):

```bash
npm install
npm run lint
npm run prettier:verify
npm run test:unit
```

After deploying, add the **KPI Dashboard** component to a Home page or App page in Lightning App Builder (Setup → Lightning App Builder).

---

## How it works

- **`@wire` + `refreshApex`**: I keep the wired result and refresh it on demand, which bypasses the client-side cache of the `cacheable=true` method.
- **"Last updated" from the server**: the server returns `generatedAt = System.now()` and the component shows that time, not the browser clock.
- **`@AuraEnabled(cacheable=true)`**: results are cached on the client by Lightning Data Service.
- **Security**: `with sharing` plus `WITH USER_MODE` on every query. One test runs as a Minimum Access user and expects a `System.SecurityException`.
- **SOQL**: aggregate query with `GROUP BY`, `IsWon`, `THIS_MONTH` date literals.
- **Internationalisation**: Custom Labels for every string, `lightning-formatted-number` with the user's currency (`@salesforce/i18n/currency`) and locale.
- **Styling**: CSS grid and SLDS global styling hooks (`--slds-g-color-*`) with fallbacks.
- **`ShowToastEvent`**: shows the user an error notification.
- **Testing**: Apex `@TestSetup`, `Test.setCreatedDate`, `Database.convertLead`, `System.runAs`; Jest with `createApexTestWireAdapter` and a mocked `refreshApex`.

---

## Testing

I tested this on 12 Nov 2026 in a Developer Edition org (API 68.0).

- Deploy: all 16 components (Apex, LWC, Custom Labels, permission set) deployed with no errors. The platform compiles the LWC on deploy, so this also checks the template and JavaScript.
- Apex: 7 of 7 test methods in `KpiDashboardControllerTest` pass. The CLI says "Tests Ran 8" because it also counts the `@TestSetup` method. The tests cover KPI counts and the pipeline sum, `IsWon` + `THIS_MONTH` filtering (won deals closing last or next month are excluded), leads created last month being excluded, the converted/unconverted Lead aggregate (50% case), zero values on an empty data set, the server timestamp, and user-mode enforcement for a Minimum Access user.
- Coverage in that run: `KpiDashboardController` 100%.
- Offline checks pass: Apex parses (prettier-plugin-apex), ESLint, Prettier, XML is well-formed, and Jest runs 5 passing tests (`npm run lint`, `npm run prettier:verify`, `npm run test:unit`).

---

## Author

**Rida Najjari**, Salesforce Consultant, Developer & Administrator

4x Salesforce Certified: Platform Administrator · Platform App Builder · Platform Developer I · Associate

- LinkedIn: [linkedin.com/in/rida-najjari](https://www.linkedin.com/in/rida-najjari)
- GitHub: [github.com/ridanajjari](https://github.com/ridanajjari)
