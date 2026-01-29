import { SegmentAngles } from "../models/imu";

type RotationOrder = "ZYX" | "XZY" | "XYZ" | "YXZ" | "YZX" | "ZXY";

type Matrix3x3 = [
  [number, number, number],
  [number, number, number],
  [number, number, number]
];

const RAD_TO_DEG = 180 / Math.PI;
const EPS = 0.99999;
const HALF_PI = Math.PI / 2;

const radToDeg = (value: number) => value * RAD_TO_DEG;

export const matToAngles = (matrices: Matrix3x3[], order: RotationOrder): SegmentAngles => {
  const roll: number[] = [];
  const pitch: number[] = [];
  const yaw: number[] = [];

  matrices.forEach((mat) => {
    const [[m11, m12, m13], [m21, m22, m23], [m31, m32, m33]] = mat;

    switch (order) {
      case "ZYX":
        if (Math.abs(m31) > EPS) {
          yaw.push(radToDeg(0));
          roll.push(radToDeg(Math.atan2(m23, m13)));
          pitch.push(radToDeg(HALF_PI * Math.sign(m31)));
        } else {
          roll.push(radToDeg(Math.atan2(m21, m11)));
          pitch.push(radToDeg(Math.asin(-m31)));
          yaw.push(radToDeg(Math.atan2(m32, m33)));
        }
        break;
      case "XZY":
        if (Math.abs(m12) > EPS) {
          yaw.push(radToDeg(Math.atan2(m31, m21)));
          roll.push(radToDeg(-HALF_PI * Math.sign(m12)));
          pitch.push(radToDeg(0));
        } else {
          pitch.push(radToDeg(Math.atan2(m13, m11)));
          yaw.push(radToDeg(Math.atan2(m32, m22)));
          roll.push(radToDeg(Math.asin(-m12)));
        }
        break;
      case "XYZ":
        if (Math.abs(m13) > EPS) {
          yaw.push(radToDeg(Math.atan2(m21, -m31)));
          roll.push(radToDeg(0));
          pitch.push(radToDeg(HALF_PI * Math.sign(m13)));
        } else {
          roll.push(radToDeg(Math.atan2(-m12, m11)));
          pitch.push(radToDeg(Math.asin(m13)));
          yaw.push(radToDeg(Math.atan2(-m23, m33)));
        }
        break;
      case "YXZ":
        if (Math.abs(m23) > EPS) {
          yaw.push(radToDeg(HALF_PI * Math.sign(m23)));
          roll.push(radToDeg(0));
          pitch.push(radToDeg(Math.atan2(m12, m32)));
        } else {
          roll.push(radToDeg(Math.atan2(m21, m22)));
          pitch.push(radToDeg(Math.atan2(m13, m33)));
          yaw.push(radToDeg(Math.asin(-m23)));
        }
        break;
      case "YZX":
        if (Math.abs(m21) > EPS) {
          yaw.push(radToDeg(0));
          roll.push(radToDeg(HALF_PI * Math.sign(m21)));
          pitch.push(radToDeg(Math.atan2(m13, -m12)));
        } else {
          roll.push(radToDeg(Math.asin(m21)));
          pitch.push(radToDeg(Math.atan2(-m31, m11)));
          yaw.push(radToDeg(Math.atan2(-m23, m22)));
        }
        break;
      case "ZXY":
        if (Math.abs(m32) > EPS) {
          pitch.push(radToDeg(0));
          roll.push(radToDeg(Math.atan2(m13, -m23)));
          yaw.push(radToDeg(HALF_PI * Math.sign(m32)));
        } else {
          roll.push(radToDeg(Math.atan2(-m12, m22)));
          pitch.push(radToDeg(Math.atan2(-m31, m33)));
          yaw.push(radToDeg(Math.asin(m32)));
        }
        break;
    }
  });

  return {
    roll,
    pitch,
    yaw,
  };
};

export type { Matrix3x3, RotationOrder };
