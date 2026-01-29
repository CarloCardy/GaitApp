import { useMemo, useState } from "react";
import {
  Modal,
  NativeModules,
  Platform,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  useWindowDimensions,
  View,
} from "react-native";
import * as DocumentPicker from "expo-document-picker";
import * as FileSystem from "expo-file-system";
import Svg, { G, Line, Path, Rect, Text as SvgText } from "react-native-svg";
import { ImuDataDao } from "./src/data/ImuDataDao";
import { TxtImuSource } from "./src/data/sources/TxtImuSource";
import { buildTriplet, parseXsensTxt, processTriplet } from "./src/processing/xsensTriplet";
import type { EventMarker, GaitPhase, XsensTripletResult } from "./src/processing/xsensTriplet";
import type { ImuDataSource } from "./src/data/ImuDataDao";

export default function App() {
  const [selectedSourceId, setSelectedSourceId] = useState<string | null>(null);
  const [status, setStatus] = useState("Pronto");
  const [lastRun, setLastRun] = useState<string | null>(null);
  const [txtModalOpen, setTxtModalOpen] = useState(false);
  const [txtFileName, setTxtFileName] = useState<string | null>(null);
  const [txtFileNames, setTxtFileNames] = useState<string[]>([]);
  const [txtError, setTxtError] = useState<string | null>(null);
  const [txtTriplet, setTxtTriplet] = useState<ReturnType<typeof buildTriplet> | null>(null);
  const [analysisResult, setAnalysisResult] = useState<XsensTripletResult | null>(null);
  const [showResults, setShowResults] = useState(false);
  const { width: windowWidth } = useWindowDimensions();

  const bleAvailable = Platform.OS !== "web" && Boolean(NativeModules.BlePlx);

  const { dao, txtSource } = useMemo(() => {
    const txtSourceInstance = new TxtImuSource();
    const sources: ImuDataSource[] = [txtSourceInstance];

    if (bleAvailable) {
      const { BluetoothImuSource } =
        require("./src/data/sources/BluetoothImuSource") as typeof import("./src/data/sources/BluetoothImuSource");
      sources.push(
        new BluetoothImuSource({
          serviceUuid: "0000180f-0000-1000-8000-00805f9b34fb",
          characteristicUuid: "00002a19-0000-1000-8000-00805f9b34fb",
        })
      );
    }

    return { dao: new ImuDataDao(sources), txtSource: txtSourceInstance };
  }, [bleAvailable]);

  const sources = dao.listSources();

  const handlePickTxt = async () => {
    setTxtError(null);
    const result = await DocumentPicker.getDocumentAsync({
      type: ["text/plain", "text/csv", "text/*"],
      copyToCacheDirectory: true,
      multiple: true,
    });

    if (result.canceled || result.assets.length === 0) {
      return;
    }

    if (result.assets.length !== 3) {
      setTxtError("Seleziona esattamente 3 file TXT (uno per sensore).");
      return;
    }

    try {
      const parsedFiles = [];
      for (const asset of result.assets) {
        let content = "";
        if (Platform.OS === "web") {
          const response = await fetch(asset.uri);
          content = await response.text();
        } else {
          content = await FileSystem.readAsStringAsync(asset.uri);
        }
        parsedFiles.push(parseXsensTxt(content, asset.name ?? undefined));
      }

      const baseName = parsedFiles[0].baseName;
      if (!parsedFiles.every((file) => file.baseName === baseName)) {
        throw new Error("I file selezionati non appartengono allo stesso trial.");
      }

      const triplet = buildTriplet(parsedFiles);
      setTxtTriplet(triplet);
      setTxtFileNames(result.assets.map((asset) => asset.name ?? "file.txt"));
      setTxtFileName(baseName);
      txtSource.updateContent("timestamp,ax,ay,az,gx,gy,gz\n0,0,0,0,0,0,0");
      setTxtModalOpen(false);
      setStatus("File TXT caricato.");
    } catch (error) {
      setTxtTriplet(null);
      setTxtError(
        error instanceof Error
          ? error.message
          : "Impossibile leggere il file. Verifica il formato TXT/CSV."
      );
    }
  };

  const handleAcquire = async () => {
    const source = selectedSourceId ? dao.getSource(selectedSourceId) : undefined;
    if (!source) {
      setStatus("Seleziona una sorgente IMU");
      return;
    }

    setStatus("Connessione in corso...");
    await source.connect();

    setStatus("Acquisizione dati...");
    await source.startStreaming((stream) => {
      setStatus(`Ricevuti ${stream.samples.length} campioni da ${stream.metadata.sensorId}`);
    });
  };

  const handleAnalyze = () => {
    if (!txtTriplet) {
      setLastRun("Carica 3 file TXT dello stesso trial prima di analizzare.");
      return;
    }
    try {
      const result = processTriplet(txtTriplet, "ZXY");
      setAnalysisResult(result);
      setShowResults(true);
      setLastRun(
        `Triplet ${result.baseName}: segmenti ${result.segments.hip.length}, picchi hip ${result.peaks.hip.initialContact.length}`
      );
    } catch (error) {
      setLastRun(
        error instanceof Error
          ? `Errore analisi: ${error.message}`
          : "Errore durante l'analisi del triplet."
      );
    }
  };

  if (showResults && analysisResult) {
    return (
      <SafeAreaView style={styles.safeArea}>
        <ScrollView contentContainerStyle={styles.container}>
          <View style={styles.headerRow}>
            <Text style={styles.title}>Risultati MATLAB → React</Text>
            <TouchableOpacity
              style={styles.secondaryButton}
              onPress={() => setShowResults(false)}
            >
              <Text style={styles.secondaryButtonText}>Indietro</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Numero di passi (heel strike → heel strike)</Text>
            <Text style={styles.status}>{analysisResult.steps.count}</Text>
          </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Stance / Swing per passo</Text>
          {analysisResult.steps.stancePercent.map((stance, index) => (
            <Text key={`step-${index}`} style={styles.status}>
              Passo {index + 1}: Stance {stance.toFixed(1)}% · Swing{" "}
              {analysisResult.steps.swingPercent[index].toFixed(1)}%
            </Text>
          ))}
          <StanceSwingBar
            stance={analysisResult.steps.stanceMean}
            swing={analysisResult.steps.swingMean}
            stanceRange={{ min: 60, max: 62 }}
            swingRange={{ min: 40, max: 42 }}
          />
        </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Caviglia - flesso estensione</Text>
            <LineChart
              width={Math.min(windowWidth - 48, 420)}
              height={220}
              curves={analysisResult.segments.ankle}
              meanCurve={analysisResult.segments.ankleMean}
              stancePercent={analysisResult.steps.stanceMean}
              phases={analysisResult.phases}
              events={analysisResult.meanEvents.ankle}
            />
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Ginocchio - flesso estensione</Text>
            <LineChart
              width={Math.min(windowWidth - 48, 420)}
              height={220}
              curves={analysisResult.segments.knee}
              meanCurve={analysisResult.segments.kneeMean}
              stancePercent={analysisResult.steps.stanceMean}
              phases={analysisResult.phases}
              events={analysisResult.meanEvents.knee}
            />
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Anca - flesso estensione</Text>
            <LineChart
              width={Math.min(windowWidth - 48, 420)}
              height={220}
              curves={analysisResult.segments.hip}
              meanCurve={analysisResult.segments.hipMean}
              stancePercent={analysisResult.steps.stanceMean}
              phases={analysisResult.phases}
              events={analysisResult.meanEvents.hip}
            />
          </View>
        </ScrollView>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <ScrollView contentContainerStyle={styles.container}>
        <Text style={styles.title}>Gait IMU Lab</Text>
        <Text style={styles.subtitle}>
          Acquisizione dati da sensori IMU, segmentazione e calcolo parametri di gait analysis.
        </Text>
        {Platform.OS === "web" ? (
          <Text style={styles.helperText}>
            Nota: su Web è disponibile solo la simulazione TXT. Il Bluetooth richiede Android/iOS.
          </Text>
        ) : null}
        {Platform.OS !== "web" && !bleAvailable ? (
          <Text style={styles.helperText}>
            Bluetooth non disponibile in Expo Go/Simulator. Serve una development build con il modulo BLE.
          </Text>
        ) : null}

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>1. Seleziona la sorgente dati</Text>
          <View style={styles.sourceList}>
            {sources.map((source) => (
              <TouchableOpacity
                key={source.id}
                style={[
                  styles.sourceCard,
                  selectedSourceId === source.id && styles.sourceCardSelected,
                ]}
                onPress={() => {
                  setSelectedSourceId(source.id);
                  if (source.type === "txt") {
                    setTxtModalOpen(true);
                  }
                }}
              >
                <Text style={styles.sourceTitle}>{source.name}</Text>
                <Text style={styles.sourceMeta}>{source.type.toUpperCase()}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>2. Avvia acquisizione</Text>
          <TouchableOpacity style={styles.primaryButton} onPress={handleAcquire}>
            <Text style={styles.primaryButtonText}>Acquisisci dati</Text>
          </TouchableOpacity>
          <Text style={styles.status}>{status}</Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>3. Analisi e report</Text>
          <TouchableOpacity style={styles.secondaryButton} onPress={handleAnalyze}>
            <Text style={styles.secondaryButtonText}>Esegui pipeline MATLAB → React</Text>
          </TouchableOpacity>
          {lastRun ? <Text style={styles.status}>{lastRun}</Text> : null}
        </View>
      </ScrollView>
      <Modal
        visible={txtModalOpen}
        transparent
        animationType="fade"
        onRequestClose={() => setTxtModalOpen(false)}
      >
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Seleziona file TXT/CSV</Text>
            <Text style={styles.modalSubtitle}>
              Seleziona 3 file TXT del medesimo trial (foot, tibia, hip).
            </Text>
            {txtFileName ? <Text style={styles.modalFileName}>File: {txtFileName}</Text> : null}
            {txtFileNames.length > 0 ? (
              <Text style={styles.modalFileName}>Selezionati: {txtFileNames.join(", ")}</Text>
            ) : null}
            {txtError ? <Text style={styles.modalError}>{txtError}</Text> : null}
            <TouchableOpacity style={styles.primaryButton} onPress={handlePickTxt}>
              <Text style={styles.primaryButtonText}>Scegli file</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.modalClose} onPress={() => setTxtModalOpen(false)}>
              <Text style={styles.modalCloseText}>Chiudi</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

type LineChartProps = {
  width: number;
  height: number;
  curves: number[][];
  meanCurve: number[];
  stancePercent?: number;
  phases?: GaitPhase[];
  events?: EventMarker[];
};

const LineChart = ({
  width,
  height,
  curves,
  meanCurve,
  stancePercent,
  phases = [],
  events = [],
}: LineChartProps) => {
  if (curves.length === 0 || meanCurve.length === 0) {
    return <Text style={styles.status}>Nessun dato disponibile.</Text>;
  }

  const allValues = curves.flat().concat(meanCurve);
  const minY = Math.min(...allValues);
  const maxY = Math.max(...allValues);
  const padding = 12;
  const stanceCut = Math.min(100, Math.max(0, stancePercent ?? 60));

  const normalizeY = (value: number) => {
    if (maxY === minY) {
      return height / 2;
    }
    return padding + ((maxY - value) / (maxY - minY)) * (height - padding * 2);
  };

  const toPath = (series: number[]) => {
    const stepX = (width - padding * 2) / (series.length - 1);
    return series
      .map((value, index) => {
        const x = padding + stepX * index;
        const y = normalizeY(value);
        return `${index === 0 ? "M" : "L"}${x},${y}`;
      })
      .join(" ");
  };

  const stepX = (width - padding * 2) / (meanCurve.length - 1);
  const phaseLabelY = height - 6;
  const eventLabelOffset = 10;

  const labelForEvent = (label: string) => {
    const map: Record<string, string> = {
      initialContact: "IC",
      loadingResponse: "LR",
      midTerminalStance: "MTS",
      terminalStance: "TS",
      preSwing: "PS",
      initialSwing: "ISw",
      terminalSwing: "TSw",
      swing: "Sw",
    };
    return map[label] ?? label;
  };

  return (
    <View style={{ width, height }}>
      <Svg width={width} height={height}>
        <Rect
          x={padding}
          y={padding}
          width={((width - padding * 2) * stanceCut) / 100}
          height={height - padding * 2}
          fill="#f0f2ff"
        />
        <Rect
          x={padding + ((width - padding * 2) * stanceCut) / 100}
          y={padding}
          width={(width - padding * 2) * (1 - stanceCut / 100)}
          height={height - padding * 2}
          fill="#fff4f0"
        />
        <Line
          x1={padding}
          x2={width - padding}
          y1={normalizeY(0)}
          y2={normalizeY(0)}
          stroke="#9aa4c7"
          strokeWidth={1}
          strokeDasharray="4 4"
        />
        <Line
          x1={padding + ((width - padding * 2) * stanceCut) / 100}
          x2={padding + ((width - padding * 2) * stanceCut) / 100}
          y1={padding}
          y2={height - padding}
          stroke="#9aa4c7"
          strokeWidth={1}
          strokeDasharray="4 4"
        />
        {phases
          .filter((phase) => phase.start > 0)
          .map((phase) => {
            const x = padding + ((width - padding * 2) * phase.start) / 100;
            return (
              <Line
                key={`phase-${phase.label}`}
                x1={x}
                x2={x}
                y1={padding}
                y2={height - padding}
                stroke="#d1d6ea"
                strokeWidth={1}
              />
            );
          })}
        {curves.map((curve, index) => (
          <Path
            key={`curve-${index}`}
            d={toPath(curve)}
            stroke="#b8c2ff"
            strokeWidth={1}
            fill="none"
          />
        ))}
        <Path d={toPath(meanCurve)} stroke="#2743ff" strokeWidth={2} fill="none" />
        {events.map((event, index) => {
          const x = padding + stepX * event.index;
          const y = normalizeY(event.value);
          return (
            <G key={`event-${index}`}>
              <Line
                x1={x}
                x2={x}
                y1={y}
                y2={height - padding}
                stroke="#7b86b2"
                strokeWidth={0.8}
                strokeDasharray="2 3"
              />
              <Path
                d={`M${x - 2},${y} L${x},${y - 2} L${x + 2},${y} L${x},${y + 2} Z`}
                fill={event.type === "max" ? "#2743ff" : "#d24b4b"}
              />
              <SvgText
                x={x + 4}
                y={Math.max(padding + 8, y - eventLabelOffset)}
                fontSize="9"
                fill="#42435a"
              >
                {labelForEvent(event.label)} {event.value.toFixed(1)}°
              </SvgText>
            </G>
          );
        })}
        {phases.map((phase) => {
          const mid = (phase.start + phase.end) / 2;
          const x = padding + ((width - padding * 2) * mid) / 100;
          return (
            <SvgText
              key={`phase-label-${phase.label}`}
              x={x - 8}
              y={phaseLabelY}
              fontSize="9"
              fill="#6b6b85"
            >
              {phase.label}
            </SvgText>
          );
        })}
        <SvgText x={padding} y={padding - 2} fontSize="10" fill="#6b6b85">
          Flessione (+)
        </SvgText>
        <SvgText x={padding} y={height - 2} fontSize="10" fill="#6b6b85">
          Estensione (-)
        </SvgText>
        <SvgText x={padding} y={height - 6} fontSize="10" fill="#6b6b85">
          0%
        </SvgText>
        <SvgText x={width - padding - 16} y={height - 6} fontSize="10" fill="#6b6b85">
          100%
        </SvgText>
        <SvgText
          x={padding + ((width - padding * 2) * stanceCut) / 2 - 18}
          y={padding + 12}
          fontSize="10"
          fill="#6b6b85"
        >
          Stance
        </SvgText>
        <SvgText
          x={padding + ((width - padding * 2) * (stanceCut / 100)) + 8}
          y={padding + 12}
          fontSize="10"
          fill="#6b6b85"
        >
          Swing
        </SvgText>
      </Svg>
    </View>
  );
};

type StanceSwingBarProps = {
  stance: number;
  swing: number;
  stanceRange: { min: number; max: number };
  swingRange: { min: number; max: number };
};

const StanceSwingBar = ({
  stance,
  swing,
  stanceRange,
  swingRange,
}: StanceSwingBarProps) => {
  const totalWidth = 280;
  const stanceWidth = Math.min(100, Math.max(0, stance));
  const swingWidth = Math.min(100, Math.max(0, swing));
  const stancePx = (stanceWidth / 100) * totalWidth;
  const swingPx = (swingWidth / 100) * totalWidth;
  const stanceMinX = (stanceRange.min / 100) * totalWidth;
  const stanceMaxX = (stanceRange.max / 100) * totalWidth;
  const swingMinX = totalWidth - (swingRange.max / 100) * totalWidth;
  const swingMaxX = totalWidth - (swingRange.min / 100) * totalWidth;

  return (
    <View style={[styles.stanceBar, { width: totalWidth }]}>
      <View style={[styles.stanceFill, { width: stancePx }]} />
      <View style={[styles.swingFill, { width: swingPx }]} />
      <View style={[styles.rangeMarker, { left: stanceMinX }]} />
      <View style={[styles.rangeMarker, { left: stanceMaxX }]} />
      <View style={[styles.rangeMarker, { left: swingMinX }]} />
      <View style={[styles.rangeMarker, { left: swingMaxX }]} />
      <Text style={styles.stanceBarText}>
        Stance {stance.toFixed(1)}% · Swing {swing.toFixed(1)}%
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: "#f7f7fb",
  },
  container: {
    padding: 24,
    gap: 24,
  },
  title: {
    fontSize: 28,
    fontWeight: "700",
    color: "#1d1d2f",
  },
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 12,
  },
  subtitle: {
    fontSize: 14,
    color: "#5a5a7a",
  },
  helperText: {
    fontSize: 12,
    color: "#7a7a9a",
  },
  section: {
    padding: 16,
    backgroundColor: "#ffffff",
    borderRadius: 16,
    shadowColor: "#1d1d2f",
    shadowOpacity: 0.1,
    shadowRadius: 12,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 12,
    color: "#2a2a3a",
  },
  sourceList: {
    flexDirection: "row",
    gap: 12,
  },
  sourceCard: {
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#d6d6e7",
    backgroundColor: "#fafafe",
    flex: 1,
  },
  sourceCardSelected: {
    borderColor: "#4c6fff",
    backgroundColor: "#eef1ff",
  },
  sourceTitle: {
    fontWeight: "600",
    color: "#2b2b3f",
  },
  sourceMeta: {
    marginTop: 4,
    fontSize: 12,
    color: "#6b6b85",
  },
  primaryButton: {
    backgroundColor: "#4c6fff",
    borderRadius: 12,
    paddingVertical: 12,
    alignItems: "center",
  },
  primaryButtonText: {
    color: "#ffffff",
    fontWeight: "600",
  },
  secondaryButton: {
    borderWidth: 1,
    borderColor: "#4c6fff",
    borderRadius: 12,
    paddingVertical: 12,
    alignItems: "center",
  },
  secondaryButtonText: {
    color: "#4c6fff",
    fontWeight: "600",
  },
  status: {
    marginTop: 12,
    fontSize: 13,
    color: "#4b4b67",
  },
  stanceBar: {
    marginTop: 12,
    height: 28,
    borderRadius: 14,
    overflow: "hidden",
    backgroundColor: "#eef0f6",
    justifyContent: "center",
  },
  stanceFill: {
    position: "absolute",
    left: 0,
    top: 0,
    bottom: 0,
    backgroundColor: "#c9d3ff",
  },
  swingFill: {
    position: "absolute",
    right: 0,
    top: 0,
    bottom: 0,
    backgroundColor: "#ffd9c6",
  },
  rangeMarker: {
    position: "absolute",
    top: 4,
    bottom: 4,
    width: 2,
    backgroundColor: "#6b6b85",
    opacity: 0.6,
  },
  stanceBarText: {
    textAlign: "center",
    fontSize: 12,
    color: "#303046",
    fontWeight: "600",
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: "rgba(19, 19, 32, 0.6)",
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
  },
  modalCard: {
    backgroundColor: "#ffffff",
    borderRadius: 16,
    padding: 20,
    gap: 12,
    width: "100%",
    maxWidth: 420,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: "700",
    color: "#1d1d2f",
  },
  modalSubtitle: {
    fontSize: 13,
    color: "#5a5a7a",
  },
  modalFileName: {
    fontSize: 13,
    color: "#2b2b3f",
  },
  modalError: {
    fontSize: 12,
    color: "#c23b3b",
  },
  modalClose: {
    alignItems: "center",
    paddingVertical: 8,
  },
  modalCloseText: {
    color: "#4b4b67",
    fontWeight: "600",
  },
});
