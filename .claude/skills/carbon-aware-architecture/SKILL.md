---
name: carbon-aware-architecture
description: "Carbon-aware design patterns from the Green Software Foundation. Time shifting, spatial shifting, demand shaping, Carbon Aware SDK, carbon-aware CI/CD, region selection. Use when designing infrastructure, scheduling workloads, or choosing deployment regions."
---

# Carbon-Aware Architecture

> **Version**: 1.0.0 | **Last updated**: 2026-02-11

## Purpose

Carbon-aware architecture means building systems that respond to the variable carbon intensity of the electricity grid. The same computation emits different amounts of CO2 depending on *where* and *when* it runs. This skill provides the patterns, tools, and concrete implementation guidance to make software carbon-aware.

**Reference**: [GSF Carbon Aware SDK](https://github.com/Green-Software-Foundation/carbon-aware-sdk) | [Green Software Patterns](https://patterns.greensoftware.foundation/)

---

## Three Strategies

Carbon awareness operates through three complementary strategies. They are not mutually exclusive — the most effective systems combine all three.

### 1. Time Shifting (Temporal)

**Run workloads when the grid is cleaner.**

The carbon intensity of electricity varies throughout the day based on the renewable energy mix. Time shifting means scheduling deferrable workloads — batch jobs, ML training, CI builds, data pipelines, backups — to periods of lower carbon intensity.

**When to apply**: workloads that are not latency-sensitive and can tolerate scheduling delays of hours (or days for ML training).

**Typical impact**: 10–50% carbon reduction depending on grid variability and scheduling flexibility.

```typescript
import { z } from 'zod';

const CarbonForecastSchema = z.object({
  timestamp: z.string().datetime(),
  rating: z.number(), // gCO2eq/kWh
  location: z.string(),
});

type CarbonForecast = z.infer<typeof CarbonForecastSchema>;

/**
 * Find the optimal time window with lowest carbon intensity
 * within a given scheduling horizon.
 *
 * @param forecasts - Carbon intensity forecast data points
 * @param windowMinutes - Required execution window in minutes
 * @returns Best start time and average intensity for that window
 */
function findOptimalWindow(
  forecasts: CarbonForecast[],
  windowMinutes: number,
): { startTime: string; avgIntensity: number } {
  const windowSize = Math.ceil(windowMinutes / 60); // forecast points per window
  let bestStart = 0;
  let bestAvg = Infinity;

  for (let i = 0; i <= forecasts.length - windowSize; i++) {
    const windowForecasts = forecasts.slice(i, i + windowSize);
    const avg = windowForecasts.reduce((sum, f) => sum + f.rating, 0) / windowSize;
    if (avg < bestAvg) {
      bestAvg = avg;
      bestStart = i;
    }
  }

  return {
    startTime: forecasts[bestStart].timestamp,
    avgIntensity: bestAvg,
  };
}
```

### 2. Spatial Shifting (Location)

**Run workloads where the grid is cleaner.**

Different regions have vastly different carbon intensities. Spatial shifting means routing computation to regions with lower carbon intensity, when latency and data residency constraints allow.

**When to apply**: multi-region deployments, global batch processing, ML training where data can move, CI/CD with flexible runner location.

**Typical impact**: 20–75% carbon reduction (choosing Montreal over Iowa can reduce intensity by 95%).

```typescript
/**
 * Select the greenest region from a set of candidates
 * that meet latency and compliance requirements.
 *
 * @param candidates - Regions that meet non-carbon constraints
 * @param carbonData - Current carbon intensity per region
 * @returns The region with lowest carbon intensity
 */
function selectGreenestRegion(
  candidates: string[],
  carbonData: Map<string, number>,
): string {
  let bestRegion = candidates[0];
  let bestIntensity = Infinity;

  for (const region of candidates) {
    const intensity = carbonData.get(region);
    if (intensity !== undefined && intensity < bestIntensity) {
      bestIntensity = intensity;
      bestRegion = region;
    }
  }

  return bestRegion;
}
```

**Constraints**: data residency (GDPR requires EU data to stay in EU), latency requirements, egress costs. Spatial shifting operates within these bounds.

### 3. Demand Shaping

**Adjust workload intensity based on grid cleanliness.**

Instead of moving work in time or space, demand shaping adjusts how much work is done. When carbon intensity is low, do more (prefetch, pre-compute, warm caches). When it is high, do less (defer non-critical work, reduce quality, enable eco-mode).

**When to apply**: user-facing applications with variable workload, background processing with priority levels, applications with quality/timeliness trade-offs.

**Typical impact**: 5–20% carbon reduction, highly dependent on the application's ability to modulate workload.

```typescript
/**
 * Determine workload priority based on current carbon intensity.
 *
 * @param currentIntensity - Current grid carbon intensity (gCO2eq/kWh)
 * @param thresholds - Intensity thresholds for each priority level
 * @returns Which workload categories should run now
 */
function getWorkloadPolicy(
  currentIntensity: number,
  thresholds = { low: 100, medium: 250, high: 400 },
): { runCritical: boolean; runStandard: boolean; runDeferrable: boolean } {
  return {
    runCritical: true, // Always run critical work
    runStandard: currentIntensity <= thresholds.high,
    runDeferrable: currentIntensity <= thresholds.low,
  };
}
```

---

## Carbon Aware SDK Integration

The GSF Carbon Aware SDK provides a unified interface to carbon intensity data from multiple providers (WattTime, Electricity Maps). It exposes a REST API and CLI.

### Deployment

```yaml
# docker-compose.yml — Carbon Aware SDK as sidecar
services:
  carbon-aware-sdk:
    image: ghcr.io/green-software-foundation/carbon-aware-sdk:latest
    environment:
      - DataSources__ForecastDataSource=WattTime
      - DataSources__WattTime__Username=${WATTTIME_USERNAME}
      - DataSources__WattTime__Password=${WATTTIME_PASSWORD}
    ports:
      - "8090:80"

  scheduler:
    build: ./scheduler
    environment:
      - CARBON_AWARE_SDK_URL=http://carbon-aware-sdk:80
    depends_on:
      - carbon-aware-sdk
```

### SDK API Usage

```typescript
const CARBON_SDK_BASE = process.env.CARBON_AWARE_SDK_URL ?? 'http://localhost:8090';

/**
 * Get current carbon intensity for a location.
 */
async function getCurrentIntensity(location: string): Promise<number> {
  const response = await fetch(
    `${CARBON_SDK_BASE}/emissions/bylocation?location=${location}&time=${new Date().toISOString()}`
  );
  if (!response.ok) {
    throw new Error(`Carbon Aware SDK error: ${response.status}`);
  }
  const data = await response.json();
  return data[0]?.rating ?? 0;
}

/**
 * Get forecast and find optimal window for a deferrable workload.
 */
async function getOptimalSchedule(
  location: string,
  windowMinutes: number,
): Promise<{ startTime: string; intensity: number }> {
  const response = await fetch(
    `${CARBON_SDK_BASE}/emissions/forecasts/current?location=${location}`
  );
  if (!response.ok) {
    throw new Error(`Carbon Aware SDK forecast error: ${response.status}`);
  }
  const forecast = await response.json();
  return findOptimalWindow(forecast[0].forecastData, windowMinutes);
}
```

---

## Carbon-Aware Patterns Catalog

Patterns from the GSF catalog, organized by applicability:

### Infrastructure Patterns

| Pattern | Principle | Action |
|---------|----------|--------|
| **Scale-to-zero in clean hours** | Carbon Awareness + Energy | Auto-scale aggressively when grid is clean, hold minimum when dirty |
| **Green region preference** | Carbon Awareness | Default to lowest-carbon region that meets latency/compliance |
| **ARM-first compute** | Hardware Efficiency | ARM instances use ~40% less energy per compute unit |
| **Right-size containers** | Energy Efficiency | CPU/memory limits based on actual usage, not worst-case |
| **Multi-arch builds** | Hardware + Energy | Support ARM64 + AMD64 to run on most efficient hardware |

### Application Patterns

| Pattern | Principle | Action |
|---------|----------|--------|
| **Cache aggressively** | Energy Efficiency | Every cache hit avoids compute and network energy |
| **Compress payloads** | Energy Efficiency | Less data transferred = less network energy |
| **Lazy evaluation** | Energy Efficiency | Compute only what is needed, when it is needed |
| **Efficient serialization** | Energy Efficiency | Protocol Buffers over JSON for high-throughput internal APIs |
| **Reduce page weight** | Energy + Hardware | Smaller web pages = less energy on client and server |
| **Progressive enhancement** | Hardware Efficiency | Works on older devices, degrades gracefully |

### CI/CD Patterns

| Pattern | Principle | Action |
|---------|----------|--------|
| **Carbon-aware scheduling** | Carbon Awareness | Run non-urgent CI in low-carbon windows |
| **Aggressive caching** | Energy Efficiency | Cache dependencies, Docker layers, build outputs |
| **Minimal build matrix** | Energy Efficiency | Test on representative subset, full matrix only on release |
| **Green runners** | Carbon Awareness | Use CI runners in low-carbon regions |

### Data Patterns

| Pattern | Principle | Action |
|---------|----------|--------|
| **Data minimization** | Energy Efficiency | Store and process only what you need (aligns with GDPR) |
| **Cold storage lifecycle** | Energy Efficiency | Move old data to low-energy storage tiers |
| **Efficient queries** | Energy Efficiency | Proper indexing, avoid full table scans, use projections |
| **Batch over stream** | Energy Efficiency | Batch processing is more energy-efficient per record |

---

## Carbon-Aware CI/CD

### GitHub Actions with Carbon Awareness

```yaml
# .github/workflows/carbon-aware-build.yml
name: Carbon-Aware Build

on:
  push:
    branches: [main]

jobs:
  check-carbon:
    runs-on: ubuntu-latest
    outputs:
      should-defer: ${{ steps.check.outputs.defer }}
      intensity: ${{ steps.check.outputs.intensity }}
    steps:
      - name: Check current carbon intensity
        id: check
        run: |
          # Query carbon intensity for the runner region
          INTENSITY=$(curl -s "${CARBON_SDK_URL}/emissions/bylocation?location=CAISO_NORTH" \
            | jq '.[0].rating')
          echo "intensity=${INTENSITY}" >> "$GITHUB_OUTPUT"
          # Defer non-critical builds if intensity > 400 gCO2eq/kWh
          if (( $(echo "$INTENSITY > 400" | bc -l) )); then
            echo "defer=true" >> "$GITHUB_OUTPUT"
          else
            echo "defer=false" >> "$GITHUB_OUTPUT"
          fi

  build:
    needs: check-carbon
    if: needs.check-carbon.outputs.should-defer == 'false'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and test
        run: npm ci && npm run build && npm test

  defer-build:
    needs: check-carbon
    if: needs.check-carbon.outputs.should-defer == 'true'
    runs-on: ubuntu-latest
    steps:
      - name: Schedule for lower intensity
        run: |
          echo "Carbon intensity too high (${{ needs.check-carbon.outputs.intensity }} gCO2eq/kWh)."
          echo "Build deferred. Will retry in next low-carbon window."
          # Trigger workflow_dispatch with delay or use scheduler
```

### Terraform: Carbon-Aware Region Selection

```hcl
variable "candidate_regions" {
  description = "Regions that meet latency and compliance requirements"
  type        = list(string)
  default     = ["europe-west1", "europe-north1", "europe-west9"]
}

variable "carbon_intensity_map" {
  description = "Approximate annual gCO2eq/kWh per GCP region"
  type        = map(number)
  default = {
    "europe-north1"           = 50   # Finland — nuclear + hydro
    "europe-west9"            = 60   # Paris — nuclear
    "us-west1"                = 80   # Oregon — hydro
    "europe-west1"            = 150  # Belgium — mixed
    "northamerica-northeast1" = 20   # Montreal — hydro
    "europe-west4"            = 340  # Netherlands — gas
    "us-central1"             = 400  # Iowa — mixed
  }
}

locals {
  # Select the greenest region from candidates
  greenest_region = element(
    sort([for r in var.candidate_regions : r]),
    index(
      [for r in sort(var.candidate_regions) : var.carbon_intensity_map[r]],
      min([for r in var.candidate_regions : var.carbon_intensity_map[r]]...)
    )
  )
}

resource "google_cloud_run_v2_service" "api" {
  name     = "invoice-api"
  location = local.greenest_region
  # ... rest of configuration
}
```

---

## Region Selection Decision Framework

When choosing a deployment region, evaluate three dimensions:

```
┌──────────────────────────────────────────────┐
│           REGION SELECTION MATRIX             │
├──────────────┬───────────┬───────────────────┤
│   Dimension  │  Weight   │    Constraint     │
├──────────────┼───────────┼───────────────────┤
│ Compliance   │ MUST      │ Data residency    │
│ Latency      │ HIGH      │ p99 < target      │
│ Carbon       │ MEDIUM    │ Prefer lowest CI  │
│ Cost         │ MEDIUM    │ Within budget     │
│ Availability │ HIGH      │ Multi-zone min    │
└──────────────┴───────────┴───────────────────┘

Step 1: Filter by compliance (eliminate non-compliant regions)
Step 2: Filter by latency (eliminate regions exceeding p99 target)
Step 3: Score remaining by: carbon intensity (40%) + cost (30%) + availability (30%)
Step 4: Document decision in ADR with "Sustainability Impact" section
```

---

## Monitoring Carbon Awareness

### Custom Metrics

```typescript
import { metrics } from '@opentelemetry/api';

const meter = metrics.getMeter('carbon-awareness');

const carbonIntensityGauge = meter.createObservableGauge(
  'carbon.grid.intensity',
  { description: 'Current grid carbon intensity in gCO2eq/kWh', unit: 'gCO2eq/kWh' },
);

const carbonEmissionsCounter = meter.createCounter(
  'carbon.emissions.total',
  { description: 'Estimated CO2 emissions in gCO2eq', unit: 'gCO2eq' },
);

const workloadDeferredCounter = meter.createCounter(
  'carbon.workload.deferred',
  { description: 'Workloads deferred due to high carbon intensity' },
);

// Observe grid intensity periodically
carbonIntensityGauge.addCallback(async (result) => {
  const intensity = await getCurrentIntensity(process.env.GRID_REGION ?? 'IE');
  result.observe(intensity, { region: process.env.GRID_REGION ?? 'IE' });
});
```

---

## Anti-Patterns

- **"Carbon data is too unreliable"**: even approximate data enables significant reductions. Perfect is the enemy of good.
- **"Latency always wins"**: for deferrable workloads, latency is irrelevant. Distinguish critical path from background work.
- **"Carbon-aware = complex"**: start with region selection (static). Graduate to time-shifting (scheduled). Advanced: real-time demand shaping.
- **"Our provider handles it"**: cloud providers optimize their own footprint, not yours. Your scheduling and architecture choices still matter enormously.
- **"Green region, done"**: a green region with inefficient code is worse than a mixed region with optimized code. Carbon awareness complements, not replaces, energy efficiency.

---

## For Claude Code

When generating infrastructure: suggest low-carbon regions from the candidate set, include carbon intensity as a comment alongside cost in Terraform/Pulumi, generate carbon-aware scheduling for batch workloads. When generating CI/CD: suggest caching strategies, minimal build matrices, and carbon-aware scheduling for non-urgent pipelines. Always combine carbon awareness with energy efficiency — they are not alternatives, they are complements.

---

*Internal references*: `green-software-principles/SKILL.md`, `sci-measurement/SKILL.md`, `infrastructure-as-code/SKILL.md`, `cicd-pipeline/SKILL.md`, `observability/SKILL.md`, `finops/SKILL.md`
