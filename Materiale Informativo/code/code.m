%
clc
close all
clear all 
clearvars

%% LOAD DATI
% i dati presi da s1 (FO) corrispondono al piede destro mentre i dati presi
% da s2 (A7) corrispondono al piede sinistro
% IL PITCH TYPE USATO A LEZIONE ERA ZXY      
nomefile='MT_012100F3_004.mtb'; 
%questa variabile mi serve per il titolo delle figure

sensore_1 = importdata ('MT_012100F3_004-000_00B4CAF0.txt');
sensore_2 = importdata ('MT_012100F3_004-000_00B4CBA7.txt');
%estraggo i dati dal file.txt

DATA_1=sensore_1.data;
DATA_2=sensore_2.data;
%così elaboro solo la tabella del file.txt

Fs=100; 
%non estratta dal file ma impostata manualmente dal software

%% creo e gestisco l'asse temporale 

time_1=DATA_1(:,1);
time_2=DATA_2(:,1);
%estraggo la colonna del tempo da entrambi i file, ne basterebbe una ma per
%scrupolo le estraggo entrambe, solo nel caso i due sensori acquisiscano
%dati diversi 

t_1 = (time_1 - time_1(1))/Fs; 
t_2 = (time_2 - time_2(1))/Fs; 
%creo l'asse temporale, facendo attenzione a farlo partire da zero e
%rispettando la frequenza di acquisizione 

t_inizio=0.25;
t_fine=5.25;
% Definisco un tempo di inizio e fine relativo all'acquisizione per
% escludere le sezioni iniziale e finale di segnale per evitare di
% interpretare male i primi/ultimi eventi dove il piede potrebbe già essere
% in movimento 

idx_t_validi_1=find(t_1>=t_inizio & t_1<=t_fine);
idx_t_validi_2=find(t_2>=t_inizio & t_2<=t_fine);
%trovo gli indici relativi ai tempi che ho impostato

t_1_trim = t_1(idx_t_validi_1);
t_2_trim = t_2(idx_t_validi_2);
%aggiorno l'asse temporale per escludere sezione iniziale/finale

%% costruisco la matrice di decomposizione sensore 1
M_1 = zeros(3, 3, size(DATA_1, 1));  
M_1(1,1,:)=DATA_1(:,8);  M_1(1,2,:)=DATA_1(:,11);  M_1(1,3,:)=DATA_1(:,14);
M_1(2,1,:)=DATA_1(:,9);  M_1(2,2,:)=DATA_1(:,12);  M_1(2,3,:)=DATA_1(:,15);
M_1(3,1,:)=DATA_1(:,10); M_1(3,2,:)=DATA_1(:,13);  M_1(3,3,:)=DATA_1(:,16);

%% matrice di rotazione sensore 2
M_2 = zeros(3, 3, size(DATA_2, 1));
M_2(1,1,:)=DATA_2(:,8);  M_2(1,2,:)=DATA_2(:,11);  M_2(1,3,:)=DATA_2(:,14);
M_2(2,1,:)=DATA_2(:,9);  M_2(2,2,:)=DATA_2(:,12);  M_2(2,3,:)=DATA_2(:,15);
M_2(3,1,:)=DATA_2(:,10); M_2(3,2,:)=DATA_2(:,13);  M_2(3,3,:)=DATA_2(:,16);

%% Definisco l'ordine di decomposizione per i vari plot 
decomposition_orders = {"XYZ", "XZY", "YXZ", "YZX", "ZXY", "ZYX"};

%% Creo la figura dei pitch per ogni ordine di scomposizione per i dati del primo sensore
hFig1 = figure('Name', 'Angolo di Pitch DX per ogni ordine di scomposizione', 'NumberTitle', 'off');
% Titolo generale per l'intra finestra

nomefile_disp=strrep(nomefile, '_', '\_'); 
% per non visualizzare gli undescore come pedici 

sg1 = sgtitle(sprintf('Angolo di pitch PIEDE DX per diversi ordini di scomposizione (File: %s)', nomefile_disp), ...
    'Interpreter', 'tex', 'FontSize', 14, 'FontWeight', 'bold');
