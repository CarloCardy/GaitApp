import { extractGaitPeaks } from "../algorithms/gaitPeaks";
import { matToAngles, Matrix3x3, RotationOrder } from "../algorithms/mat2ang";
import { segmentSignalWithIdx } from "../algorithms/segmentSignal";

export type XsensParsedFile = {
  baseName: string;
  deviceId: string;
  matrices: Matrix3x3[];
  sampleCount: number;
};

export type XsensTriplet = {
  foot: Matrix3x3[];
  tibia: Matrix3x3[];
  hip: Matrix3x3[];
  baseName: string;
};

export type XsensTripletResult = {
  baseName: string;
  time: number[];
  footPitch: number[];
  tibiaPitch: number[];
  hipPitch: number[];
  anklePitch: number[];
  kneePitch: number[];
  phases: GaitPhase[];
  steps: {
    count: number;
    heelStrikeIndices: number[];
    toeOffIndices: number[];
    stepDuration: number[];
    stanceDuration: number[];
    swingDuration: number[];
    stancePercent: number[];
    swingPercent: number[];
    stanceMean: number;
    swingMean: number;
  };
  segments: {
    hip: number[][];
    knee: number[][];
    ankle: number[][];
    hipMean: number[];
    kneeMean: number[];
    ankleMean: number[];
  };
  peaks: ReturnType<typeof extractGaitPeaks>["peaks"];
  peakSummary: ReturnType<typeof extractGaitPeaks>["summary"];
  meanEvents: {
    hip: EventMarker[];
    knee: EventMarker[];
    ankle: EventMarker[];
  };
};

export type GaitPhase = {
  label: string;
  start: number;
  end: number;
  type: "stance" | "swing";
};

export type EventMarker = {
  label: string;
  index: number;
  value: number;
  type: "max" | "min";
};

const DEVICE_MAP: Record<string, "foot" | "tibia" | "hip"> = {
  "00B4CAF0": "foot",
  "00B4CBA7": "tibia",
  "00B4CB9F": "hip",
};

const DEFAULT_SAMPLE_RATE = 100;
const DEFAULT_T_START = 0.25;
const DEFAULT_T_END = 17.85;

const GAIT_PHASES: GaitPhase[] = [
  { label: "IC", start: 0, end: 0, type: "stance" },
  { label: "LR", start: 0, end: 10, type: "stance" },
  { label: "MS", start: 10, end: 30, type: "stance" },
  { label: "TS", start: 30, end: 50, type: "stance" },
  { label: "PS", start: 50, end: 60, type: "stance" },
  { label: "ISw", start: 60, end: 73, type: "swing" },
  { label: "MSw", start: 73, end: 87, type: "swing" },
  { label: "TSw", start: 87, end: 100, type: "swing" },
];

export const parseXsensTxt = (content: string, fileName?: string): XsensParsedFile => {
  const lines = content
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0);

  const deviceId = extractDeviceId(lines) ?? extractDeviceIdFromName(fileName);
  if (!deviceId) {
    throw new Error("DeviceId non trovato nel file.");
  }

  const baseName = extractBaseName(fileName, deviceId);

  const headerIndex = lines.findIndex(
    (line) => line.includes("PacketCounter") && line.includes("Mat[1][1]")
  );
  if (headerIndex === -1) {
    throw new Error("Header PacketCounter non trovato.");
  }

  const dataLines = lines.slice(headerIndex + 1);
  const matrices: Matrix3x3[] = [];

  dataLines.forEach((line) => {
    const values = line.split(/\t+/).map((value) => Number(value));
    if (values.length < 16 || values.some((value) => Number.isNaN(value))) {
      return;
    }

    const m11 = values[7];
    const m21 = values[8];
    const m31 = values[9];
    const m12 = values[10];
    const m22 = values[11];
    const m32 = values[12];
    const m13 = values[13];
    const m23 = values[14];
    const m33 = values[15];

    matrices.push([
      [m11, m12, m13],
      [m21, m22, m23],
      [m31, m32, m33],
    ]);
  });

  if (matrices.length === 0) {
    throw new Error("Nessun dato valido trovato nel file.");
  }

  return {
    baseName,
    deviceId,
    matrices,
    sampleCount: matrices.length,
  };
};

