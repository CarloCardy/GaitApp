import { GaitPeaks } from "../models/imu";

type PeakResult = {
  values: number[];
  indices: number[];
};

type PeakStats = {
  mean: number;
  std: number;
  meanIndex: number;
  stdIndex: number;
};

export type GaitPeakSummary = {
  hip: Record<string, PeakStats>;
  knee: Record<string, PeakStats>;
  ankle: Record<string, PeakStats>;
};

export type GaitPeakIndices = {
  hip: Record<string, number[]>;
  knee: Record<string, number[]>;
  ankle: Record<string, number[]>;
};

type PeakWindow = { start: number; end: number };

export type GaitPeakOptions = {
  adaptive?: boolean;
  minMargin?: number;
  maxMargin?: number;
  stdFactor?: number;
};

const findPeaks = (values: number[]): PeakResult => {
  const peaks: number[] = [];
  const indices: number[] = [];

  for (let i = 1; i < values.length - 1; i += 1) {
    if (values[i] > values[i - 1] && values[i] > values[i + 1]) {
      peaks.push(values[i]);
      indices.push(i + 1);
    }
  }

  return { values: peaks, indices };
};

const findNegativePeaks = (values: number[]): PeakResult => {
  const inverted = values.map((value) => -value);
  const peaks = findPeaks(inverted);
  return {
    values: peaks.values.map((value) => -value),
    indices: peaks.indices,
  };
};

const rangePeak = (peaks: PeakResult, start: number, end: number, mode: "max" | "min") => {
  const candidates = peaks.values
    .map((value, idx) => ({ value, index: peaks.indices[idx] }))
    .filter(({ index }) => index >= start && index <= end);

  if (candidates.length === 0) {
    return null;
  }

  const selected = candidates.reduce((prev, current) => {
    if (mode === "max") {
      return current.value > prev.value ? current : prev;
    }
    return current.value < prev.value ? current : prev;
  });

  return selected;
};

const mean = (values: number[]) =>
  values.length === 0 ? 0 : values.reduce((sum, value) => sum + value, 0) / values.length;

const std = (values: number[]) => {
  if (values.length === 0) {
    return 0;
  }
  const average = mean(values);
  const variance = mean(values.map((value) => (value - average) ** 2));
  return Math.sqrt(variance);
};

const summaryFrom = (values: number[], indices: number[]): PeakStats => ({
  mean: mean(values),
  std: std(values),
  meanIndex: mean(indices),
  stdIndex: std(indices),
});

const clamp = (value: number, minValue: number, maxValue: number) =>
  Math.min(maxValue, Math.max(minValue, value));

const adaptiveWindow = (window: PeakWindow, values: number[], options?: GaitPeakOptions) => {
  if (!options?.adaptive) {
    return window;
  }
  const minMargin = options.minMargin ?? 2;
  const maxMargin = options.maxMargin ?? 10;
  const stdFactor = options.stdFactor ?? 0.2;
  const margin = clamp(Math.round(std(values) * stdFactor), minMargin, maxMargin);
  return {
    start: clamp(window.start - margin, 1, 100),
    end: clamp(window.end + margin, 1, 100),
  };
};

const rangePeakAdaptive = (
  peaks: PeakResult,
  window: PeakWindow,
  values: number[],
  mode: "max" | "min",
  options?: GaitPeakOptions
) => {
  const adjusted = adaptiveWindow(window, values, options);
  return rangePeak(peaks, adjusted.start, adjusted.end, mode);
};