% titolo della figura 

for i = 1:length(decomposition_orders)
current_order = decomposition_orders{i}; 
%viene assegnato l'indice relativo all'ordine di scomposizione usato

Ang_1_temp = Mat2Ang_1(M_1, current_order);
%Richiamo la funzione

if any(isnan(Ang_1_temp.y))
    disp('VALORI NaN in Ang_1_temp.y');
else
    disp('NESSUN VALORE NaN in Ang_1_temp.y');
end
% controllo se ci sono dei NaN nell'angolo di pitch del sensore 1 

Ang_1_temp.y = Ang_1_temp.y(idx_t_validi_1);
%restringo il grafico tagliando primi/ultimi campioni

%% subplots della prima figura
subplot(3,2,i);
% i subplot si auto posizionano seguendo l'ordine di decomposizione
% impostato

plot(t_1_trim, Ang_1_temp.y, 'b');
grid on;
grid minor;
xlim('tight');
ylim('tight');
%restringo gli assi alla dimensione del segnale

title_str = sprintf('Ordine: %s', current_order);
title(title_str, 'Angle Y (Pitch)');
%titolo del subplot

ylabel('Degrees');
xlabel('time');
    
end    

%% faccio la stessa cosa ma con i dati del secondo sensore
hFig2 = figure('Name', 'Angolo di Pitch SX per ogni ordine di scomposizione', 'NumberTitle', 'off');
% Titolo generale per l'intera finestra

nomefile_disp=strrep(nomefile, '_', '\_'); 
% per non visualizzare gli undescore come pedici

sg2 = sgtitle(sprintf('Angolo di Pitch PIEDE SX per diversi ordini di scomposizione (File: %s)', nomefile_disp), ...
    'Interpreter', 'tex', 'FontSize', 14, 'FontWeight', 'bold');
% titolo della figura

for i = 1:length(decomposition_orders)
current_order = decomposition_orders{i};
%viene assegnato l'indice relativo all'ordine di scomposizione usato

Ang_2_temp = Mat2Ang_1(M_2, current_order);
% richiamo la funzione

if any(isnan(Ang_2_temp.y))
    disp('VALORI NaN in Ang_2_temp.y');
else
    disp('NESSUN VALORE NaN in Ang_2_temp.y');
end
% controllo se ci sono dei NaN nell'angolo di pitch del sensore 2 

Ang_2_temp.y = Ang_2_temp.y(idx_t_validi_2);
%restringo il grafico tagliando primi/ultimi campioni

%% subplots della prima figura
subplot(3,2,i);
% i subplot si auto posizionano seguendo l'ordine di decomposizione
% impostato

plot(t_2_trim, Ang_2_temp.y, 'r');
grid on;
grid minor;
xlim('tight');
ylim('tight');
%restringo gli assi alla dimensione del segnale

title_str = sprintf('Ordine: %s', current_order);
title(title_str, 'Angle Y (Pitch)');
%titolo del subplot

ylabel('Degrees');
xlabel('time');
   
end

%% Calcolo Ang_1.y solo per l'ordine di decomposizione ZXY 
Ang_1_ZXY = Mat2Ang_1(M_1, 'ZXY');
Ang_2_ZXY = Mat2Ang_1(M_2, 'ZXY');
% Questo mi serve per poter segmentare il segnale, perchè non posso
% prendere i dati direttamente dalla funzione

Ang_1_ZXY.y = Ang_1_ZXY.y(idx_t_validi_1);
Ang_2_ZXY.y = Ang_2_ZXY.y(idx_t_validi_2);
% Restringo il segnale nell'intervallo definito

%% BLOCCO DELLE INTERPOLAZIONI I sulla lunghezza II sui NaN
% SE NON E' NECESSARIA L'INTERPOLAZIONE RISCRIVO NEL SEGNALE RICAMPIONATO
% IL SEGNALE ESTRATTO DALLA FUNZIONE 
Ang_1_ZXY_resampled = Ang_1_ZXY.y;
Ang_2_ZXY_resampled = Ang_2_ZXY.y;

