import { ImuDataSource, ImuSourceInfo, ImuStreamHandler } from "../ImuDataDao";
import { ImuSample, ImuStream } from "../../models/imu";

export type TxtImuConfig = {
  id?: string;
  name?: string;
  sampleRateHz?: number;
  placement?: ImuStream["metadata"]["placement"];
  content?: string;
};

const DEFAULT_CONTENT = `timestamp,ax,ay,az,gx,gy,gz
0,0.01,0.03,0.98,0.1,0.2,0.15
10,0.02,0.04,0.97,0.12,0.18,0.13
20,0.03,0.05,0.99,0.11,0.19,0.17`;

export class TxtImuSource implements ImuDataSource {
  readonly info: ImuSourceInfo;
  private content: string;
  private streaming = false;
  private readonly sampleRateHz: number;
  private readonly placement: ImuStream["metadata"]["placement"];

  constructor(config: TxtImuConfig = {}) {
    this.info = {
      id: config.id ?? "txt-local",
      name: config.name ?? "Simulazione TXT",
      type: "txt",
    };
    this.content = config.content ?? DEFAULT_CONTENT;
    this.sampleRateHz = config.sampleRateHz ?? 100;
    this.placement = config.placement ?? "unknown";
  }

  async connect(): Promise<void> {
    return;
  }

  async disconnect(): Promise<void> {
    this.streaming = false;
  }

  async startStreaming(onStream: ImuStreamHandler): Promise<void> {
    this.streaming = true;
    const samples = parseTxtContent(this.content);
    if (!this.streaming) {
      return;
    }

    const stream: ImuStream = {
      metadata: {
        sampleRateHz: this.sampleRateHz,
        sensorId: this.info.id,
        placement: this.placement,
      },
      samples,
    };

    onStream(stream);
  }

  async stopStreaming(): Promise<void> {
    this.streaming = false;
  }

  updateContent(content: string) {
    this.content = content;
  }
}

export const parseTxtContent = (content: string): ImuSample[] => {
  const lines = content
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0);

  if (lines.length === 0) {
    return [];
  }

  const headerIndex = lines.findIndex(
    (line) => line.includes("PacketCounter") && line.includes("Mat[1][1]")
  );
  if (headerIndex !== -1) {
    const dataLines = lines.slice(headerIndex + 1);
    return dataLines
      .map((line) => line.split(/\t+/).map((value) => Number(value)))
      .filter((values) => values.length >= 7 && values.every((value) => Number.isFinite(value)))
      .map(([timestamp, ax, ay, az, gx, gy, gz]) => ({
        timestamp,
        accelerometer: { x: ax, y: ay, z: az },
        gyroscope: { x: gx, y: gy, z: gz },
      }));
  }

  const header = lines[0].toLowerCase();
  const hasHeader = header.includes("timestamp") && header.includes("ax");
  const dataLines = hasHeader ? lines.slice(1) : lines;

  return dataLines
    .map((line) => line.split(",").map((value) => Number(value)))
    .filter((values) => values.length >= 7 && values.every((value) => Number.isFinite(value)))
    .map(([timestamp, ax, ay, az, gx, gy, gz]) => ({
      timestamp,
      accelerometer: { x: ax, y: ay, z: az },
      gyroscope: { x: gx, y: gy, z: gz },
    }));
};