export const buildTriplet = (files: XsensParsedFile[]): XsensTriplet => {
  const baseName = files[0]?.baseName ?? "";
  const byPlacement: Partial<Record<"foot" | "tibia" | "hip", Matrix3x3[]>> = {};

  files.forEach((file) => {
    const placement = DEVICE_MAP[file.deviceId];
    if (!placement) {
      throw new Error(`DeviceId sconosciuto: ${file.deviceId}`);
    }
    byPlacement[placement] = file.matrices;
  });

  if (!byPlacement.foot || !byPlacement.tibia || !byPlacement.hip) {
    throw new Error("Mancano uno o più sensori (foot/tibia/hip).");
  }

  return {
    baseName,
    foot: byPlacement.foot,
    tibia: byPlacement.tibia,
    hip: byPlacement.hip,
  };
};

export const processTriplet = (
  triplet: XsensTriplet,
  rotationOrder: RotationOrder = "ZXY",
  sampleRate = DEFAULT_SAMPLE_RATE,
  tStart = DEFAULT_T_START,
  tEnd = DEFAULT_T_END
): XsensTripletResult => {
  const footAngles = matToAngles(triplet.foot, rotationOrder).pitch;
  const tibiaAngles = matToAngles(triplet.tibia, rotationOrder).pitch;
  const hipAngles = matToAngles(triplet.hip, rotationOrder).pitch;

  const footTrim = trimByTime(footAngles, sampleRate, tStart, tEnd);
  const tibiaTrim = trimByTime(tibiaAngles, sampleRate, tStart, tEnd);
  const hipTrim = trimByTime(hipAngles, sampleRate, tStart, tEnd);

  const { signals: [footInterp, tibiaInterp, hipInterp], time } = interpolateSignals(
    [footTrim.signal, tibiaTrim.signal, hipTrim.signal],
    [footTrim.time, tibiaTrim.time, hipTrim.time]
  );

  const ankle = footInterp.map((value, index) => value - tibiaInterp[index] - 70);
  const knee = tibiaInterp.map((value, index) => -(value - hipInterp[index]));
  const hipAdjusted = hipInterp.map((value) => value + 90);

  const steps = computeSteps(footInterp, time, sampleRate);
  const { segments, meanCurves } = segmentTriplet(
    hipAdjusted,
    knee,
    ankle,
    steps.heelStrikeIndices
  );

  const { peaks, summary } = extractGaitPeaks(segments.hip, segments.knee, segments.ankle, {
    adaptive: true,
    stdFactor: 0.2,
    minMargin: 2,
    maxMargin: 12,
  });

  const meanPeaks = extractGaitPeaks(
    [meanCurves.hip],
    [meanCurves.knee],
    [meanCurves.ankle],
    {
      adaptive: true,
      stdFactor: 0.2,
      minMargin: 2,
      maxMargin: 12,
    }
  );

  return {
    baseName: triplet.baseName,
    time,
    footPitch: footInterp,
    tibiaPitch: tibiaInterp,
    hipPitch: hipAdjusted,
    anklePitch: ankle,
    kneePitch: knee,
    phases: GAIT_PHASES,
    steps,
    segments: {
      hip: segments.hip,
      knee: segments.knee,
      ankle: segments.ankle,
      hipMean: meanCurves.hip,
      kneeMean: meanCurves.knee,
      ankleMean: meanCurves.ankle,
    },
    peaks,
    peakSummary: summary,
    meanEvents: {
      hip: buildEventMarkers("hip", meanPeaks.peaks.hip, meanPeaks.indices.hip),
      knee: buildEventMarkers("knee", meanPeaks.peaks.knee, meanPeaks.indices.knee),
      ankle: buildEventMarkers("ankle", meanPeaks.peaks.ankle, meanPeaks.indices.ankle),
    },
  };
};

const extractDeviceId = (lines: string[]): string | null => {
  const matchLine = lines.find((line) => line.includes("DeviceId:"));
  if (!matchLine) {
    return null;
  }
  const match = matchLine.match(/DeviceId:\s*([0-9A-F]+)/i);
  return match?.[1] ?? null;
};

const extractDeviceIdFromName = (fileName?: string): string | null => {
  if (!fileName) {
    return null;
  }
  const match = fileName.match(/_([0-9A-F]{8})\.txt$/i);
  return match?.[1] ?? null;
};

const extractBaseName = (fileName: string | undefined, deviceId: string): string => {
  if (!fileName) {
    return `MT_${deviceId}`;
  }
  const normalized = fileName.trim();
  const match = normalized.match(/^(.*)_[0-9A-F]{8}\.txt$/i);
  if (match?.[1]) {
    return match[1];
  }
  return normalized.replace(/\.txt$/i, "");
};

