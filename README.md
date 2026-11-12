# LWC KPI Dashboard — Salesforce

A custom Lightning Web Component that displays five Sales & Service KPIs on a Salesforce Home Page or App Page — no AppExchange license needed.

---

## Business Problem

Out-of-the-box Salesforce dashboards require building reports first. This component gives managers a KPI snapshot directly on their home page. Values are loaded when the page opens and re-queried from the server when the user clicks **Refresh**; the footer shows the server time at which the displayed values were computed.

---

## KPIs Displayed

All queries run `WITH USER_MODE` in a `with sharing` class, so the running user's sharing, object and field permissions apply. "This month" uses the SOQL `THIS_MONTH` date literal (running user's time zone).

| Metric                               | Source                                                                         |
| ------------------------------------ | ------------------------------------------------------------------------------ |
| Open Cases                           | `Case`, `IsClosed = false`                                                     |
| Open Pipeline                        | `Opportunity`, `IsClosed = false`, `SUM(Amount)`, shown in the user's currency |
| New Leads This Month (Not Converted) | `Lead`, `CreatedDate = THIS_MONTH`, `IsConverted = false`                      |
| Lead Conversion Rate (This Month)    | Converted / all leads with `CreatedDate = THIS_MONTH`                          |
| Closed Won (This Month)              | `Opportunity`, `IsWon = true`, `CloseDate = THIS_MONTH`                        |

Both Lead figures come from one aggregate query (`COUNT(Id)` grouped by `IsConverted`), so the controller runs four SOQL queries per call.

Note: `SUM(Amount)` is returned in the org's corporate currency and formatted with the running user's currency code. In single-currency orgs these are the same; in multi-currency orgs where they differ, the symbol may not match the amount.

---

## Screenshot

TODO: real screenshot

<!-- Replace this line with a screenshot of the component on a Home page, e.g. ![KPI Dashboard](docs/screenshot.png) -->

---

## Project Structure

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

## Deployment

```bash
git clone https://github.com/ridanajjari/lwc-kpi-dashboard.git
cd lwc-kpi-dashboard
sf org login web --alias my-org
sf project deploy start --source-dir force-app --target-org my-org --wait 30
sf org assign permset --name KPI_Dashboard_User --target-org my-org
sf apex run test --target-org my-org --class-names KpiDashboardControllerTest --code-coverage --result-format human --wait 30
```

The permission set grants access to the Apex class only. Because the queries run in user mode, users also need read access to Case, Lead and Opportunity (including `Opportunity.Amount`) from their profile or another permission set.

Local tooling (Node.js required):

```bash
npm install
npm run lint
npm run prettier:verify
npm run test:unit
```

After deploying, add the **KPI Dashboard** component to a Home page or App page via Lightning App Builder (Setup → Lightning App Builder).

---

## Key Salesforce Concepts Demonstrated

- **`@wire` + `refreshApex`** — the wired result is kept and refreshed on demand, bypassing the client-side cache of the `cacheable=true` method
- **Truthful "Last updated"** — the server returns `generatedAt = System.now()`; the component shows that time, not the browser clock
- **`@AuraEnabled(cacheable=true)`** — results are cached on the client by Lightning Data Service
- **Security** — `with sharing` plus `WITH USER_MODE` on every query; a test runs as a Minimum Access user and expects a `QueryException`
- **SOQL** — aggregate query with `GROUP BY`, `IsWon`, `THIS_MONTH` date literals
- **Internationalisation** — Custom Labels for every string, `lightning-formatted-number` with the user's currency (`@salesforce/i18n/currency`) and locale
- **Styling** — CSS grid and SLDS global styling hooks (`--slds-g-color-*`) with fallbacks
- **`ShowToastEvent`** — user-facing error notification
- **Testing** — Apex `@TestSetup`, `Test.setCreatedDate`, `Database.convertLead`, `System.runAs`; Jest with `createApexTestWireAdapter` and a mocked `refreshApex`

---

## Testing

Status on 2026-11-12:

- ✅ Apex tests written: 7 test methods in `KpiDashboardControllerTest` covering KPI counts and pipeline sum, `IsWon` + `THIS_MONTH` filtering (won deals closing last/next month excluded), leads created last month excluded, the converted/unconverted Lead aggregate (50% case), zero values on an empty data set, the server timestamp, and user-mode enforcement for a Minimum Access user.
- ✅ Offline checks passing: Apex parses (prettier-plugin-apex), ESLint, Prettier, XML well-formed, Jest: 5 tests passing (`npm run lint`, `npm run prettier:verify`, `npm run test:unit`).
- ⏳ Apex test execution and coverage: pending run in a Developer Edition org.

---

## Author

**Rida Najjari** — Salesforce Consultant, Developer & Administrator

4x Salesforce Certified: Platform Administrator · Platform App Builder · Platform Developer I · Associate

- LinkedIn: [linkedin.com/in/rida-najjari](https://www.linkedin.com/in/rida-najjari)
- GitHub: [github.com/ridanajjari](https://github.com/ridanajjari)
