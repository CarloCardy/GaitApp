import { matToAngles, Matrix3x3, RotationOrder } from "../algorithms/mat2ang";
import { extractGaitPeaks } from "../algorithms/gaitPeaks";
import { segmentSignalWithIdx } from "../algorithms/segmentSignal";
import { GaitPeaks, SegmentAngles } from "../models/imu";

export type SegmentationIndices = {
  start: number[];
  end: number[];
};

export type GaitProcessingResult = {
  angles: SegmentAngles;
  segmented: {
    hip: number[][];
    knee: number[][];
    ankle: number[][];
  };
  peaks: GaitPeaks;
  peakSummary: ReturnType<typeof extractGaitPeaks>["summary"];
};

export class GaitProcessingPipeline {
  private rotationOrder: RotationOrder;

  constructor(rotationOrder: RotationOrder = "ZYX") {
    this.rotationOrder = rotationOrder;
  }

  computeAngles(matrices: Matrix3x3[]): SegmentAngles {
    return matToAngles(matrices, this.rotationOrder);
  }

  segmentSignals(
    hip: number[],
    knee: number[],
    ankle: number[],
    indices: SegmentationIndices
  ) {
    return {
      hip: segmentSignalWithIdx(hip, indices.start, indices.end),
      knee: segmentSignalWithIdx(knee, indices.start, indices.end),
      ankle: segmentSignalWithIdx(ankle, indices.start, indices.end),
    };
  }

  extractPeaks(segmented: { hip: number[][]; knee: number[][]; ankle: number[][] }) {
    return extractGaitPeaks(segmented.hip, segmented.knee, segmented.ankle);
  }

  run(
    matrices: Matrix3x3[],
    hip: number[],
    knee: number[],
    ankle: number[],
    indices: SegmentationIndices
  ): GaitProcessingResult {
    const angles = this.computeAngles(matrices);
    const segmented = this.segmentSignals(hip, knee, ankle, indices);
    const { peaks, summary } = this.extractPeaks(segmented);

    return {
      angles,
      segmented,
      peaks,
      peakSummary: summary,
    };
  }
}