const trimByTime = (signal: number[], fs: number, start: number, end: number) => {
  const time = signal.map((_, index) => (index + 1) / fs);
  const maxTime = time[time.length - 1] ?? 0;
  const tEnd = Math.min(end, maxTime);
  const startIndex = time.findIndex((value) => value >= start);
  const endIndex = time.findIndex((value) => value >= tEnd);
  const safeStart = startIndex < 0 ? 0 : startIndex;
  const safeEnd = endIndex < 0 ? signal.length - 1 : endIndex;

  return {
    time: time.slice(safeStart, safeEnd + 1),
    signal: signal.slice(safeStart, safeEnd + 1),
  };
};

const interpolateSignals = (
  signals: number[][],
  times: number[][]
): { signals: number[][]; time: number[] } => {
  const lengths = times.map((time) => time.length);
  const maxIndex = lengths.reduce((maxIdx, length, idx, arr) => (length > arr[maxIdx] ? idx : maxIdx), 0);
  const tCommon = times[maxIndex];

  const resampled = signals.map((signal, index) => {
    const time = times[index];
    if (time.length === tCommon.length && time.every((value, idx) => value === tCommon[idx])) {
      return signal.slice();
    }
    return interpolate(time, signal, tCommon);
  });

  const cleaned = resampled.map((signal) => fillNaNs(signal, tCommon));

  return { signals: cleaned, time: tCommon };
};

const interpolate = (x: number[], y: number[], xNew: number[]): number[] => {
  return xNew.map((value) => interpolatePoint(x, y, value));
};

const interpolatePoint = (x: number[], y: number[], value: number): number => {
  if (x.length === 0) {
    return 0;
  }
  if (value <= x[0]) {
    return y[0];
  }
  if (value >= x[x.length - 1]) {
    return y[y.length - 1];
  }

  let idx = x.findIndex((item) => item >= value);
  if (idx <= 0) {
    idx = 1;
  }
  const x0 = x[idx - 1];
  const x1 = x[idx];
  const y0 = y[idx - 1];
  const y1 = y[idx];
  const ratio = (value - x0) / (x1 - x0);
  return y0 + ratio * (y1 - y0);
};

const fillNaNs = (signal: number[], time: number[]): number[] => {
  if (!signal.some((value) => Number.isNaN(value))) {
    return signal;
  }
  const valid = signal
    .map((value, index) => ({ value, time: time[index] }))
    .filter(({ value }) => !Number.isNaN(value));
  const validTime = valid.map((item) => item.time);
  const validValues = valid.map((item) => item.value);

  return time.map((value) => interpolatePoint(validTime, validValues, value));
};

const detectHeelStrikes = (signal: number[], fs: number) => {
  const base = signal[0] ?? 0;
  const aligned = signal.map((value) => value - base);
  const minDistance = Math.max(1, Math.round(0.2 * fs));
  const meanValue = mean(aligned);
  const stdValue = std(aligned);
  const minPeak = Math.max(5, meanValue + 0.5 * stdValue);
  const peaks: number[] = [];
  const candidates: { index: number; value: number }[] = [];

  for (let i = 1; i < aligned.length - 1; i += 1) {
    if (aligned[i] > aligned[i - 1] && aligned[i] > aligned[i + 1]) {
      candidates.push({ index: i, value: aligned[i] });
    }
  }

  candidates
    .filter((item) => item.value >= minPeak)
    .forEach((item) => {
      if (peaks.length === 0 || item.index - peaks[peaks.length - 1] >= minDistance) {
        peaks.push(item.index);
      }
    });

  if (peaks.length >= 2) {
    return peaks;
  }

  candidates
    .sort((a, b) => b.value - a.value)
    .forEach((item) => {
      if (peaks.length >= 6) {
        return;
      }
      if (peaks.every((existing) => Math.abs(existing - item.index) >= minDistance)) {
        peaks.push(item.index);
      }
    });

  return peaks.sort((a, b) => a - b);
};