t_comm = t_1_trim;
% definisco un tempo comune, prendo il t_1_trim come reference, tanto
% t_comm viene aggiornato se i due vettori non hanno la stessa dimensione.
% se invece sono uguali va bene t_1_trim che è già uguale a t_2_trim

% SE LE LUNGHEZZE DEI SEGNALI SONO DIVERSE ALLORA FACCIO UN'INTERPOLAZIONE
% PER OTTENERE VETTORI DELLA STESSA LUNGHEZZA
if length(t_1_trim) ~= length(t_2_trim)
    disp('Lunghezza dei vettori diversa. Interpolazione su un asse temporale comune.');

    if length(t_1_trim) >= length(t_2_trim)
        t_comm = t_1_trim;
        Ang_2_ZXY_resampled = interp1(t_2_trim, Ang_2_ZXY.y, t_comm, 'linear', 'extrap');
        % Interpolo Ang_2_ZXY.y su t_comm
        % extrap serve per interpolare i valori di t_comm che sono fuori da
        % t_2_trim. Senza questo comando aggiungo solo dei NaN nei punti
        % vuoti
    else
        t_comm = t_2_trim;
        Ang_1_ZXY_resampled = interp1(t_1_trim, Ang_1_ZXY.y, t_comm, 'linear', 'extrap');
        %interpolo Ang_1_ZXY.y su t_comm
    end
else
    disp('I vettori sono della stessa dimensione e non è necessario interpolare')
end

%% II interpolazione sui NaN
% sensore1
nan_idx_1 =  isnan(Ang_1_ZXY_resampled);
if any(nan_idx_1)
    disp('Ci sono dei NaNs in Ang_1_ZXY_resempled. Interpolazione per riempire i vuoti di segnale')
    non_nan_t_1 = t_comm(~nan_idx_1);
    non_nan_ang_1 = Ang_1_ZXY_resampled(~nan_idx_1);
    %vado a prendere i valori del segnale (non NaN) ed i loro indici
    %temporali
    Ang_1_ZXY_interp = interp1(non_nan_t_1, non_nan_ang_1, t_comm, 'linear','extrap');
else
    Ang_1_ZXY_interp = Ang_1_ZXY_resampled;
    disp('Non ci sono NaNs in Ang_1_ZXY_resempled');
end

% sensore 2
nan_idx_2 = isnan(Ang_2_ZXY_resampled);
if any(nan_idx_2)
    disp('Ci sono dei NaNs in Ang_2_ZXY_resempled. Interpolazione per riempire i vuoti di segnale')
    non_nan_t_2 = t_comm(~nan_idx_2);
    non_nan_ang_2 = Ang_2_ZXY_resampled(~nan_idx_2);
    %vado a prendere i valori del segnale (non NaN) ed i loro indici
    %temporali
    Ang_2_ZXY_interp = interp1(non_nan_t_2, non_nan_ang_2, t_comm, 'linear', 'extrap');
else
    Ang_2_ZXY_interp = Ang_2_ZXY_resampled;
    disp('Non ci sono NaNs in Ang_2_ZXY_resempled')
end

%% creo la figura con il pitch dell'ordine di scomposizione ZXY
hFig3=figure('Name', 'Segmentazione ciclo del passo usando il Pitch Angle', 'NumberTitle', 'off');
% Titolo generale per l'intera finestra

%% impostazioni della figura, posizione degli oggetti, titoli, dimensioni etc.
set(gcf,'WindowState','maximized');
%per avere la figura a tutto schermo

set(gca, 'Position', [0.07 0.1 0.9 0.8]);  % [left bottom width height]
% ax = gca restituisce gli assi correnti (o la visualizzazione standalone) 
% nella figura corrente. Utilizzare ax per ottenere e impostare 
% le proprietà degli assi correnti. Se non sono presenti assi o grafici 
% nella figura corrente, gca crea un oggetto assi cartesiani.

%set(hFig3, 'Position', [100, 100, 1200, 800]);  
% imposta la dimensione della finestra per non sovrapporre i titoli

