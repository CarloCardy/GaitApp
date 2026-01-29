import { BleManager, Device } from "react-native-ble-plx";
import { ImuDataSource, ImuSourceInfo, ImuStreamHandler } from "../ImuDataDao";
import { ImuSample, ImuStream } from "../../models/imu";

export type BluetoothImuConfig = {
  id?: string;
  name?: string;
  serviceUuid: string;
  characteristicUuid: string;
  placement?: ImuStream["metadata"]["placement"];
  sampleRateHz?: number;
};

export class BluetoothImuSource implements ImuDataSource {
  readonly info: ImuSourceInfo;
  private manager: BleManager;
  private device: Device | null = null;
  private streaming = false;
  private readonly serviceUuid: string;
  private readonly characteristicUuid: string;
  private readonly placement: ImuStream["metadata"]["placement"];
  private readonly sampleRateHz: number;

  constructor(config: BluetoothImuConfig) {
    this.info = {
      id: config.id ?? "bluetooth-imu",
      name: config.name ?? "IMU Bluetooth",
      type: "bluetooth",
    };
    this.manager = new BleManager();
    this.serviceUuid = config.serviceUuid;
    this.characteristicUuid = config.characteristicUuid;
    this.placement = config.placement ?? "unknown";
    this.sampleRateHz = config.sampleRateHz ?? 100;
  }

  async connect(): Promise<void> {
    const device = await this.scanForDevice();
    this.device = await device.connect();
    await this.device.discoverAllServicesAndCharacteristics();
  }

  async disconnect(): Promise<void> {
    this.streaming = false;
    if (this.device) {
      await this.device.cancelConnection();
    }
  }

  async startStreaming(onStream: ImuStreamHandler): Promise<void> {
    if (!this.device) {
      throw new Error("Dispositivo IMU non connesso");
    }

    this.streaming = true;
    const samples: ImuSample[] = [];

    await this.device.monitorCharacteristicForService(
      this.serviceUuid,
      this.characteristicUuid,
      (_error, characteristic) => {
        if (!this.streaming || !characteristic?.value) {
          return;
        }

        const parsed = decodeImuPayload(characteristic.value);
        if (parsed) {
          samples.push(parsed);
        }
      }
    );

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

  private async scanForDevice(): Promise<Device> {
    return new Promise((resolve, reject) => {
      const subscription = this.manager.startDeviceScan(null, null, (error, device) => {
        if (error) {
          subscription.remove();
          reject(error);
          return;
        }

        if (device?.serviceUUIDs?.includes(this.serviceUuid)) {
          subscription.remove();
          resolve(device);
        }
      });
    });
  }
}

const decodeImuPayload = (value: string): ImuSample | null => {
  const decoder = globalThis.atob;
  if (!decoder) {
    return null;
  }

  const decoded = decoder(value);
  const [timestamp, ax, ay, az, gx, gy, gz] = decoded.split(",").map((item) => Number(item));

  if ([timestamp, ax, ay, az, gx, gy, gz].some((item) => !Number.isFinite(item))) {
    return null;
  }

  return {
    timestamp,
    accelerometer: { x: ax, y: ay, z: az },
    gyroscope: { x: gx, y: gy, z: gz },
  };
};
