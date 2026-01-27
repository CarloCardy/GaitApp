%
clc
close all
clear all 
clearvars

%% LOAD DATI
% i dati presi da s1 (FO) corrispondono al piede destro mentre i dati presi
% da s2 (A7) corrispondono ai dati sulla tibia
% IL PITCH TYPE USATO A LEZIONE ERA ZXY      

%% Aggiungi le cartelle delle funzioni al path
%addpath('C:\Users\Hp\Desktop\Nuova cartella\acquisizioni.2');
%mi serve per poter usare le funzioni presenti in altre cartelle (questa é
%un'aggiunta temporanea, ma sta inserita in modo permanente tramite
%HOME/SET_PATH/ADD_FOLDER/CARTELLA

cd('C:\Users\Hp\Desktop\Nuova cartella\acquisizioni.2\pazienti\acquisizioni 23.09');
% cd = change directory per accedere alla cartella in cui sono contenuti i
% file 
file_name = 'MT_012100F3_029.mtb'; 
%questa variabile mi serve per il titolo delle figure

sensore_1 = importdata ('MT_012100F3_029-000_00B4CAF0.txt');
sensore_2 = importdata ('MT_012100F3_029-000_00B4CBA7.txt');
sensore_3 = importdata ('MT_012100F3_029-000_00B4CB9F.txt');

% così importo i dati dal file.txt
data_foot = sensore_1.data;
data_tibia = sensore_2.data;
data_hip = sensore_3.data;
%così elaboro solo la tabella del file.txt

%% definisco la frerquenza di campionamento ed estraggo l'asse temporale 
Fs = 100; 
%non estratta dal file ma impostata manualmente dal software

time_1 = data_foot(:,1);
time_2 = data_tibia(:,1);
time_3 = data_hip(:,1);
%estraggo la colonna del tempo dai file, ne basterebbe una ma per
%scrupolo le estraggo tutte, solo nel caso i sensori acquisiscano
%dati diversi 

% Trova la lunghezza massima tra i vettori di tempo
max_length = max([length(time_1), length(time_2), length(time_3)]);

% Adatta le dimensioni di time_1, time_2 e time_3
% e dei corrispondenti vettori di dati (data_foot, data_tibia, data_hip)
if length(time_1) < max_length
    time_1 = [time_1; NaN(max_length - length(time_1), 1)];
    data_foot = [data_foot; NaN(max_length - length(data_foot), size(data_foot, 2))];
end
if length(time_2) < max_length
    time_2 = [time_2; NaN(max_length - length(time_2), 1)];
    data_tibia = [data_tibia; NaN(max_length - length(data_tibia), size(data_tibia, 2))];
end
if length(time_3) < max_length
    time_3 = [time_3; NaN(max_length - length(time_3), 1)];
    data_hip = [data_hip; NaN(max_length - length(data_hip), size(data_hip, 2))];
end

% Crea l'asse temporale unificato
time = 1:max_length;

% t_1 = (time_1 - time_1(1))/Fs; 
% t_2 = (time_2 - time_2(1))/Fs;
% t_3 = (time_3 - time_3(1))/Fs;
%creo l'asse temporale, facendo attenzione a farlo partire da zero e
%rispettando la frequenza di acquisizione 

t_1 = time/Fs;
t_2 = time/Fs;
t_3 = time/Fs;
% devo forzare l'asse temporale in questo modo perchè in alcune
% acquisizioni il packet counter si azzerava e non veniva costruito
% correttamente l'asse temporale 

t_inizio = 0.25;
t_fine = 17.85;
% Definisco un tempo di inizio e fine relativo all'acquisizione per
% escludere le sezioni iniziale e finale di segnale per evitare di
% interpretare male i primi/ultimi eventi dove il piede potrebbe già essere
% in movimento 

idx_t_validi_1 = find(t_1 >= t_inizio & t_1 <= t_fine);
idx_t_validi_2 = find(t_2 >= t_inizio & t_2 <= t_fine);
idx_t_validi_3 = find(t_3 >= t_inizio & t_3 <= t_fine);
%trovo gli indici relativi ai tempi che ho impostato

t_1_trim = t_1(idx_t_validi_1);
t_2_trim = t_2(idx_t_validi_2);
t_3_trim = t_3(idx_t_validi_3);
%aggiorno l'asse temporale per escludere sezione iniziale/finale

%% costruisco la matrice di decomposizione sensore 1
M_1 = zeros(3, 3, size(data_foot, 1));
M_1(1,1,:)=data_foot(:,8);  M_1(1,2,:)=data_foot(:,11);  M_1(1,3,:)=data_foot(:,14);
M_1(2,1,:)=data_foot(:,9);  M_1(2,2,:)=data_foot(:,12);  M_1(2,3,:)=data_foot(:,15);
M_1(3,1,:)=data_foot(:,10); M_1(3,2,:)=data_foot(:,13);  M_1(3,3,:)=data_foot(:,16);

%% matrice di rotazione sensore 2
M_2 = zeros(3, 3, size(data_tibia, 1));
M_2(1,1,:)=data_tibia(:,8);  M_2(1,2,:)=data_tibia(:,11);  M_2(1,3,:)=data_tibia(:,14);
M_2(2,1,:)=data_tibia(:,9);  M_2(2,2,:)=data_tibia(:,12);  M_2(2,3,:)=data_tibia(:,15);
M_2(3,1,:)=data_tibia(:,10); M_2(3,2,:)=data_tibia(:,13);  M_2(3,3,:)=data_tibia(:,16);

%% matrice di rotazione sensore 3
M_3 = zeros(3, 3, size(data_hip, 1));
M_3(1,1,:)=data_hip(:,8);  M_3(1,2,:)=data_hip(:,11);  M_3(1,3,:)=data_hip(:,14);
M_3(2,1,:)=data_hip(:,9);  M_3(2,2,:)=data_hip(:,12);  M_3(2,3,:)=data_hip(:,15);
M_3(3,1,:)=data_hip(:,10); M_3(3,2,:)=data_hip(:,13);  M_3(3,3,:)=data_hip(:,16);

%% Calcolo Ang_1.y solo per l'ordine di decomposizione ZXY 
Ang_1_ZXY = Mat2Ang_1(M_1, 'ZXY');
Ang_2_ZXY = Mat2Ang_1(M_2, 'ZXY');
Ang_3_ZXY = Mat2Ang_1(M_3, 'ZXY');
% Questo mi serve per poter segmentare il segnale, perchè non posso
% prendere i dati direttamente dalla funzione

Ang_1_ZXY.y = Ang_1_ZXY.y(idx_t_validi_1);
Ang_2_ZXY.y = Ang_2_ZXY.y(idx_t_validi_2);
Ang_3_ZXY.y = Ang_3_ZXY.y(idx_t_validi_3);
% Restringo il segnale nell'intervallo definito

%% BLOCCO DI INTERPOLAZIONE
%creo dei cell array per angoli ed assi temporali per fare l'interpolazione
AngoliDaInterp = {Ang_1_ZXY.y, Ang_2_ZXY.y, Ang_3_ZXY.y};
TempiDaInterp = {t_1_trim, t_2_trim, t_3_trim};
% Un array di celle è un tipo di dati con contenitori di dati indicizzati 
% chiamati celle, dove ogni cella può contenere qualsiasi tipo di dati. 

%funzione di interpolazione
[AngoliInterpolati, t_comm_final] = interpolaSegnali(AngoliDaInterp, TempiDaInterp);

% Assegnazione dei risultati a variabili individuali per il successivo
% utilizzo 
Ang_1_ZXY_interp = AngoliInterpolati{1};
Ang_2_ZXY_interp = AngoliInterpolati{2};
Ang_3_ZXY_interp = AngoliInterpolati{3};

%% Faccio ora la sottrazione dei pitch FOOT-TIBIA = ANKLE ANGLE
Ang_Ankle_ZXY.y = Ang_1_ZXY_interp - Ang_2_ZXY_interp;

%% Faccio ora la sottrazione dei pitch TIBIA-ANCA = KNEE ANGLE
Ang_Knee_ZXY.y =  Ang_2_ZXY_interp - Ang_3_ZXY_interp; 
Ang_Knee_ZXY.y = - Ang_Knee_ZXY.y;

%% piccola accortezza per rendere i grafici coerenti con la letteratura
Ang_3_ZXY_interp = Ang_3_ZXY_interp + 90;

%% Meno su angoli di tibia ed anca 
% Ang_2_ZXY.y = - Ang_2_ZXY.y;
% Ang_3_ZXY.y = - Ang_3_ZXY.y;

%% piccola accortezza per rendere i grafici coerenti con la letteratura
Ang_Ankle_ZXY.y = Ang_Ankle_ZXY.y - 70;

%% chiamo la funzione di segmentazione del segnale del piede 
[num_passi_foot, durata_passo_foot, ~, idx_passi_validi_foot, ...
    durata_swing_foot, percent_swing_foot, durata_stance_foot, ...
    percent_stance_foot, stacco_foot, appoggio_foot, ...
    idx_stacco_foot, idx_appoggio_foot, zero_cross_pos_foot, zero_cross_neg_foot] = segmentation(t_comm_final, Ang_1_ZXY.y, 'ZXY');
% devo mettere ~ in relazione al III output della funzione perchè
% l'estrazione del segmento non mi serve più, lo avevo messo per poter fare
% la media ma non posso farlo perchè i segmenti non sono della stessa
% dimensione quindi li devo far passare dentro la seconda funzione 
% "segmentSignalWithIDX" in modo che diventino di lunghezza 1x100

%% Segmento il segnale di tibia e quello di caviglia 
% per segmentare questi segnali utilizzo gli indici dei passivalidi 
% del piede ovvero gli idx_passi_validi

start_idx_foot = cellfun(@(x) x(1), idx_passi_validi_foot);
end_idx_foot = cellfun(@(x) x(2), idx_passi_validi_foot);
% cellfun stands for "cell function". Its purpose is to apply a 
% specified function to each cell in a cell array. 
% It's a vectorized way to loop through cells, often more efficient and 
% concise than a traditional for loop.

% @(x) x(1): This is an anonymous function. 
% in wich
% @: Denotes the creation of an anonymous function.
% (x): Defines x as the input argument to this anonymous function.
% x(1): This is the body of the function. 
%       It means "take the input x and return its first element".
% idx_passi_validi: This is the input cell array to cellfun

%in pratica il comando prende la funzione anonima e la applica ad ogni
%cella del cell array idx_passi_validi, che cosa fa questa funzione:
%resituisce il primo elemento di ogni cell array dato che il mio cell array
%contiene gli indici di inizio e fine dei passi validi me li estrae e me li
%mette in un vettore start_idx_foot ed end_idx_foot

%% chiamo la funzione di segmentazione per tibia e caviglia 
segment_foot_raw = segmentSignalWithIDX(Ang_1_ZXY_interp, start_idx_foot, end_idx_foot);
segment_tibia_raw = segmentSignalWithIDX(Ang_2_ZXY_interp, start_idx_foot, end_idx_foot);
segment_hip_raw = segmentSignalWithIDX(Ang_3_ZXY_interp, start_idx_foot, end_idx_foot);
segment_ankle_raw = segmentSignalWithIDX(Ang_Ankle_ZXY.y, start_idx_foot, end_idx_foot);
segment_knee_raw = segmentSignalWithIDX(Ang_Knee_ZXY.y, start_idx_foot, end_idx_foot);
% i segmenti sono tutti di 100 campioni

%% Vado a prendere solo i segmenti pieni scartando quelli vuoti
% nella fnzione ci sono dei controlli che prevengono la rappresentazione di
% questi segmenti, ma vengono comunque salvati quindi li devo levare prima
% di creare la matrice 

%foot
segment_not_empty_foot = ~cellfun(@isempty, segment_foot_raw);
% ~cellfun(@isempty, cell_array_raw):
% @isempty: This is an anonymous function that checks if its input is empty.
% cellfun(...): Applies isempty to each cell in cell_array_raw.
% ~: Negates the logical result. So, ~isempty returns true for non-empty cells and false for empty cells.
% The result, segmento_non_vuoto_xxx, is a logical array ([true; true; false; true; ...]).

segment_foot = segment_foot_raw(segment_not_empty_foot);
% prendo solo i segmenti pieni (dim 1x100) scegliendoli dagli indici
% di segmento_non_vuoto 

% tibia
segment_not_empty_tibia = ~cellfun(@isempty, segment_tibia_raw);
segment_tibia = segment_tibia_raw(segment_not_empty_tibia);

% hip
segment_not_empty_hip = ~cellfun(@isempty, segment_hip_raw);
segment_hip = segment_hip_raw(segment_not_empty_hip);

% ankle
segment_not_empty_ankle = ~cellfun(@isempty, segment_ankle_raw);
segment_ankle = segment_ankle_raw(segment_not_empty_ankle);

% knee
segment_not_empty_knee = ~cellfun(@isempty, segment_knee_raw);
segment_knee = segment_knee_raw(segment_not_empty_knee);

%% verifica dei segmenti piede tibia e caviglia 
disp(' ');
disp(['Numero di passi identificati:', num2str(length(num_passi_foot))]);
disp(['Numero di segmenti per il PIEDE (from original segmentation): ', num2str(length(segment_foot))]); 
% deve essere uguale a num_passi_foot

disp(['Numero di segmenti per la TIBIA (using foot indices): ', num2str(length(segment_tibia))]);
disp(['Numero di segmenti per la ANCA (using foot indices): ', num2str(length(segment_hip))]);
disp(['Numero di segmenti per la CAVIGLIA (using foot indices): ', num2str(length(segment_ankle))]);
disp(['Numero di segmenti per il GINOCCHIO (using foot indices): ', num2str(length(segment_knee))]);

%% calcolo la media dei segmenti e la deviazione standard
% per poter fare la media devo convertire i miei cell array in matrici.
% sono già in colonna con ogni cella che contiene vettori in riga 
% quindi è più facile 

segment_foot_M = cell2mat(segment_foot);
% cell2mat passa da un cell array ad una matrice che in questo caso diventa
% una matrice n righe (quanti sono i segmenti) e 100 colonne (una per ogni
% punto del segmento)

segment_tibia_M = cell2mat(segment_tibia);
segment_hip_M = cell2mat(segment_hip);
segment_ankle_M = cell2mat(segment_ankle);
segment_knee_M = cell2mat(segment_knee);

% calcolo la media e la deviazione standard
mean_foot_cycle = mean(segment_foot_M, 1);
std_foot_cycle = std(segment_foot_M, 0, 1);

mean_tibia_cycle = mean(segment_tibia_M, 1);
std_tibia_cycle = std(segment_tibia_M, 0, 1);

mean_hip_cycle = mean(segment_hip_M, 1);
std_hip_cycle = std(segment_hip_M, 0, 1);

mean_ankle_cycle = mean(segment_ankle_M, 1);
std_ankle_cycle = std(segment_ankle_M, 0, 1);

mean_knee_cycle = mean(segment_knee_M, 1);
std_knee_cycle = std(segment_knee_M, 0, 1);

%% creo un asse delle ascisse che va da  1 a 100 per media e std
x_axis = (1:100);

%% prendo gli eventi di tempo per segmentare i passi
t_passi = t_comm_final(start_idx_foot);

%% Trovo la media delle altre variabili 
mean_durata_passo_foot = mean((durata_passo_foot.'), 1);
mean_durata_stance_foot = mean(durata_stance_foot, 1);
mean_durata_swing_foot = mean(durata_swing_foot, 1);
mean_percent_stance_foot = mean(percent_stance_foot, 1);
mean_percent_swing_foot = mean(percent_swing_foot, 1);

%% creo la figura in cui rappresento gli angoli articolari con media ed std
hFig1 = figure('Name', 'Anca Ginocchio Caviglia',...
    'NumberTitle', 'off');
% Titolo generale per l'intera finestra

nomefile_disp=strrep(file_name, '_', '\_'); 
% per non visualizzare gli undescore come pedici

%% impostazioni della figura, posizione degli oggetti, titoli, dimensioni etc.
set(gcf,'WindowState','maximized'); 
%per avere la figura a tutto schermo

% set(gca, 'Position', [0.07 0.1 0.9 0.8]);  % [left bottom width height]
% % ax = gca restituisce gli assi correnti (o la visualizzazione standalone) 
% % nella figura corrente. Utilizzare ax per ottenere e impostare 
% % le proprietà degli assi correnti. Se non sono presenti assi o grafici 
% % nella figura corrente, gca crea un oggetto assi cartesiani.

%set(hFig1, 'Position', [100, 100, 1200, 700]);  
% imposta la dimensione della finestra per non sovrapporre i titoli

sg1=sgtitle(sprintf(' Angoli Articolari (File: %s)',...
    nomefile_disp),'Interpreter', 'tex', 'FontSize', 14, ...
    'FontWeight', 'bold', 'color','red');
%titolo della figura

%% subplot 1  della 1° figura
subplot(3,2,1);
hHip = plot(t_comm_final, Ang_3_ZXY_interp, 'k'); 
hold on
grid on;
grid minor;

hXLineFoot = xline(t_passi, 'r:', 'LineWidth',2);
% crea delle linee vericali per evidenziare meglio i segmenti 
xlim('tight');
ylim('tight');
title('Angolo di anca');
ylabel('Degrees');
xlabel('time');
lgd = legend([hHip, hXLineFoot(1)], ...
    {'Hip angle', 'xline Foot (segment)'}, ...
    'Location', 'northeastoutside');
lgd.Title.String = 'Legend';

%% subplot 2 della 1° figura
subplot(3,2,2);
hMeanHip = plot(x_axis, mean_hip_cycle, 'k');

hold on
% Definisco i limiti superiori ed inferiori della media usando std  
lower_bound_hip = (mean_hip_cycle - std_hip_cycle);
upper_bound_hip = (mean_hip_cycle + std_hip_cycle);

% The x-coordinates go forward along the lower bound, then backward along the upper bound
% The y-coordinates follow the lower bound, then the upper bound in reverse
hFillHip = fill([x_axis, fliplr(x_axis)], [lower_bound_hip, fliplr(upper_bound_hip)], ...
    [0.5 0.5 0.5], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
% [0.8 0.8 0.8] is a light grey color. 
% 'FaceAlpha' controls transparency (0=fully transparent, 1=fully opaque).
% 'EdgeColor', 'none' removes the border around the filled area.

hStdPlusHip = plot(x_axis, (mean_hip_cycle + std_hip_cycle), '--r');
hStdMinusHip = plot(x_axis, (mean_hip_cycle - std_hip_cycle), '--b');
grid on;
grid minor;
xlim('tight');
ylim('tight');
title('Media angolo Y (Pitch) anca');
ylabel('Degrees');
xlabel('Samples');
lgd = legend([hMeanHip, hFillHip, hStdPlusHip, hStdMinusHip], ...
    {'Mean Hip angle', 'Standard Deviation', 'Mean + Std', 'Mean - Std'}, ...
    'Location', 'northeastoutside');
lgd.Title.String = 'Legend';

%% subplot 3 della 1° figura
subplot(3,2,3);
hKnee = plot(t_comm_final, Ang_Knee_ZXY.y, 'k'); 
hold on
grid on;
grid minor;

hXLineFoot = xline(t_passi, 'r:', 'LineWidth',2);
% crea delle linee vericali per evidenziare meglio i segmenti 
xlim('tight');
ylim('tight');
title('Angolo di ginocchio');
ylabel('Degrees');
xlabel('time');
lgd = legend([hKnee, hXLineFoot(1)], ...
    {'Knee angle', 'xline Foot (segment)'}, ...
    'Location', 'northeastoutside');
lgd.Title.String = 'Legend';

%% subplot 4 della 1° figura
subplot(3,2,4);
hMeanKnee = plot(x_axis, mean_knee_cycle, 'k');

hold on
% Definisco i limiti superiori ed inferiori della media usando std  
lower_bound_knee = (mean_knee_cycle - std_knee_cycle);
upper_bound_knee = (mean_knee_cycle + std_knee_cycle);

% The x-coordinates go forward along the lower bound, then backward along the upper bound
% The y-coordinates follow the lower bound, then the upper bound in reverse
hFillKnee = fill([x_axis, fliplr(x_axis)], [lower_bound_knee, fliplr(upper_bound_knee)], ...
    [0.5 0.5 0.5], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
% [0.8 0.8 0.8] is a light grey color. 
% 'FaceAlpha' controls transparency (0=fully transparent, 1=fully opaque).
% 'EdgeColor', 'none' removes the border around the filled area.

hStdPlusKnee = plot(x_axis, (mean_knee_cycle + std_knee_cycle), '--r');
hStdMinusKnee = plot(x_axis, (mean_knee_cycle - std_knee_cycle), '--b');
grid on;
grid minor;
xlim('tight');
ylim('tight');
title('Media angolo Y ginocchio');
ylabel('Degrees');
xlabel('Samples');
lgd = legend([hMeanKnee, hFillKnee, hStdPlusKnee, hStdMinusKnee], ...
    {'Mean Knee angle', 'Standard Deviation', 'Mean + Std', 'Mean - Std'}, ...
    'Location', 'northeastoutside');
lgd.Title.String = 'Legend';

%% subplot 5  della 1° figura
subplot(3,2,5);
hAnkle = plot(t_comm_final, Ang_Ankle_ZXY.y, 'k'); 
hold on
grid on;
grid minor;

hXLineFoot = xline(t_passi, 'r:', 'LineWidth',2);
% crea delle linee vericali per evidenziare meglio i segmenti 
xlim('tight');
ylim('tight');
title('Angolo della caviglia');
ylabel('Degrees');
xlabel('time');
lgd = legend([hAnkle, hXLineFoot(1)], ...
    {'Ankle angle', 'xline Foot (segment)'}, ...
    'Location', 'northeastoutside');
lgd.Title.String = 'Legend';

%% subplot 6 della 1° figura
subplot(3,2,6);
hMeanAnkle = plot(x_axis, mean_ankle_cycle, 'k');

hold on
% Definisco i limiti superiori ed inferiori della media usando std  
lower_bound_ankle = (mean_ankle_cycle - std_ankle_cycle);
upper_bound_ankle = (mean_ankle_cycle + std_ankle_cycle);

% The x-coordinates go forward along the lower bound, then backward along the upper bound
% The y-coordinates follow the lower bound, then the upper bound in reverse
hFillAnkle = fill([x_axis, fliplr(x_axis)], [lower_bound_ankle, fliplr(upper_bound_ankle)], ...
    [0.5 0.5 0.5], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
% [0.8 0.8 0.8] is a light grey color. 
% 'FaceAlpha' controls transparency (0=fully transparent, 1=fully opaque).
% 'EdgeColor', 'none' removes the border around the filled area.

hStdPlusAnkle = plot(x_axis, (mean_ankle_cycle + std_ankle_cycle), '--r');
hStdMinusAnkle = plot(x_axis, (mean_ankle_cycle - std_ankle_cycle), '--b');
grid on;
grid minor;
xlim('tight');
ylim('tight');
title('Media angolo Y caviglia');
ylabel('Degrees');
xlabel('Samples');
lgd = legend([hMeanAnkle, hFillAnkle, hStdPlusAnkle, hStdMinusAnkle], ...
    {'Mean Ankle angle','Standard Deviation', 'Mean + Std', 'Mean - Std'}, ...
    'Location', 'northeastoutside');
lgd.Title.String = 'Legend';

%% seconda figura in cui rappresento  gli angoli dei segmenti corporei con media ed std
hFig2 = figure('Name', 'Femore Tibia Piede',...
    'NumberTitle', 'off');
% Titolo generale per l'intera finestra

%% impostazioni della figura, posizione degli oggetti, titoli, dimensioni etc.
set(gcf,'WindowState','maximized'); 
%per avere la figura a tutto schermo

% set(gca, 'Position', [0.07 0.1 0.9 0.8]);  % [left bottom width height]
% % ax = gca restituisce gli assi correnti (o la visualizzazione standalone) 
% % nella figura corrente. Utilizzare ax per ottenere e impostare 
% % le proprietà degli assi correnti. Se non sono presenti assi o grafici 
% % nella figura corrente, gca crea un oggetto assi cartesiani.

%set(hFig2, 'Position', [100, 100, 1200, 700]);  
% imposta la dimensione della finestra per non sovrapporre i titoli

sg2=sgtitle(sprintf('Pitch dei segmenti corporei (File: %s)',...
    nomefile_disp),'Interpreter', 'tex', 'FontSize', 14, ...
    'FontWeight', 'bold', 'color','red');
%titolo della figura

%% subplot 1 della 2° figura
subplot(3,2,1);
hHip = plot(t_comm_final, Ang_3_ZXY_interp, 'g'); 
hold on
grid on;
grid minor;

hXLineFoot = xline(t_passi, 'k:', 'LineWidth',2);
% crea delle linee vericali per evidenziare meglio i segmenti 
xlim('tight');
ylim('tight');
title('Angolo di anca');
ylabel('Degrees');
xlabel('time');
lgd = legend([hHip, hXLineFoot(1)], ...
    {'Hip angle', 'xline Foot (segment)'}, ...
    'Location', 'northeastoutside');
lgd.Title.String = 'Legend';

%% subplot 2  della 1° figura
subplot(3,2,2);
hMeanHip = plot(x_axis, mean_hip_cycle, 'g');

hold on
% Definisco i limiti superiori ed inferiori della media usando std  
lower_bound_hip = (mean_hip_cycle - std_hip_cycle);
upper_bound_hip = (mean_hip_cycle + std_hip_cycle);

% The x-coordinates go forward along the lower bound, then backward along the upper bound
% The y-coordinates follow the lower bound, then the upper bound in reverse
hFillHip = fill([x_axis, fliplr(x_axis)], [lower_bound_hip, fliplr(upper_bound_hip)], ...
    [0.5 0.5 0.5], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
% [0.8 0.8 0.8] is a light grey color. 
% 'FaceAlpha' controls transparency (0=fully transparent, 1=fully opaque).
% 'EdgeColor', 'none' removes the border around the filled area.

hStdPlusHip = plot(x_axis, (mean_hip_cycle + std_hip_cycle), '--m');
hStdMinusHip = plot(x_axis, (mean_hip_cycle - std_hip_cycle), '--c');
grid on;
grid minor;
xlim('tight');
ylim('tight');
title('Media angolo Y (Pitch) anca');
ylabel('Degrees');
xlabel('Samples');
lgd = legend([hMeanHip, hFillHip, hStdPlusHip, hStdMinusHip], ...
    {'Mean Hip angle', 'Standard Deviation', 'Mean + Std', 'Mean - Std'}, ...
    'Location', 'northeastoutside');
lgd.Title.String = 'Legend';

%% subplot 3 della 2° figura
subplot(3,2,3);
hPitchTibia = plot(t_comm_final, Ang_2_ZXY_interp, 'r'); 
hold on
grid on;
grid minor;

hXLineFoot = xline(t_passi, 'k:', 'LineWidth',2);
% crea delle linee vericali per evidenziare meglio i segmenti 
% quando si usa xline MATLAB disegna una xline per ogni valore 
% e restituisce un array di handle grafici. però non si può mettere in 
% legenda più oggetti dello stesso tipo (come più xline) con un'unica etichetta.

lgd = legend([hPitchTibia, hXLineFoot(1)],{'pitch Tibia', ...
     'xline Foot (segmento)'}, 'Location', 'northeastoutside');
lgd.Title.String = 'Legend';
xlim('tight');
ylim('tight');
title('Angolo Y (Pitch) tibia');
ylabel('Degrees');
xlabel('time');

%% subplot 4 della 2° figura
subplot(3,2,4);
hMeanTibia = plot(x_axis, mean_tibia_cycle, 'r');

hold on
% Definisco i limiti superiori ed inferiori della media usando std  
lower_bound_tibia = (mean_tibia_cycle - std_tibia_cycle);
upper_bound_tibia = (mean_tibia_cycle + std_tibia_cycle);

% The x-coordinates go forward along the lower bound, then backward along the upper bound
% The y-coordinates follow the lower bound, then the upper bound in reverse
hFillTibia = fill([x_axis, fliplr(x_axis)], [lower_bound_tibia, fliplr(upper_bound_tibia)], ...
    [0.5 0.5 0.5], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
% [0.8 0.8 0.8] is a light grey color. 
% 'FaceAlpha' controls transparency (0=fully transparent, 1=fully opaque).
% 'EdgeColor', 'none' removes the border around the filled area.

hStdPlusTibia = plot(x_axis, (mean_tibia_cycle + std_tibia_cycle), '--m');
hStdMinusTibia = plot(x_axis, (mean_tibia_cycle - std_tibia_cycle), '--c');
grid on;
grid minor;
xlim('tight');
ylim('tight');
title('Media angolo Y (Pitch) tibia');
ylabel('Degrees');
xlabel('Samples');
lgd = legend([hMeanTibia, hFillTibia, hStdPlusTibia, hStdMinusTibia], ...
    {'Mean Tibia angle', 'Standard Deviation', 'Mean + Std', 'Mean - Std'}, ...
    'Location', 'northeastoutside');
lgd.Title.String = 'Legend';

%% subplot 5 della 2° figura
subplot(3,2,5);
hPitchFoot = plot(t_comm_final, Ang_1_ZXY_interp, 'b');
hold on
grid on;
grid minor;
xlim('tight');
ylim('tight');

zero_cross_neg_foot = find(diff(sign(Ang_1_ZXY_interp - Ang_1_ZXY_interp(1,1))) < 0);

%zero_cross_pos_foot = find(diff(sign(Ang_1_ZXY_interp - Ang_1_ZXY_interp(1,1))) > 0);
% Questa riga fa riferimento agli attraversamenti per lo zero positivi, è
% un'alternativa

%t_zero_cross = t_comm_final(zero_cross_neg_foot);
%creo l'asse dei tempi per la linea che attraverserà i zero_cross

%y_zero_cross= Ang_1_ZXY_interp(zero_cross_neg_foot);
%creo la linea che passsera per zero_cross

hPtoZeroNFoot = scatter(t_comm_final(zero_cross_neg_foot),Ang_1_ZXY_interp(zero_cross_neg_foot), 'k*');
% evidenzio gli eventi di attraversamento dello zero che mi segmentano il
% passo 
%hPtoZeroPFoot = scatter(t_comm_final(zero_cross_pos_foot),Ang_1_ZXY_interp(zero_cross_pos_foot), 'w*')

%hLineFoot = plot(t_zero_cross, y_zero_cross, 'k--');
% linea che passa per gli attraversamenti dello zero 

hXLineFoot = xline(t_passi, 'k:', 'LineWidth',2);
% crea delle linee vericali per evidenziare meglio i segmenti 
% quando si usa xline MATLAB disegna una xline per ogni valore 
% e restituisce un array di handle grafici. però non si può mettere in 
% legenda più oggetti dello stesso tipo (come più xline) con un'unica etichetta.

hStaccoFoot = scatter(idx_stacco_foot, interp1(t_comm_final, Ang_1_ZXY_interp, ...
    idx_stacco_foot),50,'b','d','filled');
% evidenzio gli eventi di Toe Off, ovvero di distacco del piede

hAppoggioFoot = scatter(idx_appoggio_foot, interp1(t_comm_final, Ang_1_ZXY_interp, ...
    idx_appoggio_foot),50,'r','o','filled');
% evidenzio gli eventi di Heel Strike, ovvero l'appoggio del piede

title('Angolo Y (Pitch) piede ');
ylabel('Degrees','FontWeight', 'bold');
xlabel('time','FontWeight', 'bold');
% titolo del subplot e degli assi

lgd = legend([hPitchFoot, hPtoZeroNFoot, hXLineFoot(1), ...
    hStaccoFoot, hAppoggioFoot],{'pitch Foot', ...
     'Zero-Crossing line Foot', 'xline Foot (segment)', ...
     'stacco Foot', 'appoggio Foot'}, 'Location', 'northeastoutside');
lgd.Title.String = 'Legend';
% hXLineDX(1), hXLineSX(1) guarda commento di xline
%legenda con posizione e titolo

%% subplot 6  della 2° figura
subplot(3,2,6);
hMeanFoot = plot(x_axis, mean_foot_cycle, 'b');

hold on
% Definisco i limiti superiori ed inferiori della media usando std  
lower_bound_foot = (mean_foot_cycle - std_foot_cycle);
upper_bound_foot = (mean_foot_cycle + std_foot_cycle);

% The x-coordinates go forward along the lower bound, then backward along the upper bound
% The y-coordinates follow the lower bound, then the upper bound in reverse
hFillFoot = fill([x_axis, fliplr(x_axis)], [lower_bound_foot, fliplr(upper_bound_foot)], ...
    [0.5 0.5 0.5], 'FaceAlpha', 0.5, 'EdgeColor', 'none');
% [0.8 0.8 0.8] is a light grey color. 
% 'FaceAlpha' controls transparency (0=fully transparent, 1=fully opaque).
% 'EdgeColor', 'none' removes the border around the filled area.

hStdPlusFoot = plot(x_axis, (mean_foot_cycle + std_foot_cycle), '--m');
hStdMinusFoot = plot(x_axis, (mean_foot_cycle - std_foot_cycle), '--c');
grid on;
grid minor;
xlim('tight');
ylim('tight');
title('Media angolo Y (Pitch) piede');
ylabel('Degrees');
xlabel('Samples');
lgd = legend([hMeanFoot, hFillFoot, hStdPlusFoot, hStdMinusFoot], ...
    {'Mean Foot angle', 'Standard Deviation', 'Mean + Std', 'Mean - Std'}, ...
    'Location', 'northeastoutside');
lgd.Title.String = 'Legend';

%% BLOCCO DI SALVATAGGIO DELLE FIGURE 
output_folder = 'C:\Users\Hp\Desktop\Nuova cartella\img\pazienti\paziente.4\acquisizione 23.09\NO_ORTESI_S_arto_sano(dx)'; 
% il percorso va aggiornato ogni cambio di individuo o parametri

% Create the folder if it doesn't exist
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
%  breakdown:
% - exist(name, 'kind'): This function checks for the existence of name and 
% specifies what kind of thing to look for.
% - output_folder: This is the variable holding the path to the folder you 
% want to check (e.g., 'C:\Users\YourUser\Documents\MatlabFigures').
% - 'dir': This string literal explicitly tells exist to search only 
% for directories (folders).
% So, the line if ~exist(output_folder, 'dir') literally translates to:
% "If the output_folder does not exist as a directory (folder), 
% then execute the following code (which is mkdir(output_folder) to create it)."

% Get the base name of the file without the extension (e.g., 'MT_012100F3_XXX')
[~, base_filename, ~] = fileparts(file_name); 
% fileparts extracts parts of a file path: 
% [path, name, ext] = fileparts(filename)

% Save Figure 1
saveas(hFig1, fullfile(output_folder, sprintf('Anca_Ginocchio_Caviglia_%s.png', base_filename)));
saveas(hFig1, fullfile(output_folder, sprintf('Anca_Ginocchio_Caviglia_%s.fig', base_filename)));

% Save Figure 2
saveas(hFig2, fullfile(output_folder, sprintf('Femore_Tibia_Piede_%s.png', base_filename)));
saveas(hFig2, fullfile(output_folder, sprintf('Femore_Tibia_Piede_%s.fig', base_filename)));

disp(['Images saved to: ', output_folder]);

%% Creo ora una tabella per i dati relativi al piede
% queste righe sono per controllare se i miei dati sono organizzari in riga
% o colonna per poterle mettere nella tabella
% disp(['Size of Passo_Foot: ', mat2str(size(num_passi_foot))]);
% disp(['Size of durata_passo_foot: ', mat2str(size(durata_passo_foot))]);
% disp(['Size of durata_swing_foot: ', mat2str(size(durata_swing_foot))]);
% disp(['Size of percent_swing_foot: ', mat2str(size(percent_swing_foot))]);
% disp(['Size of durata_stance_foot: ', mat2str(size(durata_stance_foot))]);
% disp(['Size of percent_stance_foot: ', mat2str(size(percent_stance_foot))]);

    if ~isempty(durata_passo_foot)
Passo_Foot_Str = cellfun(@num2str, num2cell((1:length(durata_passo_foot))'),'UniformOutput', false); 
% Step number based on actual valid steps
% Converto 'Passo_Foot' in un cell array di stringhe fin dall'inizio
% Questo permette di mescolare numeri (convertiti in stringhe) e la stringa 'Medie'
Tabella_Foot = table(Passo_Foot_Str, durata_passo_foot', ...
    durata_swing_foot,percent_swing_foot,durata_stance_foot, ...
    percent_stance_foot, 'VariableNames', {'Num_Passo', ...
    'Durata_Totale_Sec', 'Durata_Swing_Sec', 'Percent_Swing', ...
    'Durata_Stance_Sec', 'Percent_Stance'});

%% creo la riga  per le medie da aggiungere alla tabella 
% Per 'Num_Passo' uso la scritta Media per indicare che non è un passo specifico,
% ma una media, riferita alle colonne successive.

% Per garantire la compatibilità dei tipi di dato tra la tabella esistente 
% e la nuova riga, estraggo i tipi di dato delle colonne numeriche della tabella 
% e li uso per la nuova riga.
% Questo è importante se ci sono colonne integer (come num_passi) o altri tipi specifici.

% Inizializzo una riga vuota con i nomi delle variabili per mantenere la struttura
    new_row = cell2table(cell(1, width(Tabella_Foot)), 'VariableNames', ...
        Tabella_Foot.Properties.VariableNames);

% Assegno i valori medi alla nuova riga
    new_row.Num_Passo = {'Medie'};  
    new_row.Durata_Totale_Sec = mean_durata_passo_foot;
    new_row.Durata_Swing_Sec = mean_durata_swing_foot;
    new_row.Percent_Swing = mean_percent_swing_foot;
    new_row.Durata_Stance_Sec = mean_durata_stance_foot;
    new_row.Percent_Stance = mean_percent_stance_foot;
    
% Appendo la nuova riga alla tabella esistente
    Tabella_Foot = [Tabella_Foot; new_row];
% dopo aver controllato la forma dei dati inverto durata_passo_foot
disp(' ');
disp('Tabella Parametri Gait - Sensore Piede:');
disp(Tabella_Foot);
    else
disp(' ');
disp('Nessun passo valido rilevato per il sensore Piede.');
Tabella_Foot = table();
end

%% estrazione dei picchi negli angoli di caviglia ginocchio e anca per ogni passo 
% Richiamo la funzione per estrarre i picchi e calcolare le statistiche
[all_gait_peaks, Tabella_PicchiMedi_Articolari] = extractAndCalculateGaitPeaks...
    (segment_foot, segment_hip, segment_knee, segment_ankle);
disp(' ');
disp('Tabella Riepilogativa Massimi e Minimi per Tipo di Evento (Medie da tutti i cicli):');
disp(Tabella_PicchiMedi_Articolari);

%% blocco di salvataggio tabelle + esportazione Exel
output_data_folder = 'C:\Users\Hp\Desktop\Nuova cartella\img\pazienti\paziente.4\acquisizione 23.09\NO_ORTESI_S_arto_sano(dx)\variabili';

if ~exist(output_data_folder, 'dir')
    mkdir(output_data_folder);
end

save_filename = fullfile(output_data_folder, sprintf('GaitAnalysisData_%s.mat', base_filename));

% Salva tutte le variabili rilevanti, inclusa la nuova tabella dei picchi medi
save(save_filename, ...
     'Tabella_Foot',...
     'Tabella_PicchiMedi_Articolari',... % La nuova tabella
     'idx_appoggio_foot','idx_stacco_foot', ...
     'zero_cross_neg_foot', 'Fs', 't_comm_final', ...
     'all_gait_peaks');

disp(['File MAT salvato in: ' save_filename]);
%% === Conversione del file .mat appena salvato in Excel ===
% Carica il contenuto del .mat
data = load(save_filename);

% Individua le variabili di tipo table
nomiVariabili = fieldnames(data);
isTab = structfun(@(x) istable(x), data);
nomiTabelle = nomiVariabili(isTab);

if isempty(nomiTabelle)
    warning('Nessuna variabile di tipo table trovata nel file MAT.');
else
    % Nome Excel (stesso base name del MAT)
    [~, baseName, ~] = fileparts(save_filename);
    excelNameUnico = [baseName '.xlsx'];

    % 1️. Percorso Excel nella stessa cartella del MAT
    fullExcelPath_local = fullfile(output_data_folder, excelNameUnico);

    % 2️. Percorso Excel anche in TabelleExcel
    excel_folder_global = 'C:\Users\Hp\Desktop\Nuova cartella\TabelleExcel\paziente.4\acquisizione 23.09\NO_ORTESI_S_arto_sano(dx)';
    if ~exist(excel_folder_global, 'dir')
        mkdir(excel_folder_global);
    end
    fullExcelPath_global = fullfile(excel_folder_global, excelNameUnico);

    % Esporta ogni tabella in entrambi i percorsi
    for k = 1:numel(nomiTabelle)
        writetable(data.(nomiTabelle{k}), fullExcelPath_local,  'Sheet', nomiTabelle{k});
        writetable(data.(nomiTabelle{k}), fullExcelPath_global, 'Sheet', nomiTabelle{k});
    end

    disp(['Tabelle esportate in: ' fullExcelPath_local]);
    disp(['Tabelle esportate in: ' fullExcelPath_global]);
end