nomefile_disp=strrep(nomefile, '_', '\_'); 
% per non visualizzare gli undescore come pedici

sg3 = sgtitle(sprintf('Angolo di Pitch con ordine di scomposizione "ZXY" (File: %s)', ...
    nomefile_disp), 'Interpreter', 'tex', 'FontSize', 12, ...
    'FontWeight', 'bold', 'color','red');

%% chiamo la funzione 
[num_passi_dx, durata_passo_dx, durata_swing_dx, percent_swing_dx, ...
    durata_stance_dx, percent_stance_dx, stacco_dx, appoggio_dx, ...
    idx_stacco_dx, idx_appoggio_dx] = segmentation(t_1_trim, Ang_1_ZXY.y, 'ZXY');

[num_passi_sx, durata_passo_sx, durata_swing_sx, percent_swing_sx, ...
    durata_stance_sx, percent_stance_sx, stacco_sx, appoggio_sx, ...
    idx_stacco_sx, idx_appoggio_sx] = segmentation(t_2_trim, Ang_2_ZXY.y, 'ZXY');

%% plot dei grafici di piede destro e sinistro sovrapposti

hPitchDX = plot(t_comm, Ang_1_ZXY_interp, 'b');
hold on
hPitchSX = plot(t_comm, Ang_2_ZXY_interp, 'r'); 

grid on;
grid minor;
xlim('tight');
ylim('tight');
%restringo gli assi alla dimensione del segnale

zero_cross_neg_dx = find(diff(sign(Ang_1_ZXY_interp - Ang_1_ZXY_interp(1,1))) < 0);
zero_cross_neg_sx = find(diff(sign(Ang_2_ZXY_interp - Ang_2_ZXY_interp(1,1))) < 0);
% Recalculate zero_cross_pos for the ZXY pitch data to plot them correctly
%zero_cross_pos_dx = find(diff(sign(Ang_1_ZXY_interp - Ang_1_ZXY_interp(1,1))) > 0);
%zero_cross_pos_sx = find(diff(sign(Ang_2_ZXY_interp - Ang_2_ZXY_interp(1,1))) > 0);

t_zero_cross_dx = t_comm(zero_cross_neg_dx);
t_zero_cross_sx = t_comm(zero_cross_neg_sx);
%creo l'asse dei tempi per la linea che attraverserà i zero_cross

y_zero_cross_dx= Ang_1_ZXY_interp(zero_cross_neg_dx);
y_zero_cross_sx= Ang_2_ZXY_interp(zero_cross_neg_sx);
%creo la linea che passsera per zero_cross

hPtoZeroDX = scatter(t_comm(zero_cross_neg_dx),Ang_1_ZXY_interp(zero_cross_neg_dx), 'k*');
hPtoZeroSX = scatter(t_comm(zero_cross_neg_sx),Ang_2_ZXY_interp(zero_cross_neg_sx), 'k*');
% evidenzio gli eventi di attraversamento dello zero che mi segmentano il
% passo 
%scatter(t_comm(zero_cross_pos_dx),Ang_1_ZXY_interp(zero_cross_pos_dx), 'k*')
%scatter(t_comm(zero_cross_pos_sx), Ang_2_ZXY_interp(zero_cross_pos_sx), 'k*')

hLineDX = plot(t_zero_cross_dx, y_zero_cross_dx, 'k--');
hLineSX = plot(t_zero_cross_sx, y_zero_cross_sx, 'k--');
% linea che passa per gli attraversamenti dello zero 

hXLineDX = xline(t_zero_cross_dx, 'b:', 'LineWidth',2);
hXLineSX = xline(t_zero_cross_sx, 'r:', 'LineWidth',2);
% crea delle linee vericali per evidenziare meglio i segmenti 
% quando si usa xline MATLAB disegna una xline per ogni valore 
% e restituisce un array di handle grafici. però non si può mettere in 
% legenda più oggetti dello stesso tipo (come più xline) con un'unica etichetta.

