%
function [segmented_signal] = segmentSignalWithIDX (signal, start_idx, end_idx)
%Questa funzione mi serve a segmentare i segnali usando gli indici di
%segmentazione che ho estratto dal pitch del piede

if length(start_idx) ~= length(end_idx)
    error (['gli indici di inizio e fine non hanno la stessa lunghezza, ...' ...
        'ovvero un passo inizia e non finisce o finisce senza aver inizato'])
end

num_sements = length (start_idx);
% devono esserci n segmenti per quanti sono gli indici di start dei passi

segmented_signal = cell(num_sements, 1);
%creo un cell array che conterrà ogni singolo segmento del segnale 

target_samples = 100;
%definisco il numer di campioni che deve avere ogni segmento

for i = 1: num_sements
    idx_inizio = start_idx(i);
    idx_fine = end_idx(i);

    if idx_inizio > length(signal) || idx_fine > length(signal) || idx_inizio < 1 || idx_fine < 1
        warning(['Segment %d: Idx [%d, %d] sono fuori dai limiti di ...' ...
            'lunghezza del segnale %d. Salta il segmento.'], ...
             i, idx_inizio, idx_fine, length(signal));
            segmented_signal{i} = []; 
            % Store an empty array or handle as appropriate
            continue;
    end

% Estrazione del segmento originale 
current_segment = signal (idx_inizio:idx_fine);

if length (current_segment)<2
    warning (['Segmento %d: Il segmento è troppo corto (%d campioni)...' ...
        ' per essere interpolato. Salto il segmento.'], i, length(current_segment));
    
    segment_signal{i} = []; 
    continue;
elseif length(current_segment) == target_samples
     segmented_signal{i} = current_segment; 
     % Non serve interpolare
else
    %% interpolazione del segmento a 100 campioni 
    original_pts = 1 : length(current_segment);
    % creo una specie di asse temporale che contenga il numero di punti di
    % ogni segmento in modo da poterlo interpolare con il target di 100
    % campioni
    
    new_pts = linspace(1, length(current_segment), target_samples);
    % y = linspace(x1,x2,n) generates n points betwin x1 and x2. 
    % The spacing between the points is (x2-x1)/(n-1).

    segment_interp = interp1(original_pts, current_segment, new_pts, ...
        'linear', 'extrap');
    %faccio l'interpolazione

    segmented_signal{i} = segment_interp (:)';
    % il : mette i vettori in colonna indipendentemente da come siano
    % orientati ed il trasposto lo mette in riga. In realtà la funzione già
    % restituiva un cell array di N righe quanti sono i segmenti ed 1
    % colonna. ogni riga contiene un vettore di 1x100 (dimensione del
    % segmento). però questa imposizione manuale non lascia spazio ai dubbi
end 
end
end
%
%

