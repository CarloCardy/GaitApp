const path = require("path");
const { getDefaultConfig } = require("expo/metro-config");
const exclusionList = require("metro-config/src/defaults/exclusionList");

const escapeForRegex = (value) =>
  value.replace(/[|\\{}()[\]^$+*?.]/g, "\\$&");

const blockDir = (dirName) => {
  const absPath = path.resolve(__dirname, dirName).replace(/\\/g, "/");
  const escaped = escapeForRegex(absPath).replace(/\//g, "[\\\\/]");
  return new RegExp(`${escaped}[\\\\/].*`);
};

const config = getDefaultConfig(__dirname);

config.resolver.blockList = exclusionList([
  blockDir("Materiale Informativo"),
  blockDir("acquisizioni.2"),
  blockDir("Documenti algoritmo"),
  blockDir("Documenti di Riferimento"),
  blockDir("code"),
  blockDir("GaitApp"),
]);

module.exports = config;
