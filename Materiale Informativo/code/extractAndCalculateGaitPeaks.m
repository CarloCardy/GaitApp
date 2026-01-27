function [peak_data_struct, table_peaks] = extractAndCalculateGaitPeaks(segmento_foot, segmento_hip, segmento_knee, segmento_ankle)
% l'output della funzione sarà una struttura contenente tutti i valori dei
% picchi dei segnali e la loro posizione ed una tabella contenente media e
% std 

%definisco dei vettrori vuoti che conterranno i valori dei picchi
%ANCA
pks_max_hip_initialcontact = [];
locs_pks_max_hip_initialcontact = [];
% corrisponde alla Flessione dell'anca (20-30°) durante il contatto
% iniziale 0-10% del ciclo del passo

pks_max_hip_terminalswing = [];
locs_pks_max_hip_terminalswing = [];
% corrisponde alla Flessione MAX dell'anca (40°) durante la fase di swing
% per preparare il contatto successivo del piede a terra 85-100% del ciclo

pks_min_hip_terminalstance = [];
locs_pks_min_hip_terminalstance = [];
% é unico e corrisponde all'ESTENSIONE (15-20°) e si verifica nella fase 
% di terminal stance piú precisamente tra il 40-50% del ciclo del passo

%GINOCCHIO
pks_max_knee_loadingresponse = [];
locs_pks_max_knee_loadingresponse = [];
%corrisponde alla flessione del ginocchio (15-20/25°) e si verifica nella
%fase di risposta al carico dopo l'heel contact intorno al 10% del ciclo
%del passo

pks_max_knee_initialswing = [];
locs_pks_max_knee_initialswing = [];
%corrisponde alla felssione piú marcata dell'articolazione (60-65/70°), in
%genere avviene tra il 60-70% del ciclo del passo, ma bisogna considerare
%un intervallo piú ampio

pks_min_knee_initialcontact = [];
locs_pks_min_knee_initialcontact = [];
% corrisponde all'estensione del ginocchio (0° circa) all'initial contact
% 0-10% del ciclo del passo

pks_min_knee_midterminalstance = [];
locs_pks_min_knee_midterminalstance = [];
% corrisponde all'unica estensione del ginocchio (0-5°) durante il ciclo
% tra 30-40% del ciclo del passo

%CAVIGLIA
pks_max_ankle_midterminalstance = [];
locs_pks_max_ankle_midterminalstance = [];
% é la prima dorsiflessione della caviglia (5-10/15°) e si aggira tra i
% 12-48% del ciclo del passo

pks_max_ankle_swing = [];
locs_pks_max_ankle_swing = [];
% é la seconda dorsiflessione (0-5°) e si verifica durane la fase di swing
% 60-100% del ciclo del passo

pks_min_ankle_loadingresponse = [];
locs_pks_min_ankle_loadingresponse = [];
% é la prima flessione plantare (5-10°) e si verfica attorno al 10% del
% ciclo del passo 

pks_min_ankle_preswing = [];
locs_pks_min_ankle_preswing = [];
% é la seconda flessione plantare (20-30°) e si verfica attorno al 60% del
% ciclo del passo

