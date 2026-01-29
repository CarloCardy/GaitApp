import { ImuStream } from "../models/imu";

export type ImuSourceType = "txt" | "bluetooth";

export type ImuSourceInfo = {
  id: string;
  name: string;
  type: ImuSourceType;
};

export type ImuStreamHandler = (stream: ImuStream) => void;

export interface ImuDataSource {
  readonly info: ImuSourceInfo;
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  startStreaming(onStream: ImuStreamHandler): Promise<void>;
  stopStreaming(): Promise<void>;
}

export class ImuDataDao {
  private sources: ImuDataSource[];

  constructor(sources: ImuDataSource[]) {
    this.sources = sources;
  }

  listSources(): ImuSourceInfo[] {
    return this.sources.map((source) => source.info);
  }

  getSource(id: string): ImuDataSource | undefined {
    return this.sources.find((source) => source.info.id === id);
  }
}
