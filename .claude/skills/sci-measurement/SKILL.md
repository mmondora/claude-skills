---
name: sci-measurement
description: "Software Carbon Intensity (SCI) measurement per ISO/IEC 21031:2024. SCI formula, energy measurement, carbon intensity data, embodied carbon, functional units, CI integration. Use when measuring carbon emissions, setting sustainability baselines, or tracking environmental impact of software."
---

# SCI Measurement

> **Version**: 1.0.0 | **Last updated**: 2026-02-11

## Purpose

The Software Carbon Intensity (SCI) specification, developed by the Green Software Foundation and standardized as **ISO/IEC 21031:2024**, defines how to calculate the rate of carbon emissions for a software system. This skill provides the operational guidance to measure, track, and reduce SCI in real projects.

**Reference**: [SCI Specification](https://sci.greensoftware.foundation/) | [SCI Guidance](https://sci-guide.greensoftware.foundation/)

---

## The SCI Formula

```
SCI = ((E × I) + M) / R
```

Where:

| Variable | Name | Unit | Description |
|----------|------|------|-------------|
| **E** | Energy | kWh | Total energy consumed by the software system boundary |
| **I** | Carbon Intensity | gCO2eq/kWh | Location-based marginal carbon emissions for the grid powering the datacenter |
| **M** | Embodied Carbon | gCO2eq | Share of hardware manufacturing/disposal emissions allocated to the software |
| **R** | Functional Unit | per user, per request, per minute, etc. | The unit of scaling that makes the score a rate |

**Key properties**: SCI is a rate (not a total), lower is better, it can never be zero, and it is sensitive to energy efficiency, carbon awareness, and hardware efficiency. Offsets cannot reduce SCI — only actual emission elimination reduces the score.

---

## Calculating E (Energy)

Energy is the total electricity consumed by the software within its defined boundary.

### Measurement approaches (in order of preference)

**1. Direct measurement** (best accuracy): hardware power meters, RAPL (Running Average Power Limit) for CPU/DRAM, GPU power sensors.

**2. Cloud provider telemetry**: GCP Carbon Footprint dashboard, Cloud Monitoring CPU/memory utilization metrics converted to energy estimates.

**3. Software-based estimation**: tools like Kepler (Kubernetes-based Efficient Power Level Exporter), Scaphandre, CodeCarbon, or PowerAPI.

**4. Model-based estimation** (fallback): use TDP (Thermal Design Power) × utilization × time as a rough estimate.

### Cloud Run Energy Estimation

For serverless workloads (Cloud Run, Cloud Functions), estimate energy per request:

```typescript
/**
 * Estimate energy consumption per Cloud Run request.
 *
 * @param vcpuAllocation - vCPU allocation (e.g. 1.0)
 * @param memoryGiB - Memory allocation in GiB (e.g. 0.5)
 * @param durationSeconds - Average request duration in seconds
 * @param tdpPerVcpu - Estimated TDP per vCPU in watts (default: 12.5W for shared vCPU)
 * @param memoryWattPerGiB - Estimated power per GiB of memory (default: 0.3725W)
 * @param pue - Power Usage Effectiveness of the datacenter (default: 1.1 for GCP)
 * @returns Energy in kWh
 */
function estimateEnergyPerRequest(
  vcpuAllocation: number,
  memoryGiB: number,
  durationSeconds: number,
  tdpPerVcpu = 12.5,
  memoryWattPerGiB = 0.3725,
  pue = 1.1,
): number {
  const cpuWatts = vcpuAllocation * tdpPerVcpu;
  const memWatts = memoryGiB * memoryWattPerGiB;
  const totalWatts = (cpuWatts + memWatts) * pue;
  const hours = durationSeconds / 3600;
  return totalWatts * hours / 1000; // kWh
}
```

### GKE / VM Energy Estimation

For VM-based workloads, use utilization-weighted TDP:

```typescript
/**
 * Estimate energy for a VM/node over a period.
 *
 * @param tdpWatts - TDP of the machine type in watts
 * @param avgUtilization - Average CPU utilization (0.0 to 1.0)
 * @param hours - Duration in hours
 * @param idlePowerRatio - Power at idle as fraction of TDP (default: 0.12)
 * @param pue - Power Usage Effectiveness (default: 1.1 for GCP)
 * @returns Energy in kWh
 */
function estimateVmEnergy(
  tdpWatts: number,
  avgUtilization: number,
  hours: number,
  idlePowerRatio = 0.12,
  pue = 1.1,
): number {
  const dynamicPower = tdpWatts * avgUtilization;
  const idlePower = tdpWatts * idlePowerRatio;
  const totalWatts = (idlePower + dynamicPower) * pue;
  return totalWatts * hours / 1000; // kWh
}
```

---

## Calculating I (Carbon Intensity)

Carbon intensity is the grams of CO2 equivalent emitted per kWh of electricity consumed. It varies by location and time.

### Data Sources

| Source | Type | Coverage | Resolution |
|--------|------|----------|------------|
| [Electricity Maps](https://electricitymaps.com/) | Real-time + forecast | Global | Hourly, by zone |
| [WattTime](https://watttime.org/) | Real-time + forecast | Global | 5-minute, by grid |
| [Carbon Aware SDK](https://github.com/Green-Software-Foundation/carbon-aware-sdk) | Aggregator (WattTime, Electricity Maps) | Global | Varies by provider |
| [EMBER](https://ember-climate.org/) | Annual averages | Global | Yearly, by country |

### GCP Region Carbon Intensity (reference values)

| GCP Region | Location | Approx. gCO2eq/kWh | Notes |
|-----------|----------|---------------------|-------|
| `europe-north1` | Finland | ~50 | Nuclear + hydro |
| `europe-west1` | Belgium | ~150 | Mixed |
| `europe-west4` | Netherlands | ~340 | Gas-heavy |
| `europe-west9` | Paris | ~60 | Nuclear-dominant |
| `us-central1` | Iowa | ~400 | Mixed |
| `us-west1` | Oregon | ~80 | Hydro-heavy |
| `northamerica-northeast1` | Montreal | ~20 | Hydro-dominant |
| `asia-southeast1` | Singapore | ~400 | Gas + imports |

**Caution**: these are approximate annual averages and change significantly over time. Always use real-time data for carbon-aware decisions. For static SCI calculations, use the annual average for the deployment region.

### Using the Carbon Aware SDK

```typescript
// Example: query carbon intensity via Carbon Aware SDK REST API
const response = await fetch(
  `${CARBON_AWARE_SDK_URL}/emissions/bylocation?` +
  `location=${region}&time=${new Date().toISOString()}`
);
const data = await response.json();
const carbonIntensity = data[0].rating; // gCO2eq/kWh
```

---

## Calculating M (Embodied Carbon)

Embodied carbon covers manufacturing, transport, and end-of-life disposal of hardware. It is amortized over the hardware's expected lifespan and allocated proportionally to the software's usage.

### Formula

```
M = (TE × (TR / EL)) × (RS / TS)
```

Where:

| Variable | Description |
|----------|-------------|
| **TE** | Total embodied carbon of the hardware (gCO2eq) |
| **TR** | Time reserved (hours the software uses the hardware) |
| **EL** | Expected lifespan of the hardware (hours) |
| **RS** | Resources used by the software (e.g. vCPUs, GiB RAM) |
| **TS** | Total resources of the hardware |

### Cloud Estimation

For cloud workloads, embodied carbon is harder to measure. Approaches:

- **Cloud Carbon Footprint (CCF)**: open-source tool that estimates embodied emissions from cloud billing data
- **Provider data**: GCP Carbon Footprint includes scope 3 (embodied) estimates
- **Fallback**: use published server embodied carbon data (e.g., Dell PowerEdge R750 ~ 1,200 kgCO2eq over 4-year lifespan) and allocate by vCPU share

### For Serverless

For Cloud Run / Cloud Functions, embodied carbon per request is typically very small due to high multi-tenancy. A reasonable estimate: 0.5–2.0 gCO2eq per vCPU-hour of allocated time (amortized across all tenants sharing the hardware).

---

## Choosing R (Functional Unit)

R is the unit that turns SCI from a total into a rate. Choose the unit that best represents how the software scales.

| Software Type | Recommended R | Example |
|--------------|---------------|---------|
| API service | Per API request | gCO2eq/request |
| SaaS platform | Per active user per day | gCO2eq/user/day |
| ML training | Per training run | gCO2eq/training-run |
| ML inference | Per inference request | gCO2eq/inference |
| Batch processing | Per record processed | gCO2eq/record |
| Web application | Per page view | gCO2eq/page-view |
| Mobile app | Per active user per day | gCO2eq/user/day |
| CI/CD pipeline | Per pipeline run | gCO2eq/pipeline-run |

**Rule**: R must be meaningful for comparison across releases. The same R must be used when comparing baseline SCI to post-optimization SCI.

---

## SCI Calculation Example

**Scenario**: Invoice API on Cloud Run, `europe-west1`, 1 vCPU, 512 MiB, avg 200ms/request, 1M requests/month.

```
E = 1M requests × estimateEnergyPerRequest(1.0, 0.5, 0.2)
  = 1,000,000 × 0.00000078 kWh
  = 0.78 kWh/month

I = 150 gCO2eq/kWh (europe-west1 annual average)

M = ~1.5 gCO2eq/vCPU-hour × (1M × 0.2s / 3600) hours × 1 vCPU
  = 1.5 × 55.6
  = 83.3 gCO2eq/month

R = per 1,000 requests

SCI = ((0.78 × 150) + 83.3) / 1,000
    = (117 + 83.3) / 1,000
    = 0.20 gCO2eq per 1,000 requests
```

**Interpretation**: each batch of 1,000 API requests emits approximately 0.20 grams of CO2 equivalent. Track this across releases to ensure it trends downward.

---

## CI Integration

### SCI Tracking in GitHub Actions

```yaml
# .github/workflows/sci-report.yml
name: SCI Report
on:
  push:
    branches: [main]
  schedule:
    - cron: '0 6 * * 1'  # Weekly Monday 06:00 UTC

jobs:
  sci-report:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Collect energy metrics
        run: |
          # Pull Cloud Monitoring metrics for the past week
          node scripts/collect-energy-metrics.ts \
            --project ${{ vars.GCP_PROJECT }} \
            --service invoice-api \
            --period 7d \
            --output /tmp/energy.json

      - name: Calculate SCI
        run: |
          node scripts/calculate-sci.ts \
            --energy /tmp/energy.json \
            --region europe-west1 \
            --functional-unit "per-1000-requests" \
            --output /tmp/sci-report.json

      - name: Check SCI regression
        run: |
          node scripts/check-sci-regression.ts \
            --current /tmp/sci-report.json \
            --baseline sci-baseline.json \
            --threshold 10  # Fail if SCI increases >10%

      - name: Upload SCI report
        uses: actions/upload-artifact@v4
        with:
          name: sci-report
          path: /tmp/sci-report.json
```

### SCI as Quality Gate

Add SCI regression to the quality gates (see `quality-gates/SKILL.md`):

| Gate | Metric | PASS | WARN | FAIL |
|------|--------|------|------|------|
| **Sustainability** | SCI delta vs baseline | ≤ 0% (improved or stable) | 0–10% increase | > 10% increase |

---

## SCI Dashboard

Include SCI alongside traditional observability metrics:

```
┌─────────────────────────────────────────────────┐
│  SERVICE: invoice-api                           │
│                                                 │
│  SCI Score:  0.20 gCO2eq/1K req  (↓ 5% vs last)│
│  Energy:     0.78 kWh/month                     │
│  Region CI:  150 gCO2eq/kWh (europe-west1)      │
│  Embodied:   83.3 gCO2eq/month                  │
│                                                 │
│  ▇▇▇▆▆▅▅▅▄▄▃▃  SCI trend (12 weeks)            │
│                                                 │
│  Request Rate: 33K/day  |  p99: 180ms           │
│  Error Rate:   0.02%    |  Availability: 99.98% │
└─────────────────────────────────────────────────┘
```

---

## SCI for AI (Extension)

The GSF SCI-AI specification extends SCI for AI/ML workloads. Two boundary scores:

| Score | Covers | Who Measures |
|-------|--------|-------------|
| **Provider Score** | Model training, fine-tuning, deployment infrastructure | AI model provider |
| **Consumer Score** | Inference calls, data preprocessing, integration overhead | Application team |

For teams using third-party AI APIs (e.g., LLM inference): measure the Consumer Score — energy of API calls, network overhead, and pre/post-processing. Request Provider Score transparency from vendors.

---

## Anti-Patterns

- **"SCI is too complex"**: start with estimates, refine. An imperfect SCI is better than no measurement.
- **"We only measure total emissions"**: totals increase with growth. SCI as a rate normalizes for scale.
- **"Annual measurement is enough"**: SCI should be tracked per release (or weekly minimum) to catch regressions.
- **"Embodied carbon is negligible"**: for client-side heavy apps and short-lived hardware, M can dominate.
- **"Same region, same intensity"**: carbon intensity fluctuates hourly. Use real-time data for carbon-aware decisions.

---

## For Claude Code

When instrumenting services: include SCI calculation utilities alongside observability setup, suggest appropriate functional units for the project type, generate energy estimation functions adapted to the deployment target (serverless, VM, Kubernetes), include SCI baseline tracking in CI pipelines. When choosing deployment regions, surface the carbon intensity trade-off alongside latency and cost.

---

*Internal references*: `green-software-principles/SKILL.md`, `carbon-aware-architecture/SKILL.md`, `observability/SKILL.md`, `finops/SKILL.md`, `quality-gates/SKILL.md`, `cicd-pipeline/SKILL.md`