const computeSteps = (signal: number[], time: number[], fs: number) => {
  const heelStrike = detectHeelStrikes(signal, fs);
  const fallbackStart = 0;
  const fallbackEnd = Math.max(0, signal.length - 1);
  const usableHeelStrike =
    heelStrike.length >= 2 ? heelStrike : fallbackEnd > 0 ? [fallbackStart, fallbackEnd] : [];
  if (usableHeelStrike.length < 2) {
    return {
      count: 0,
      heelStrikeIndices: [],
      toeOffIndices: [],
      stepDuration: [],
      stanceDuration: [],
      swingDuration: [],
      stancePercent: [],
      swingPercent: [],
      stanceMean: 0,
      swingMean: 0,
    };
  }

  const toeOff: number[] = [];
  const stepDuration: number[] = [];
  const stanceDuration: number[] = [];
  const swingDuration: number[] = [];
  const stancePercent: number[] = [];
  const swingPercent: number[] = [];

  for (let i = 0; i < usableHeelStrike.length - 1; i += 1) {
    const start = usableHeelStrike[i];
    const end = usableHeelStrike[i + 1];
    if (start < 0 || end <= start || end >= signal.length) {
      continue;
    }
    const segment = signal.slice(start, end + 1);
    const minValue = Math.min(...segment);
    const minIndexLocal = segment.indexOf(minValue);
    const toeIndex = start + minIndexLocal;
    toeOff.push(toeIndex);

    const tStart = time[start] ?? 0;
    const tToe = time[toeIndex] ?? tStart;
    const tEnd = time[end] ?? tToe;
    const step = tEnd - tStart;
    const stance = tToe - tStart;
    const swing = tEnd - tToe;
    if (step <= 0) {
      continue;
    }
    stepDuration.push(step);
    stanceDuration.push(stance);
    swingDuration.push(swing);
    stancePercent.push((stance / step) * 100);
    swingPercent.push((swing / step) * 100);
  }

  return {
    count: stepDuration.length,
    heelStrikeIndices: usableHeelStrike.slice(0, stepDuration.length + 1),
    toeOffIndices: toeOff,
    stepDuration,
    stanceDuration,
    swingDuration,
    stancePercent,
    swingPercent,
    stanceMean: mean(stancePercent),
    swingMean: mean(swingPercent),
  };
};

const segmentTriplet = (
  hip: number[],
  knee: number[],
  ankle: number[],
  heelStrikeIndices: number[]
) => {
  const start = heelStrikeIndices.slice(0, -1);
  const end = heelStrikeIndices.slice(1);

  const hipSegments = segmentSignalWithIdx(hip, start, end);
  const kneeSegments = segmentSignalWithIdx(knee, start, end);
  const ankleSegments = segmentSignalWithIdx(ankle, start, end);

  const filteredHip: number[][] = [];
  const filteredKnee: number[][] = [];
  const filteredAnkle: number[][] = [];

  hipSegments.forEach((segment, index) => {
    const kneeSegment = kneeSegments[index];
    const ankleSegment = ankleSegments[index];
    if (segment.length === 0 || kneeSegment.length === 0 || ankleSegment.length === 0) {
      return;
    }
    filteredHip.push(segment);
    filteredKnee.push(kneeSegment);
    filteredAnkle.push(ankleSegment);
  });

  return {
    segments: {
      hip: filteredHip,
      knee: filteredKnee,
      ankle: filteredAnkle,
    },
    meanCurves: {
      hip: meanCurve(filteredHip),
      knee: meanCurve(filteredKnee),
      ankle: meanCurve(filteredAnkle),
    },
  };
};

const meanCurve = (segments: number[][]): number[] => {
  if (segments.length === 0) {
    return [];
  }
  const length = segments[0].length;
  const result = Array.from({ length }, () => 0);
  segments.forEach((segment) => {
    segment.forEach((value, index) => {
      result[index] += value;
    });
  });
  return result.map((value) => value / segments.length);
};

const mean = (values: number[]) => {
  if (values.length === 0) {
    return 0;
  }
  return values.reduce((sum, value) => sum + value, 0) / values.length;
};

const EVENT_TYPES_BY_JOINT: Record<string, Record<string, "max" | "min">> = {
  hip: {
    initialContact: "max",
    terminalSwing: "max",
    terminalStance: "min",
  },
  knee: {
    loadingResponse: "max",
    initialSwing: "max",
    initialContact: "min",
    midTerminalStance: "min",
  },
  ankle: {
    midTerminalStance: "max",
    swing: "max",
    loadingResponse: "min",
    preSwing: "min",
  },
};

const buildEventMarkers = (
  joint: "hip" | "knee" | "ankle",
  values: Record<string, number[]>,
  indices: Record<string, number[]>
): EventMarker[] => {
  return Object.keys(values).flatMap((key) => {
    const valueList = values[key];
    const indexList = indices[key] ?? [];
    if (valueList.length === 0 || indexList.length === 0) {
      return [];
    }
    const typeMap = EVENT_TYPES_BY_JOINT[joint] ?? {};
    return [
      {
        label: key,
        index: Math.max(0, (indexList[0] ?? 1) - 1),
        value: valueList[0],
        type: typeMap[key] ?? "max",
      },
    ];
  });
};

const std = (values: number[]) => {
  if (values.length === 0) {
    return 0;
  }
  const average = mean(values);
  const variance =
    values.reduce((sum, value) => sum + (value - average) ** 2, 0) / values.length;
  return Math.sqrt(variance);
};
