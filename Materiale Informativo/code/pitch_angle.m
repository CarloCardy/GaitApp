function [Ang] = pitch_angle(M, type)
% La funzione mi deve restituire una figure contenente alpha, beta, gamma,
% che sono gli angoli di rotazione attorno a X, Y, Z rispettivamente 

for i=1:size(M,3)

    Mat = M(:,:,i);

    % Estrae gli elementi dalla matrice Mat
    Mat11 = Mat(1,1); Mat12 = Mat(1,2); Mat13 = Mat(1,3);
    Mat21 = Mat(2,1); Mat22 = Mat(2,2); Mat23 = Mat(2,3);
    Mat31 = Mat(3,1); Mat32 = Mat(3,2); Mat33 = Mat(3,3);
     switch type

    case "XYZ"
        alpha = squeeze(rad2deg(atan2(M_1(3,2,:), M_1(3,3,:))));
      

        beta = squeeze(rad2deg(asin(-M_1(3,1,:))));
        

        gamma = squeeze(rad2deg(atan2(M_1(2,1,:), M_1(1,1,:))));
        
    case "XZY"
        alpha = squeeze(rad2deg(atan2(-M_1(2,3,:), M_1(2,2,:))));
       
        
        beta = squeeze(rad2deg(asin(M_1(2,1,:))));
        
        
        gamma = squeeze(rad2deg(atan2(-M_1(3,1,:), M_1(1,1,:))));
        
    case "YXZ"
        alpha = squeeze(rad2deg(atan2(-M_1(3,1,:), M_1(3,3,:))));
       
        beta = squeeze(rad2deg(asin(M_1(3,2,:))));

        gamma = squeeze(rad2deg(atan2(-M_1(1,2,:), M_1(2,2,:))));
       
    case "YZX"
        alpha = squeeze(rad2deg(atan2(M_1(1,3,:), M_1(1,1,:))));
        

        beta = squeeze(rad2deg(asin(-M_1(1,2,:))));
        

        gamma = squeeze(rad2deg(atan2(-M_1(3,2,:), M_1(2,2,:))));
        
    case "ZXY"
        alpha = squeeze(rad2deg(atan2(M_1(2,1,:), M_1(2,2,:))));
        
        
        beta = squeeze(rad2deg(asin(-M_1(2,3,:))));
       
        
        gamma = squeeze(rad2deg(atan2(M_1(1,3,:), M_1(3,3,:))));
        
    case "ZYX"
        alpha = squeeze(rad2deg(atan2(-M_1(1,2,:), M_1(1,1,:))));
        
        
        beta = squeeze(rad2deg(asin(M_1(1,3,:))));
        

        gamma = squeeze(rad2deg(atan2(-M_1(2,3,:), M_1(3,3,:))));
        
    otherwise
        error('Unsupported ORDTYPE: %s. Supported types are XYZ, XZY, YXZ, YZX, ZXY, ZYX.', ORDTYPE);
end

end
%