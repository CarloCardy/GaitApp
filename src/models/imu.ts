export type Vector3 = {
  x: number;
  y: number;
  z: number;
};

export type ImuSample = {
  timestamp: number;
  accelerometer: Vector3;
  gyroscope: Vector3;
  magnetometer?: Vector3;
  quaternion?: [number, number, number, number];
};

export type ImuStreamMetadata = {
  sampleRateHz: number;
  sensorId: string;
  placement: "foot" | "shank" | "thigh" | "pelvis" | "unknown";
};

export type ImuStream = {
  metadata: ImuStreamMetadata;
  samples: ImuSample[];
};

export type SegmentAngles = {
  roll: number[];
  pitch: number[];
  yaw: number[];
};

export type GaitPeaks = {
  hip: Record<string, number[]>;
  knee: Record<string, number[]>;
  ankle: Record<string, number[]>;
};
