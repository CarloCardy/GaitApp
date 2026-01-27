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

cd('C:\Users\Hp\Desktop\Nuova cartella\acquisizioni.2\test allineamento');
% cd = change directory per accedere alla cartella in cui sono contenuti i
% file 
file_name = 'MT_012100F3_000.mtb'; 
%questa variabile mi serve per il titolo delle figure

sensore_1 = importdata ('MT_012100F3_000-000_00B4CAF0.txt');
sensore_2 = importdata ('MT_012100F3_000-000_00B4CBA7.txt');
sensore_3 = importdata ('MT_012100F3_000-000_00B4CB9F.txt');

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
time = 1 : length(time_1); 
% creo un vettore speculare al packet counter come numero di campioni

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
t_fine = 10.25;
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

ver_1 = Ang_1_ZXY.y - Ang_2_ZXY.y
ver_2 = Ang_2_ZXY.y - Ang_3_ZXY.y
ver_3 = Ang_1_ZXY.y - Ang_3_ZXY.y

ver_1_mean = mean(ver_1)
ver_2_mean = mean(ver_2)
ver_3_mean = mean(ver_3)