% vado ad individuare i pichhi per ogni segmento del segnale (ovvero in
% ogni passo, per ogni angolo di interesse 
for i = 1:length(segmento_foot)
    %posso usare anche segmento_hip o segmento_knee, perchè ho già trovato
    %e valutato che sono uguali in numero

    current_hip_segment = segmento_hip{i};
    current_knee_segment = segmento_knee{i};
    current_ankle_segment = segmento_ankle{i};
    %devo richiamarli tutti perché cerco i picchi in punti diversi

    %ANCA
    [pks_hip_all_max, locs_hip_all_max] = findpeaks(current_hip_segment);
    [pks_hip_all_min, locs_hip_all_min] = findpeaks(-current_hip_segment);
    pks_hip_all_min = -pks_hip_all_min;
    %trovo tutti i picchi positivi e negativi e relative posizioni con
    %findpeaks, per i picchi negativi rendo negativo il segnale quindi devo
    %ricordarmi di girarlo 
   
    % Filtro e salvo i picchi dell'anca in base alle posizioni del campione (indici %)

% Picco di flessione anca (20-30°) - Initial Contact (0-10% del ciclo) -> Campioni 1-10
    idx = find(locs_hip_all_max >= 1 & locs_hip_all_max <= 15);
    % uso una variabile che si aggiornerá a seconda dei range di indici %
    % che mi serviranno per trovare i picchi di interesse 
    if ~isempty(idx)
        [val, pos] = max(pks_hip_all_max(idx));
        % a questo punto trovo e successivamente salvo valore e posizione 
        % del picco massimo nell'intervallo
        pks_max_hip_initialcontact = [pks_max_hip_initialcontact; val];
        locs_pks_max_hip_initialcontact = [locs_pks_max_hip_initialcontact; locs_hip_all_max(idx(pos))];
    end

% Picco di flessione anca MAX (circa 40°) - Terminal Swing (85-100% del ciclo) -> Campioni 85-100
    idx = find(locs_hip_all_max >= 70 & locs_hip_all_max <= 100);
    if ~isempty(idx)
        [val, pos] = max(pks_hip_all_max(idx));
        pks_max_hip_terminalswing = [pks_max_hip_terminalswing; val];
        locs_pks_max_hip_terminalswing = [locs_pks_max_hip_terminalswing; locs_hip_all_max(idx(pos))];
    end

% Picco di estensione anca (15-20°) - Terminal Stance (40-50% del ciclo) -> Campioni 40-50
    idx = find(locs_hip_all_min >= 30 & locs_hip_all_min <= 80);
    if ~isempty(idx)
        [val, pos] = min(pks_hip_all_min(idx));
        pks_min_hip_terminalstance = [pks_min_hip_terminalstance; val];
        locs_pks_min_hip_terminalstance = [locs_pks_min_hip_terminalstance; locs_hip_all_min(idx(pos))];
    end

    %Elaborazione GINOCCHIO
    [pks_knee_all_max, locs_knee_all_max] = findpeaks(current_knee_segment);
    [pks_knee_all_min, locs_knee_all_min] = findpeaks(-current_knee_segment);
    pks_knee_all_min = -pks_knee_all_min;

% Picco di flessione ginocchio (15-20/25°) - Loading Response (10% del ciclo)
    idx = find(locs_knee_all_max >= 5 & locs_knee_all_max <= 20); % Esteso per flessibilità
    if ~isempty(idx)
        [val, pos] = max(pks_knee_all_max(idx));
        pks_max_knee_loadingresponse = [pks_max_knee_loadingresponse; val];
        locs_pks_max_knee_loadingresponse = [locs_pks_max_knee_loadingresponse; locs_knee_all_max(idx(pos))];
    end

% Picco di flessione ginocchio MAX (60-65/70°) - Pre-Swing/Initial Swing (60-70% del ciclo) -> Campioni 55-75
    idx = find(locs_knee_all_max >= 55 & locs_knee_all_max <= 90);
    if ~isempty(idx)
        [val, pos] = max(pks_knee_all_max(idx));
        pks_max_knee_initialswing = [pks_max_knee_initialswing; val];
        locs_pks_max_knee_initialswing = [locs_pks_max_knee_initialswing; locs_knee_all_max(idx(pos))];
    end

% Picco di estensione ginocchio (0° circa) - Initial Contact (0-10% del ciclo) -> Campioni 1-10
    idx = find(locs_knee_all_min >= 1 & locs_knee_all_min <= 10);
    if ~isempty(idx)
        [~, pos] = min(abs(pks_knee_all_min(idx))); % Trova l'indice del valore più vicino a 0
        pks_min_knee_initialcontact = [pks_min_knee_initialcontact; pks_knee_all_min(idx(pos))];
        locs_pks_min_knee_initialcontact = [locs_pks_min_knee_initialcontact; locs_knee_all_min(idx(pos))];
    end

% Picco di estensione ginocchio (0-5°) - Mid-Terminal Stance (30-40% del ciclo) -> Campioni 30-40
    idx = find(locs_knee_all_min >= 30 & locs_knee_all_min <= 50);
    if ~isempty(idx)
        [~, pos] = min(abs(pks_knee_all_min(idx)));
        pks_min_knee_midterminalstance = [pks_min_knee_midterminalstance; pks_knee_all_min(idx(pos))];
        locs_pks_min_knee_midterminalstance = [locs_pks_min_knee_midterminalstance; locs_knee_all_min(idx(pos))];
    end

    % CAVIGLIA
    [pks_ankle_all_max, locs_ankle_all_max] = findpeaks(current_ankle_segment);
    [pks_ankle_all_min, locs_ankle_all_min] = findpeaks(-current_ankle_segment);
    pks_ankle_all_min = -pks_ankle_all_min;

% Picco di dorsiflessione caviglia (5-10/15°) - Mid-Terminal Stance (12-48% del ciclo) -> Campioni 12-48
    idx = find(locs_ankle_all_max >= 5 & locs_ankle_all_max <= 70);
    if ~isempty(idx)
        [val, pos] = max(pks_ankle_all_max(idx));
        pks_max_ankle_midterminalstance = [pks_max_ankle_midterminalstance; val];
        locs_pks_max_ankle_midterminalstance = [locs_pks_max_ankle_midterminalstance; locs_ankle_all_max(idx(pos))];
    end

% Picco di dorsiflessione caviglia (0-5°) - Swing (60-100% del ciclo) -> Campioni 60-100
    idx = find(locs_ankle_all_max >= 60 & locs_ankle_all_max <= 100);
    if ~isempty(idx)
        [val, pos] = max(pks_ankle_all_max(idx));
        pks_max_ankle_swing = [pks_max_ankle_swing; val];
        locs_pks_max_ankle_swing = [locs_pks_max_ankle_swing; locs_ankle_all_max(idx(pos))];
    end

% Picco di plantarflessione caviglia (5-10°) - Loading Response (10% del ciclo) -> Campioni 5-15
    idx = find(locs_ankle_all_min >= 1 & locs_ankle_all_min <= 15);
    if ~isempty(idx)
        [val, pos] = min(pks_ankle_all_min(idx));
        pks_min_ankle_loadingresponse = [pks_min_ankle_loadingresponse; val];
        locs_pks_min_ankle_loadingresponse = [locs_pks_min_ankle_loadingresponse; locs_ankle_all_min(idx(pos))];
    end

% Picco di plantarflessione caviglia (20-30°) - Pre-Initial Swing (60% del ciclo) -> Campioni 55-65
    idx = find(locs_ankle_all_min >= 50 & locs_ankle_all_min <= 85);
    if ~isempty(idx)
        [val, pos] = min(pks_ankle_all_min(idx));
        pks_min_ankle_preswing = [pks_min_ankle_preswing; val];
        locs_pks_min_ankle_preswing = [locs_pks_min_ankle_preswing; locs_ankle_all_min(idx(pos))];
    end
end

%% calcolo media e deviazione std dei picchi 
% ANCA
Mean_Hip_Flessione_IC = mean(pks_max_hip_initialcontact);
Std_Hip_Flessione_IC = std(pks_max_hip_initialcontact);
Mean_Loc_Hip_Flessione_IC = mean(locs_pks_max_hip_initialcontact);
Std_Loc_Hip_Flessione_IC = std(locs_pks_max_hip_initialcontact);

Mean_Hip_Flessione_TSw = mean(pks_max_hip_terminalswing);
Std_Hip_Flessione_TSw = std(pks_max_hip_terminalswing);
Mean_Loc_Hip_Flessione_TSw = mean(locs_pks_max_hip_terminalswing);
Std_Loc_Hip_Flessione_TSw = std(locs_pks_max_hip_terminalswing);

Mean_Hip_Estensione_TSt = mean(pks_min_hip_terminalstance);
Std_Hip_Estensione_TSt = std(pks_min_hip_terminalstance);
Mean_Loc_Hip_Estensione_TSt = mean(locs_pks_min_hip_terminalstance);
Std_Loc_Hip_Estensione_TSt = std(locs_pks_min_hip_terminalstance);

% GINOCCHIO
Mean_Knee_Flessione_LR = mean(pks_max_knee_loadingresponse);
Std_Knee_Flessione_LR = std(pks_max_knee_loadingresponse);
Mean_Loc_Knee_Flessione_LR = mean(locs_pks_max_knee_loadingresponse);
Std_Loc_Knee_Flessione_LR = std(locs_pks_max_knee_loadingresponse);

Mean_Knee_Flessione_ISw = mean(pks_max_knee_initialswing);
Std_Knee_Flessione_ISw = std(pks_max_knee_initialswing);
Mean_Loc_Knee_Flessione_ISw = mean(locs_pks_max_knee_initialswing);
Std_Loc_Knee_Flessione_ISw = std(locs_pks_max_knee_initialswing);

Mean_Knee_Estensione_IC = mean(pks_min_knee_initialcontact);
Std_Knee_Estensione_IC = std(pks_min_knee_initialcontact);
Mean_Loc_Knee_Estensione_IC = mean(locs_pks_min_knee_initialcontact);
Std_Loc_Knee_Estensione_IC = std(locs_pks_min_knee_initialcontact);

Mean_Knee_Estensione_MTSt = mean(pks_min_knee_midterminalstance);
Std_Knee_Estensione_MTSt = std(pks_min_knee_midterminalstance);
Mean_Loc_Knee_Estensione_MTSt = mean(locs_pks_min_knee_midterminalstance);
Std_Loc_Knee_Estensione_MTSt = std(locs_pks_min_knee_midterminalstance);

% CAVIGLIA
Mean_Ankle_DorsiFlessione_MTSt = mean(pks_max_ankle_midterminalstance);
Std_Ankle_DorsiFlessione_MTSt = std(pks_max_ankle_midterminalstance);
Mean_Loc_Ankle_DorsiFlessione_MTSt = mean(locs_pks_max_ankle_midterminalstance);
Std_Loc_Ankle_DorsiFlessione_MTSt = std(locs_pks_max_ankle_midterminalstance);

Mean_Ankle_DorsiFlessione_Swing = mean(pks_max_ankle_swing);
Std_Ankle_DorsiFlessione_Swing = std(pks_max_ankle_swing);
Mean_Loc_Ankle_DorsiFlessione_Swing = mean(locs_pks_max_ankle_swing);
Std_Loc_Ankle_DorsiFlessione_Swing = std(locs_pks_max_ankle_swing);

Mean_Ankle_PlantarFlessione_LR = mean(pks_min_ankle_loadingresponse);
Std_Ankle_PlantarFlessione_LR = std(pks_min_ankle_loadingresponse);
Mean_Loc_Ankle_PlantarFlessione_LR = mean(locs_pks_min_ankle_loadingresponse);
Std_Loc_Ankle_PlantarFlessione_LR = std(locs_pks_min_ankle_loadingresponse);

Mean_Ankle_PlantarFlessione_PS = mean(pks_min_ankle_preswing);
Std_Ankle_PlantarFlessione_PS = std(pks_min_ankle_preswing);
Mean_Loc_Ankle_PlantarFlessione_PS = mean(locs_pks_min_ankle_preswing);
Std_Loc_Ankle_PlantarFlessione_PS = std(locs_pks_min_ankle_preswing);

%% inserisco i dati in una tabella
EventType = {
    'Anca_Flessione_Picco_1';
    'Anca_Flessione_Picco_2';
    'Anca_Estensione_Picco_1';
    'Ginocchio_Flessione_Picco_1';
    'Ginocchio_Flessione_Picco_2';
    'Ginocchio_Estensione_Picco_1';
    'Ginocchio_Estensione_Picco_2';
    'Caviglia_DorsiFlessione_Picco_1';
    'Caviglia_DorsiFlessione_Picco_2';
    'Caviglia_PlantarFlessione_Picco_1';
    'Caviglia_PlantarFlessione_Picco_2'
};

Mean_Value_Deg = [
    Mean_Hip_Flessione_IC;
    Mean_Hip_Flessione_TSw;
    Mean_Hip_Estensione_TSt;
    Mean_Knee_Flessione_LR;
    Mean_Knee_Flessione_ISw;
    Mean_Knee_Estensione_IC;
    Mean_Knee_Estensione_MTSt;
    Mean_Ankle_DorsiFlessione_MTSt;
    Mean_Ankle_DorsiFlessione_Swing;
    Mean_Ankle_PlantarFlessione_LR;
    Mean_Ankle_PlantarFlessione_PS
];

Std_Dev_Deg = [
    Std_Hip_Flessione_IC;
    Std_Hip_Flessione_TSw;
    Std_Hip_Estensione_TSt;
    Std_Knee_Flessione_LR;
    Std_Knee_Flessione_ISw;
    Std_Knee_Estensione_IC;
    Std_Knee_Estensione_MTSt;
    Std_Ankle_DorsiFlessione_MTSt;
    Std_Ankle_DorsiFlessione_Swing;
    Std_Ankle_PlantarFlessione_LR;
    Std_Ankle_PlantarFlessione_PS
];

Mean_Location_Sample = [ 
    Mean_Loc_Hip_Flessione_IC;
    Mean_Loc_Hip_Flessione_TSw;
    Mean_Loc_Hip_Estensione_TSt;
    Mean_Loc_Knee_Flessione_LR;
    Mean_Loc_Knee_Flessione_ISw;
    Mean_Loc_Knee_Estensione_IC;
    Mean_Loc_Knee_Estensione_MTSt;
    Mean_Loc_Ankle_DorsiFlessione_MTSt;
    Mean_Loc_Ankle_DorsiFlessione_Swing;
    Mean_Loc_Ankle_PlantarFlessione_LR;
    Mean_Loc_Ankle_PlantarFlessione_PS
];

Std_Location_Sample = [ 
    Std_Loc_Hip_Flessione_IC;
    Std_Loc_Hip_Flessione_TSw;
    Std_Loc_Hip_Estensione_TSt;
    Std_Loc_Knee_Flessione_LR;
    Std_Loc_Knee_Flessione_ISw;
    Std_Loc_Knee_Estensione_IC;
    Std_Loc_Knee_Estensione_MTSt;
    Std_Loc_Ankle_DorsiFlessione_MTSt;
    Std_Loc_Ankle_DorsiFlessione_Swing;
    Std_Loc_Ankle_PlantarFlessione_LR;
    Std_Loc_Ankle_PlantarFlessione_PS
];

table_peaks = table(EventType, Mean_Value_Deg, Std_Dev_Deg, ...
    Mean_Location_Sample, Std_Location_Sample, ... 
    'VariableNames', {'EventType', 'Mean_Value_Deg','Std_Dev_Deg', ...
    'Mean_Location_Sample','Std_Location_Sample'}); 
% Raggruppo tutti i picchi e le locazioni in una struttura per un facile accesso
peak_data_struct.pks_max_hip_initialcontact = pks_max_hip_initialcontact;
peak_data_struct.locs_pks_max_hip_initialcontact = locs_pks_max_hip_initialcontact;
peak_data_struct.pks_max_hip_terminalswing = pks_max_hip_terminalswing;
peak_data_struct.locs_pks_max_hip_terminalswing = locs_pks_max_hip_terminalswing;
peak_data_struct.pks_min_hip_terminalstance = pks_min_hip_terminalstance;
peak_data_struct.locs_pks_min_hip_terminalstance = locs_pks_min_hip_terminalstance;

peak_data_struct.pks_max_knee_loadingresponse = pks_max_knee_loadingresponse;
peak_data_struct.locs_pks_max_knee_loadingresponse = locs_pks_max_knee_loadingresponse;
peak_data_struct.pks_max_knee_initialswing = pks_max_knee_initialswing;
peak_data_struct.locs_pks_max_knee_initialswing = locs_pks_max_knee_initialswing;
peak_data_struct.pks_min_knee_initialcontact = pks_min_knee_initialcontact;
peak_data_struct.locs_pks_min_knee_initialcontact = locs_pks_min_knee_initialcontact;
peak_data_struct.pks_min_knee_midterminalstance = pks_min_knee_midterminalstance;
peak_data_struct.locs_pks_min_knee_midterminalstance = locs_pks_min_knee_midterminalstance;

peak_data_struct.pks_max_ankle_midterminalstance = pks_max_ankle_midterminalstance;
peak_data_struct.locs_pks_max_ankle_midterminalstance = locs_pks_max_ankle_midterminalstance;
peak_data_struct.pks_max_ankle_swing = pks_max_ankle_swing;
peak_data_struct.locs_pks_max_ankle_swing = locs_pks_max_ankle_swing;
peak_data_struct.pks_min_ankle_loadingresponse = pks_min_ankle_loadingresponse;
peak_data_struct.locs_pks_min_ankle_loadingresponse = locs_pks_min_ankle_loadingresponse;
peak_data_struct.pks_min_ankle_preswing = pks_min_ankle_preswing;
peak_data_struct.locs_pks_min_ankle_preswing = locs_pks_min_ankle_preswing;

end