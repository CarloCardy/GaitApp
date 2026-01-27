function [Angoli_interp, t_comm] = interpolaSegnali(Angoli, Tempi)
% INTERPOLASEGNALI esegue l'interpolazione di angoli su un asse temporale comune
% e gestisce i valori NaN.
%
%   INPUTS:
%   - Angoli: una cell array contenente i segnali di angolo (es. {Ang_1.y, Ang_2.y, Ang_3.y}).
%   - Tempi: una cell array contenente i vettori temporali corrispondenti (es. {t_1_trim, t_2_trim, t_3_trim}).
%
%   OUTPUTS:
%   - Angoli_interp: una cell array contenente i segnali interpolati e privi di NaN.
%   - t_comm: il vettore temporale comune utilizzato per l'interpolazione.

    % Controllo degli input
    if length(Angoli) ~= length(Tempi)
        error('Il numero di segnali e vettori temporali deve essere lo stesso.');
    end

    % Trova il vettore temporale più lungo
    lunghezze = cellfun(@length, Tempi);
    [~, idx_max] = max(lunghezze);
    t_comm = Tempi{idx_max};
    
    % Inizializza l'output
    num_segnali = length(Angoli);
    Angoli_resampled = cell(1, num_segnali);
    Angoli_interp = cell(1, num_segnali);

    % BLOCCO I: INTERPOLAZIONE SU ASSE TEMPORALE COMUNE
    disp('Controllo lunghezze dei segnali e interpolazione su asse comune...');
    
    segnali_diversi = false;
    for i = 1:num_segnali
        if ~isequal(Tempi{i}, t_comm)
            segnali_diversi = true;
            break;
        end
    end

    if segnali_diversi
        for i = 1:num_segnali
            if ~isequal(Tempi{i}, t_comm)
                Angoli_resampled{i} = interp1(Tempi{i}, Angoli{i}, t_comm, 'linear', 'extrap');
            else
                Angoli_resampled{i} = Angoli{i};
            end
        end
        disp('Lunghezza dei segnali diversa. Interpolazione su un asse temporale comune completata.');
    else
        for i = 1:num_segnali
            Angoli_resampled{i} = Angoli{i};
        end
        disp('I segnali sono della stessa dimensione e non è necessario interpolare.');
    end
    
    % BLOCCO II: INTERPOLAZIONE SUI VALORI NaN
    disp('Controllo e interpolazione dei valori NaN...');
    
    for i = 1:num_segnali
        nan_idx = isnan(Angoli_resampled{i});
        if any(nan_idx)
            disp(['Ci sono dei NaNs nel segnale ', num2str(i), '. Interpolazione per riempire i vuoti.']);
            non_nan_t = t_comm(~nan_idx);
            non_nan_ang = Angoli_resampled{i}(~nan_idx);
            Angoli_interp{i} = interp1(non_nan_t, non_nan_ang, t_comm, 'linear', 'extrap');
        else
            Angoli_interp{i} = Angoli_resampled{i};
            disp(['Non ci sono NaNs nel segnale ', num2str(i), '.']);
        end
    end
    disp('Interpolazione dei NaN completata per tutti i segnali.');

end