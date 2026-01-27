function Ang = Mat2Ang_intrinseca(M, type)
% Mat2Ang_intrinseca
% Calcola gli angoli di Tait–Bryan (intrinseci) a partire da una matrice di rotazione.
% INPUT:
%   M    - matrice di rotazione 3x3xN
%   type - stringa con ordine intrinseco: 'XYZ', 'XZY', 'YXZ', 'YZX', 'ZXY', 'ZYX'
% OUTPUT:
%   Ang  - struct con campi:
%            .alpha  -> rotazione attorno al primo asse (in gradi)
%            .beta   -> rotazione attorno al secondo asse (in gradi)
%            .gamma  -> rotazione attorno al terzo asse (in gradi)
%
% Nota: ordine intrinseco 'ABC' = ordine estrinseco 'CBA'

    % Tolleranza per il gimbal lock
    e   = 0.99999;
    pi2 = pi/2;

    % Conversione ordine intrinseco in ordine estrinseco inverso
    % (per usare le stesse formule della versione estrinseca)
    type_ext = reverse(type);

    % Preallocazione
    N = size(M,3);
    alpha = zeros(1,N);
    beta  = zeros(1,N);
    gamma = zeros(1,N);

    for i = 1:N
        Mat = M(:,:,i);

        % Estrazione elementi
        M11 = Mat(1,1); M12 = Mat(1,2); M13 = Mat(1,3);
        M21 = Mat(2,1); M22 = Mat(2,2); M23 = Mat(2,3);
        M31 = Mat(3,1); M32 = Mat(3,2); M33 = Mat(3,3);

        switch type_ext
            case "ZYX" % intrinseco XYZ
                if abs(M31) > e
                    beta(i)  = rad2deg(pi2 * sign(-M31));
                    alpha(i) = rad2deg(atan2(M12, M13));
                    gamma(i) = 0;
                else
                    alpha(i) = rad2deg(atan2(M32, M33));  % rot. attorno primo asse
                    beta(i)  = rad2deg(asin(-M31));       % rot. attorno secondo asse
                    gamma(i) = rad2deg(atan2(M21, M11));  % rot. attorno terzo asse
                end

            case "XZY" % intrinseco YZX
                if abs(M12) > e
                    beta(i)  = rad2deg(-pi2 * sign(M12));
                    alpha(i) = rad2deg(atan2(M31, M21));
                    gamma(i) = 0;
                else
                    beta(i)  = rad2deg(asin(M12));
                    alpha(i) = rad2deg(atan2(-M32, M22));
                    gamma(i) = rad2deg(atan2(-M13, M11));
                end

            case "XYZ" % intrinseco ZYX
                if abs(M13) > e
                    beta(i)  = rad2deg(pi2 * sign(M13));
                    alpha(i) = rad2deg(atan2(M21, -M31));
                    gamma(i) = 0;
                else
                    beta(i)  = rad2deg(asin(M13));
                    alpha(i) = rad2deg(atan2(-M23, M33));
                    gamma(i) = rad2deg(atan2(-M12, M11));
                end

            case "YXZ" % intrinseco ZXY
                if abs(M23) > e
                    beta(i)  = rad2deg(pi2 * sign(M23));
                    alpha(i) = 0;
                    gamma(i) = rad2deg(atan2(M12, M32));
                else
                    beta(i)  = rad2deg(asin(-M23));
                    alpha(i) = rad2deg(atan2(M13, M33));
                    gamma(i) = rad2deg(atan2(M21, M22));
                end

            case "YZX" % intrinseco XZY
                if abs(M21) > e
                    beta(i)  = rad2deg(pi2 * sign(M21));
                    alpha(i) = 0;
                    gamma(i) = rad2deg(atan2(M13, -M12));
                else
                    beta(i)  = rad2deg(asin(M21));
                    alpha(i) = rad2deg(atan2(-M23, M22));
                    gamma(i) = rad2deg(atan2(-M31, M11));
                end

            case "ZXY" % i
