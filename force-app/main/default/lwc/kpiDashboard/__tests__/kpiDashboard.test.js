import { createElement } from "lwc";
import KpiDashboard from "c/kpiDashboard";
import getKpiData from "@salesforce/apex/KpiDashboardController.getKpiData";
import { refreshApex } from "@salesforce/apex";

const mockKpiData = require("./data/getKpiData.json");

// Replace the default @salesforce/apex stub so refreshApex calls can be asserted.
jest.mock(
  "@salesforce/apex",
  () => ({
    refreshApex: jest.fn(() => Promise.resolve())
  }),
  { virtual: true }
);

// Apex wire adapter that lets each test emit data or an error.
jest.mock(
  "@salesforce/apex/KpiDashboardController.getKpiData",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

// Resolve pending promises and re-render.
// eslint-disable-next-line @lwc/lwc/no-async-operation
const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

function createComponent() {
  const element = createElement("c-kpi-dashboard", { is: KpiDashboard });
  document.body.appendChild(element);
  return element;
}

describe("c-kpi-dashboard", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("shows a spinner and no cards while the wire has not responded", () => {
    const element = createComponent();

    expect(
      element.shadowRoot.querySelector("lightning-spinner")
    ).not.toBeNull();
    expect(element.shadowRoot.querySelectorAll(".kpi-card")).toHaveLength(0);
    expect(
      element.shadowRoot.querySelector("lightning-formatted-date-time")
    ).toBeNull();
  });

  it("renders the five KPI values and the server timestamp", async () => {
    const element = createComponent();
    getKpiData.emit(mockKpiData);
    await flushPromises();

    expect(element.shadowRoot.querySelector("lightning-spinner")).toBeNull();
    expect(element.shadowRoot.querySelectorAll(".kpi-card")).toHaveLength(5);

    const numbers = Array.from(
      element.shadowRoot.querySelectorAll("lightning-formatted-number")
    );
    expect(numbers.map((n) => n.value)).toEqual([24, 1250000, 138, 0.063, 12]);

    const pipeline = numbers[1];
    expect(pipeline.formatStyle).toBe("currency");
    expect(pipeline.currencyCode).toBeTruthy();
    expect(numbers[3].formatStyle).toBe("percent");

    const timestamp = element.shadowRoot.querySelector(
      "lightning-formatted-date-time"
    );
    expect(timestamp.value).toBe(mockKpiData.generatedAt);
  });

  it("shows the server error message and a toast when the wire fails", async () => {
    const element = createComponent();
    const toastHandler = jest.fn();
    element.addEventListener("lightning__showtoast", toastHandler);

    getKpiData.error({ message: "Insufficient access" });
    await flushPromises();

    expect(element.shadowRoot.querySelector("lightning-spinner")).toBeNull();
    expect(element.shadowRoot.querySelectorAll(".kpi-card")).toHaveLength(0);
    const errorText = element.shadowRoot.querySelector(
      ".slds-text-color_error"
    );
    expect(errorText.textContent).toBe("Insufficient access");
    expect(toastHandler).toHaveBeenCalledTimes(1);
    expect(toastHandler.mock.calls[0][0].detail.variant).toBe("error");
  });

  it("calls refreshApex with the wired result and shows a spinner meanwhile", async () => {
    let resolveRefresh;
    refreshApex.mockImplementationOnce(
      () =>
        new Promise((resolve) => {
          resolveRefresh = resolve;
        })
    );

    const element = createComponent();
    getKpiData.emit(mockKpiData);
    await flushPromises();

    const button = element.shadowRoot.querySelector("lightning-button");
    button.click();
    await flushPromises();

    expect(refreshApex).toHaveBeenCalledTimes(1);
    expect(refreshApex.mock.calls[0][0].data).toEqual(mockKpiData);
    expect(
      element.shadowRoot.querySelector("lightning-spinner")
    ).not.toBeNull();
    expect(button.disabled).toBe(true);
    // Existing values stay visible while refreshing.
    expect(element.shadowRoot.querySelectorAll(".kpi-card")).toHaveLength(5);

    resolveRefresh();
    await flushPromises();

    expect(element.shadowRoot.querySelector("lightning-spinner")).toBeNull();
    expect(button.disabled).toBe(false);
  });

  it("shows an error when refreshApex rejects", async () => {
    refreshApex.mockImplementationOnce(() =>
      Promise.reject({ body: { message: "Refresh failed" } })
    );

    const element = createComponent();
    getKpiData.emit(mockKpiData);
    await flushPromises();

    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();

    const errorText = element.shadowRoot.querySelector(
      ".slds-text-color_error"
    );
    expect(errorText.textContent).toBe("Refresh failed");
    expect(element.shadowRoot.querySelector("lightning-spinner")).toBeNull();
  });
});
