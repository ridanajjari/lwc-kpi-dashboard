# LWC KPI Dashboard — Salesforce

A custom Lightning Web Component that displays live Sales & Service KPIs on any Salesforce Home Page or App Page — no AppExchange license needed.

---

## Business Problem

Out-of-the-box Salesforce dashboards require report building and are slow to load. This component gives managers a real-time KPI snapshot directly on their home page, with a single Refresh button to reload live data.

---

## KPIs Displayed

| Metric | Source |
|--------|--------|
| Open Cases | `Case` object, `IsClosed = false` |
| Open Pipeline Value | `Opportunity`, not closed, sum of Amount |
| New Leads This Month | `Lead`, created this calendar month, not converted |
| Lead Conversion Rate % | Converted leads / total leads this month |
| Closed Won This Month | `Opportunity`, `StageName = 'Closed Won'`, this month |

---

## Screenshot

```
┌─────────────────────────────────────────────────────────────┐
│  Sales & Service KPIs                          [Refresh]     │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │    24    │ │  $1.2M   │ │   138    │ │   6.3%   │       │
│  │Open Cases│ │ Pipeline │ │New Leads │ │Conv. Rate│       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
│  ┌──────────┐                                                │
│  │    12    │  Last updated: 10:42:05 AM                     │
│  │Closed Won│                                                │
│  └──────────┘                                                │
└─────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── KpiDashboardController.cls           # Apex, cacheable=true, 5 SOQL queries
│   └── KpiDashboardControllerTest.cls       # 3 test scenarios
└── lwc/kpiDashboard/
    ├── kpiDashboard.html                    # Template with loading/error/data states
    ├── kpiDashboard.js                      # Wire + imperative fetch, formatted values
    ├── kpiDashboard.css                     # Responsive card grid with gradients
    └── kpiDashboard.js-meta.xml             # Exposed to Home, App, and Record pages
```

---

## Deployment

```bash
git clone https://github.com/YOUR_USERNAME/lwc-kpi-dashboard.git
cd lwc-kpi-dashboard
sf org login web --alias my-org
sf project deploy start --target-org my-org
sf apex run test --target-org my-org --test-level RunLocalTests --wait 10
```

After deploying, add the **KPI Dashboard** component to any Lightning page via Lightning App Builder (Setup → Lightning App Builder).

---

## Key Salesforce Concepts Demonstrated

- **LWC** — template directives (`lwc:if`), `@track`, `connectedCallback`
- **`@AuraEnabled(cacheable=true)`** — server-side caching for read-only queries
- **Imperative Apex call** — manual refresh pattern with `.then()/.catch()/.finally()`
- **`ShowToastEvent`** — user-facing error notification
- **CSS Grid** — responsive card layout with no external library
- **`@TestSetup`** — shared test data across multiple test methods
- **Pipeline formatting** — `$1.2M`, `$500K`, `$999` logic in JavaScript

---

## Author

**Rida Najjari** — Salesforce Consultant, Developer & Administrator

4x Salesforce Certified: Platform Administrator · Platform App Builder · Platform Developer I · Associate

- LinkedIn: [linkedin.com/in/rida-najjari](https://www.linkedin.com/in/rida-najjari)
- GitHub: [github.com/ridanajjari](https://github.com/ridanajjari)