hStaccoDX = scatter(idx_stacco_dx, interp1(t_comm, Ang_1_ZXY_interp, idx_stacco_dx), ...
    50,'blue','d','filled');
hStaccoSX = scatter(idx_stacco_sx, interp1(t_comm, Ang_2_ZXY_interp, idx_stacco_sx), ...
    50,'blue','d','filled');
% evidenzio gli eventi di Toe Off, ovvero il distacco del piede 

hAppoggioDX = scatter(idx_appoggio_dx, interp1(t_comm, Ang_1_ZXY_interp, idx_appoggio_dx), ...
    50,'red','o','filled');
hAppoggioSX = scatter(idx_appoggio_sx, interp1(t_comm, Ang_2_ZXY_interp, idx_appoggio_sx), ...
    50,'red','o','filled');
% evidenzio gli eventi di Heel Strike, ovvero l'appoggio del piede

title('Angle Y (Pitch) piede destro e sinistro');
ylabel('Degrees','FontWeight', 'bold');
xlabel('time','FontWeight', 'bold');
% titolo del subplot e degli assi

lgd = legend([hPitchDX, hPitchSX, hPtoZeroDX, hPtoZeroSX, ...
              hLineDX, hLineSX, hXLineDX(1), hXLineSX(1), ...
              hStaccoDX, hStaccoSX, hAppoggioDX, hAppoggioSX], ...
    {'pitch DX', 'pitch SX', 'zero-cross DX', 'zero-cross SX', ...
     'Zero-Crossing line DX', 'Zero-Crossing line SX', ...
     'xline DX (segmento)', 'xline SX (segmento)', ...
     'stacco DX', 'stacco SX', ...
     'appoggio DX', 'appoggio SX'}, ...
     'Location', 'northeastoutside');
% hXLineDX(1), hXLineSX(1) guarda commento di xline
lgd.Title.String = 'Legend';


%% Creo una tabella dove visualizzare i dati
% disp(['Size of Passo_Foot: ', mat2str(size(num_passi_foot))]);
% disp(['Size of durata_passo_foot: ', mat2str(size(durata_passo_foot))]);
% disp(['Size of durata_swing_foot: ', mat2str(size(durata_swing_foot))]);
% disp(['Size of percent_swing_foot: ', mat2str(size(percent_swing_foot))]);
% disp(['Size of durata_stance_foot: ', mat2str(size(durata_stance_foot))]);
% disp(['Size of percent_stance_foot: ', mat2str(size(percent_stance_foot))]);
% queste righe sono per controllare se i miei dati sono organizzari in riga
% o colonna per poterle mettere nella tabella

% PIEDE DX
if ~isempty(durata_passo_dx)
   Passo_DX = (1:length(durata_passo_dx))'; 
   % assegno ad ogni passo una posizione
Tabella_DX = table(Passo_DX, durata_passo_dx', durata_swing_dx, ...
   percent_swing_dx, durata_stance_dx, percent_stance_dx, ...
   'VariableNames', {'Passo', 'Durata_Passo_s', 'Durata_Swing_s', ...
   'Percent_Swing', 'Durata_Stance_s', 'Percent_Stance'});
disp(' '); 
% Add an empty line for better readability in the command window
disp('Tabella Durata Passi Piede Destro:');
disp(Tabella_DX);
else
   disp(' ');
   disp('Nessun passo valido rilevato per il piede destro.');
end

% PIEDE SX
if ~isempty(durata_passo_sx)
   Passo_SX = (1:length(durata_passo_sx))'; 
Tabella_SX = table(Passo_SX, durata_passo_sx', durata_swing_sx, ...
   percent_swing_sx, durata_stance_sx, percent_stance_sx, ...
   'VariableNames', {'Passo', 'Durata_Passo_s', 'Durata_Swing_s', ...
   'Percent_Swing', 'Durata_Stance_s', 'Percent_Stance'});
disp(' '); 
% Add an empty line
disp('Tabella Durata Passi Piede Sinistro:');
disp(Tabella_SX);
else
   disp(' ');
   disp('Nessun passo valido rilevato per il piede sinistro.');
end

%