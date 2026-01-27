%
function [num_passi, durata_passo, segmento, idx_passi_validi, durata_swing, percent_swing, durata_stance, percent_stance, stacco, appoggio, idx_stacco, idx_appoggio, zero_cross_pos, zero_cross_neg] = segmentation (t, Ang_y_input, type)

%% allineamento 
Ang_y_input=Ang_y_input-Ang_y_input(1,1);
% questo passaggio mi permette di annullare l'inclinazione iniziale del
% sensore da tutti i valori successivi è come se allineassi a zero il
% sensore 


%% Definisco il tempo di campionamento 
t_c= t(2)-t(1);

%% trovo gli indici di attraversamenti per lo zero
zero_cross_pos = find(diff(sign(Ang_y_input))> 0);
% da - a +

zero_cross_neg = find (diff(sign(Ang_y_input))<0);
% da + a -
%sign mi restituisce solo il segno della funzione pitch campione per
%campione. 
%diff corrisponde agli eventi di inversione del pitch da - a + e da + a - 
%find li trova come indici

%% vado a segmentare il segnale per dividerlo in singoli passi
% Devo segmentare da appoggio ad appoggio e per farlo devo individuarli
% correttamente. In genere un appoggio é associato al picco massimo del
% segnale di pitch. Devo individuare i masssimi locali nel segnale 

% Trovo i massimi locali (Heel Strike)
% Prominence è un buon parametro per filtrare i picchi significativi
[pks_appoggio, locs_appoggio] = findpeaks(Ang_y_input, 'MinPeakProminence', 20, 'MinPeakDistance', 0.2/t_c);
% 'MinPeakProminence' può essere aggiustata in base all'ampiezza tipica
% dei picchi di appoggio. 20 è un valore di riferimento che dovrebbe andar 
% bene per tutti gli individui.
% 'MinPeakDistance' assicura che i picchi non siano troppo vicini,
% il che è utile per evitare più rilevazioni per lo stesso evento.
% 0.5 secondi è una stima per la distanza minima tra due appoggi. 
% viene messo 0.2 perchè con il miglioramento dei pazienti il tempo tra un
% passo e l'altro diminuisce
% Converto in numero di campioni dividendo per il tempo di campionamento.

% Mi assicuro che ci siano almeno due appoggi per definire un passo, perché
% é caitato che si scollegassero i sensori durante l'acquisizione e si
% perdessero quasi tutti i dati
if length(locs_appoggio) < 2
    disp('Meno di 2 eventi di appoggio significativi rilevati. Impossibile segmentare i passi.');
% Inizializza tutte le variabili di output come vuote o zero

    num_passi = {};
% Inizializzo una cell array per memorizzare i segmenti che andranno a
% rappresentare i miei passi
% Un cell array è un tipo di dati con contenitori di dati indicizzati 
% denominati celle, in cui ogni cella può contenere qualsiasi tipo di dati.

    durata_passo = [];
    segmento = {};
    idx_passi_validi = {};
    durata_swing = [];
    percent_swing = [];
    durata_stance = [];
    percent_stance = [];
    stacco = [];
    appoggio = [];
    idx_stacco = [];
    idx_appoggio = [];
    zero_cross_pos = []; % Aggiunto per inizializzare
    zero_cross_neg = []; % Aggiunto per inizializzare
    return; % Termina la funzione
end

%% Segmento il segnale da Appoggio ad Appoggio
% Ogni passo inizia con un appoggio e finisce con l'appoggio successivo.
passi_tmp = {};
% Inizializzo una cell array temporanea perchè devo vedere se ci sono passi
% non validi, così posso salvare solo i passi validi. 

idx_passi_validi = {};

%% CALCOLO ANCHE LA DURATA DEI PASSI
% creo un vettore zero che conterrà le durate dei passi 
durata_passo = [];
%creo un vettore indicizzato a zero che memorizzerà il tempo di quei
%segmenti di segnale troppo brevi per essere considerati passi 
durata_accumulata = 0; 
% Per gestire segmenti brevi (non dovrebbe succedere spesso qui)

% ciclo sugli indici degli appoggi per definire i segmenti dei passi
for i = 1:length(locs_appoggio) - 1
    idx_inizio = locs_appoggio(i);
    idx_fine = locs_appoggio(i+1);

% Controllo per evitare errori di indice, nel caso sforino la lunghezza
% del vettore t
    if idx_fine > length(t) || idx_inizio > length(t)
        disp(['Indice fuori limite al passo ', num2str(i)]);
        continue;
    end

%% Calcolo la durata del passo
    t_passo = t(idx_fine) - t(idx_inizio);

% Controllo durata dei passi (un passo da appoggio ad appoggio è tipicamente > 0.6 s)
    if t_passo < 0.2  
        % soglia minima per un passo completo
        
        disp(['Durata troppo breve per essere considerato un passo valido ...' ...
            '(appoggio-appoggio), al segmento ', num2str(i)]);
        durata_accumulata = durata_accumulata + t_passo;
        continue;
    end

% Se il passo è valido, sommo la durata accumulata (se presente)
    t_passo = t_passo + durata_accumulata;
    durata_accumulata = 0; % Resetta l'accumulo

% Salvo il segmento valido e i suoi indici
    passi_tmp{end+1} = Ang_y_input(idx_inizio:idx_fine);
    idx_passi_validi{end+1} = [idx_inizio, idx_fine];
    durata_passo(end+1) = t_passo;