export const extractGaitPeaks = (
  hipSegments: number[][],
  kneeSegments: number[][],
  ankleSegments: number[][],
  options?: GaitPeakOptions
): { peaks: GaitPeaks; indices: GaitPeakIndices; summary: GaitPeakSummary } => {
  const hip = {
    initialContact: [] as number[],
    terminalSwing: [] as number[],
    terminalStance: [] as number[],
  };
  const hipIdx = {
    initialContact: [] as number[],
    terminalSwing: [] as number[],
    terminalStance: [] as number[],
  };
  const knee = {
    loadingResponse: [] as number[],
    initialSwing: [] as number[],
    initialContact: [] as number[],
    midTerminalStance: [] as number[],
  };
  const kneeIdx = {
    loadingResponse: [] as number[],
    initialSwing: [] as number[],
    initialContact: [] as number[],
    midTerminalStance: [] as number[],
  };
  const ankle = {
    midTerminalStance: [] as number[],
    swing: [] as number[],
    loadingResponse: [] as number[],
    preSwing: [] as number[],
  };
  const ankleIdx = {
    midTerminalStance: [] as number[],
    swing: [] as number[],
    loadingResponse: [] as number[],
    preSwing: [] as number[],
  };

  hipSegments.forEach((hipSegment, index) => {
    const kneeSegment = kneeSegments[index];
    const ankleSegment = ankleSegments[index];

    const hipMax = findPeaks(hipSegment);
    const hipMin = findNegativePeaks(hipSegment);

    const hipInitial = rangePeakAdaptive(hipMax, { start: 1, end: 15 }, hipSegment, "max", options);
    if (hipInitial) {
      hip.initialContact.push(hipInitial.value);
      hipIdx.initialContact.push(hipInitial.index);
    }

    const hipTerminalSwing = rangePeakAdaptive(
      hipMax,
      { start: 70, end: 100 },
      hipSegment,
      "max",
      options
    );
    if (hipTerminalSwing) {
      hip.terminalSwing.push(hipTerminalSwing.value);
      hipIdx.terminalSwing.push(hipTerminalSwing.index);
    }

    const hipTerminalStance = rangePeakAdaptive(
      hipMin,
      { start: 30, end: 80 },
      hipSegment,
      "min",
      options
    );
    if (hipTerminalStance) {
      hip.terminalStance.push(hipTerminalStance.value);
      hipIdx.terminalStance.push(hipTerminalStance.index);
    }

    const kneeMax = findPeaks(kneeSegment);
    const kneeMin = findNegativePeaks(kneeSegment);

    const kneeLoading = rangePeakAdaptive(
      kneeMax,
      { start: 5, end: 20 },
      kneeSegment,
      "max",
      options
    );
    if (kneeLoading) {
      knee.loadingResponse.push(kneeLoading.value);
      kneeIdx.loadingResponse.push(kneeLoading.index);
    }

    const kneeSwing = rangePeakAdaptive(
      kneeMax,
      { start: 55, end: 90 },
      kneeSegment,
      "max",
      options
    );
    if (kneeSwing) {
      knee.initialSwing.push(kneeSwing.value);
      kneeIdx.initialSwing.push(kneeSwing.index);
    }

    const kneeInitialContact = rangePeakAdaptive(
      kneeMin,
      { start: 1, end: 10 },
      kneeSegment,
      "min",
      options
    );
    if (kneeInitialContact) {
      knee.initialContact.push(kneeInitialContact.value);
      kneeIdx.initialContact.push(kneeInitialContact.index);
    }

    const kneeMidTerminal = rangePeakAdaptive(
      kneeMin,
      { start: 30, end: 50 },
      kneeSegment,
      "min",
      options
    );
    if (kneeMidTerminal) {
      knee.midTerminalStance.push(kneeMidTerminal.value);
      kneeIdx.midTerminalStance.push(kneeMidTerminal.index);
    }

    const ankleMax = findPeaks(ankleSegment);
    const ankleMin = findNegativePeaks(ankleSegment);

    const ankleMidTerminal = rangePeakAdaptive(
      ankleMax,
      { start: 5, end: 70 },
      ankleSegment,
      "max",
      options
    );
    if (ankleMidTerminal) {
      ankle.midTerminalStance.push(ankleMidTerminal.value);
      ankleIdx.midTerminalStance.push(ankleMidTerminal.index);
    }

    const ankleSwing = rangePeakAdaptive(
      ankleMax,
      { start: 60, end: 100 },
      ankleSegment,
      "max",
      options
    );
    if (ankleSwing) {
      ankle.swing.push(ankleSwing.value);
      ankleIdx.swing.push(ankleSwing.index);
    }

    const ankleLoading = rangePeakAdaptive(
      ankleMin,
      { start: 1, end: 15 },
      ankleSegment,
      "min",
      options
    );
    if (ankleLoading) {
      ankle.loadingResponse.push(ankleLoading.value);
      ankleIdx.loadingResponse.push(ankleLoading.index);
    }

    const anklePreSwing = rangePeakAdaptive(
      ankleMin,
      { start: 50, end: 85 },
      ankleSegment,
      "min",
      options
    );
    if (anklePreSwing) {
      ankle.preSwing.push(anklePreSwing.value);
      ankleIdx.preSwing.push(anklePreSwing.index);
    }
  });

  const peaks: GaitPeaks = {
    hip,
    knee,
    ankle,
  };

  const indices: GaitPeakIndices = {
    hip: hipIdx,
    knee: kneeIdx,
    ankle: ankleIdx,
  };

  const summary: GaitPeakSummary = {
    hip: {
      initialContact: summaryFrom(hip.initialContact, hipIdx.initialContact),
      terminalSwing: summaryFrom(hip.terminalSwing, hipIdx.terminalSwing),
      terminalStance: summaryFrom(hip.terminalStance, hipIdx.terminalStance),
    },
    knee: {
      loadingResponse: summaryFrom(knee.loadingResponse, kneeIdx.loadingResponse),
      initialSwing: summaryFrom(knee.initialSwing, kneeIdx.initialSwing),
      initialContact: summaryFrom(knee.initialContact, kneeIdx.initialContact),
      midTerminalStance: summaryFrom(knee.midTerminalStance, kneeIdx.midTerminalStance),
    },
    ankle: {
      midTerminalStance: summaryFrom(ankle.midTerminalStance, ankleIdx.midTerminalStance),
      swing: summaryFrom(ankle.swing, ankleIdx.swing),
      loadingResponse: summaryFrom(ankle.loadingResponse, ankleIdx.loadingResponse),
      preSwing: summaryFrom(ankle.preSwing, ankleIdx.preSwing),
    },
  };

  return { peaks, indices, summary };
};
