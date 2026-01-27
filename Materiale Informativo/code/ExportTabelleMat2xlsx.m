clc
close all
clear all
clearvars

%% Directory
addpath('C:\Users\Hp\Desktop\Nuova cartella')

cd('C:\Users\Hp\Desktop\Nuova cartella\img\pazienti\paziente.2\acquisizione 05.09\ORTESI_S_arto_paretico(dx)\variabili');

%% === Esportazione tabelle da file .mat a Excel ===
% Nome del file .mat
nomeFileMat = 'GaitAnalysisData_MT_012100F3_003.mat';

% Carica il contenuto del file .mat
data = load(nomeFileMat);

% Mostra i nomi delle variabili presenti
disp('Variabili presenti nel file:')
disp(fieldnames(data))

%% Cartella di destinazione
output_data_folder = 'C:\Users\Hp\Desktop\Nuova cartella\TabelleExcel\paziente.2\acquisizione 05.09\ORTESI_S_arto_paretico(dx)'; % <-- Modifica percorso se serve

% Crea la cartella se non esiste
if ~exist(output_data_folder, 'dir')
    mkdir(output_data_folder);
end

%% Nome del file Excel unico (richiama il nome del .mat)
[~, baseName, ~] = fileparts(nomeFileMat);
excelNameUnico = sprintf('%s.xlsx', baseName);
fullExcelPath = fullfile(output_data_folder, excelNameUnico);

%% Individua automaticamente le variabili di tipo table
nomiVariabili = fieldnames(data);
isTab = structfun(@(x) istable(x), data);
nomiTabelle = nomiVariabili(isTab);

if isempty(nomiTabelle)
    error('Nessuna variabile di tipo table trovata nel file.');
end

%% Esporta in un unico file Excel con un foglio per ogni tabella
for k = 1:numel(nomiTabelle)
    writetable(data.(nomiTabelle{k}), fullExcelPath, 'Sheet', nomiTabelle{k});
end

disp(['Tabelle esportate nel file: ' fullExcelPath]);
