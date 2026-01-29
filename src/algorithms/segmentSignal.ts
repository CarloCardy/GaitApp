const DEFAULT_TARGET_SAMPLES = 100;

export const segmentSignalWithIdx = (
  signal: number[],
  startIndices: number[],
  endIndices: number[],
  targetSamples = DEFAULT_TARGET_SAMPLES
): number[][] => {
  if (startIndices.length !== endIndices.length) {
    throw new Error(
      "Gli indici di inizio e fine non hanno la stessa lunghezza: ogni passo deve avere inizio e fine."
    );
  }

  return startIndices.map((start, index) => {
    const end = endIndices[index];

    if (start < 0 || end < 0 || start >= signal.length || end >= signal.length) {
      return [];
    }

    const segment = signal.slice(start, end + 1);

    if (segment.length < 2) {
      return [];
    }

    if (segment.length === targetSamples) {
      return segment;
    }

    const originalPoints = Array.from({ length: segment.length }, (_, i) => i + 1);
    const newPoints = Array.from({ length: targetSamples }, (_, i) => {
      return 1 + (i * (segment.length - 1)) / (targetSamples - 1);
    });

    return newPoints.map((point) => interpolateLinear(originalPoints, segment, point));
  });
};

const interpolateLinear = (xValues: number[], yValues: number[], x: number): number => {
  if (x <= xValues[0]) {
    return yValues[0];
  }
  if (x >= xValues[xValues.length - 1]) {
    return yValues[yValues.length - 1];
  }

  const index = xValues.findIndex((value) => value >= x);
  if (index <= 0) {
    return yValues[0];
  }

  const x0 = xValues[index - 1];
  const x1 = xValues[index];
  const y0 = yValues[index - 1];
  const y1 = yValues[index];
  const ratio = (x - x0) / (x1 - x0);

  return y0 + ratio * (y1 - y0);
};