end

if ~isempty(passi_tmp)
% ~isempty è un controllo, serve per controllare che le variabili non siano
% vuote
    num_passi = passi_tmp';
else
    num_passi = {}; 
% Restituisci cell array vuoto se nessun passo valido
end

%% Trovo TOE OFF ED HEEL STRIKE in ogni segmento 
% picco positivo = massimo =  heel strike = appoggio
% picco negativo = minimo = toe off = stacco 
% In un segmento da Appoggio ad Appoggio:
% - L'inizio del segmento è l'Heel Strike (Appoggio).
% - Il picco minimo nel segmento è il Toe Off (Stacco).
% - La fine del segmento è l'Heel Strike (Appoggio) successivo.

%definisco dei vettori (con all'interno n zeri quanti sono i passi)
%all'interno dei quali verranno registrati gli eventi di toe off ed heel
%strike (devo mettere length perchè num_passi è un cell array che per
%costruzione non è composto da numeri)

num_valid_steps = length(durata_passo); 
% devo inserire questa variabile per passare da un cell array ad un 
% vettore numerico 

if num_valid_steps > 0
stacco = zeros(num_valid_steps,1);
appoggio = zeros(num_valid_steps,1);

% YOU NEED TO KEEP track of the time values, not the indices of max/min *within the segment*
% These will store the *time* of the event,
tempo_stacco_event = zeros(num_valid_steps,1);
tempo_appoggio_event = zeros(num_valid_steps,1);

%% Calcolo anche la percentuale di swing e di stance 
% stance=durata tra appoggio e stacco (da picco positivo a negativo)
% swing=durata tra stacco e appoggio (da picco negativo a positivo)

segmento = cell(num_valid_steps,1);
durata_swing = zeros(num_valid_steps,1);
percent_swing = zeros(num_valid_steps,1);
durata_stance = zeros(num_valid_steps,1);
percent_stance = zeros(num_valid_steps,1);

% creo un ciclo grande che consderi uno alla volta i passi 
for i=1:num_valid_steps
   idx_inizio = idx_passi_validi{i}(1);
   idx_fine = idx_passi_validi{i}(2);
   %indicizzo il cell array degli indici in modo che il primo sia di inzio
   %passo ed il successivo di fine 

    % Segmento di pitch e tempo
    segmento{i}  = Ang_y_input(idx_inizio:idx_fine);
    tempo_segmento = t(idx_inizio:idx_fine);
   
% L'Appoggio (Heel Strike) per questo passo è l'inizio del segmento
% e l'Appoggio (Heel Strike) successivo è la fine del segmento.
%% Prendo il valore Ang_y_input all'inizio del segmento per l'appoggio.
        appoggio(i) = Ang_y_input(idx_inizio);
        tempo_appoggio_event(i) = t(idx_inizio); 
% Tempo dell'Heel Strike iniziale

%% Trovo il minimo locale (Toe Off) all'interno del segmento
        [valore_min, idx_min_local] = min(segmento{i});
        stacco(i) = valore_min; % Valore angolare al Toe Off
        tempo_stacco_event(i) = tempo_segmento(idx_min_local); 
% Tempo del Toe Off

%% Calcolo delle durate e percentuali
% Stance: dal Heel Strike iniziale al Toe Off
% Swing: dal Toe Off al Heel Strike successivo (fine segmento)

%% Durata della fase di STANCE (appoggio)
% In un ciclo HS-HS, la stance è la fase dal HS all'evento di Toe-Off.
% La logica è: HS (inizio segmento) -> TO (minimo locale)
        if tempo_stacco_event(i) > tempo_appoggio_event(i)
            durata_stance(i) = tempo_stacco_event(i) - tempo_appoggio_event(i);
        else
% Questo caso non dovrebbe verificarsi se il TO è sempre dopo il HS iniziale.
            disp(['Attenzione: Toe Off prima dell''Heel Strike iniziale per il passo ', num2str(i)]);
            durata_stance(i) = 0; 
% O gestisci diversamente
        end

 percent_stance(i) = (durata_stance(i) / durata_passo(i)) * 100;

%% Durata della fase di SWING (oscillazione)
% La swing è la fase dal Toe Off al Heel Strike successivo (fine del segmento).
        durata_swing(i) = t(idx_fine) - tempo_stacco_event(i);
        percent_swing(i) = (durata_swing(i) / durata_passo(i)) * 100;

% Un controllo per assicurarsi che la somma delle durate sia il passo totale
        if abs((durata_stance(i) + durata_swing(i)) - durata_passo(i)) > 1e-6
            disp(['Avviso: la somma Stance+Swing non corrisponde alla durata totale del passo per il passo ', num2str(i)]);
        end
    end
else
    
% Se non ci sono passi validi, inizializza tutte le variabili di output
    stacco = [];
    appoggio = [];
    durata_swing = [];
    percent_swing = [];
    durata_stance = [];
    percent_stance = [];
    tempo_stacco_event = [];
    tempo_appoggio_event = [];
    segmento = {};
end
idx_stacco = tempo_stacco_event;
idx_appoggio = tempo_appoggio_event; 
% Questo ora rappresenta il tempo del *primo* appoggio di ogni passo.
end
   