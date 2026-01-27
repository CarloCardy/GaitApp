%
function [Ang] = Mat2Ang_1 (M, type)

% X=ROLL | Y=PITCH | Z=YAW

% e = 1-1e-6;
e = 0.99999;
pi2=pi/2;

for i=1:size(M,3)

    Mat = M(:,:,i);

    % Estrae gli elementi dalla matrice Mat
    Mat11 = Mat(1,1); Mat12 = Mat(1,2); Mat13 = Mat(1,3);
    Mat21 = Mat(2,1); Mat22 = Mat(2,2); Mat23 = Mat(2,3);
    Mat31 = Mat(3,1); Mat32 = Mat(3,2); Mat33 = Mat(3,3);
     switch type
    
        case "ZYX" % YAW/PITCH/ROLL
%             Ang.x(1,i)=rad2deg(atan2(Mat21,Mat11)); %Ang.x--> yaw
% %             Ang.y(1,i)=rad2deg(atan2(-Mat31,sqrt(Mat32.^2+Mat33.^2))); %Ang.y --> pitch
%             Ang.y(1,i)=rad2deg(atan2(-Mat31,sqrt(1-Mat31^2)));  %Ang.y --> pitch
%             Ang.z(1,i)=rad2deg(atan2(Mat32,Mat33)); %Ang.z-->roll

            if (abs(Mat31) > e)
                Ang.x(1,i) = rad2deg(0);
                Ang.z(1,i) = rad2deg(atan2(Mat23, Mat13));
                Ang.y(1,i) = rad2deg(pi2 * sign(Mat31));
            else
                Ang.z(1,i) = rad2deg(atan2(Mat21, Mat11));
                Ang.y(1,i) = rad2deg(asin(-Mat31));
%                 Ang.y2(1,i) = rad2deg(atan2(-Mat31,sqrt(1-Mat31^2)));  %Ang.y --> pitch
                Ang.x(1,i) = rad2deg(atan2(Mat32, Mat33));
            end
    
        case "XZY"

            if (abs(Mat12) > e)
                Ang.x(1,i) = rad2deg(atan2(Mat31,Mat21));
                Ang.z(1,i) = rad2deg(-pi2 * sign(Mat12));
                Ang.y(1,i) = rad2deg(0);
            else
                Ang.y(1,i) = rad2deg(atan2(Mat13,Mat11));
                Ang.x(1,i) = rad2deg(atan2(Mat32,Mat22));
                Ang.z(1,i) = rad2deg(asin(-Mat12));
            end

       case "XYZ"
    
            if (abs(Mat13) > e)
                Ang.x(1,i) = rad2deg(atan2(Mat21, -Mat31));
                Ang.z(1,i) = rad2deg(0);
                Ang.y(1,i) = rad2deg(pi2 * sign(Mat13));
            else
                Ang.z(1,i) = rad2deg(atan2(-Mat12, Mat11));
                Ang.y(1,i) = rad2deg(asin(Mat13));
                Ang.x(1,i) = rad2deg(atan2(-Mat23, Mat33));
            end


       case "YXZ"
    
            if (abs(Mat23) > e)
                Ang.x(1,i) = rad2deg(pi2 * sign(Mat23));
                Ang.z(1,i) = rad2deg(0);
                Ang.y(1,i) = rad2deg(atan2(Mat12, Mat32));
            else
                Ang.z(1,i) = rad2deg(atan2(Mat21, Mat22));
                Ang.y(1,i) = rad2deg(atan2(Mat13, Mat33));
                Ang.x(1,i) = rad2deg(asin(-Mat23));
            end    
    
    case "YZX"
    
            if (abs(Mat21) > e)
                Ang.x(1,i) = rad2deg(0);
                Ang.z(1,i) = rad2deg(pi2 * sign(Mat21));
                Ang.y = rad2deg(atan2(Mat13, -Mat12));
            else
                Ang.z(1,i) = rad2deg(asin(Mat21));
                Ang.y(1,i) = rad2deg(atan2(-Mat31, Mat11));
                Ang.x(1,i) = rad2deg(atan2(-Mat23, Mat22));
            end

    case "ZXY"
    
            if (abs(Mat32) > e)
                Ang.y(1,i) = rad2deg(0);
                Ang.z(1,i) = rad2deg(atan2(Mat13, -Mat23));
                Ang.x(1,i) = rad2deg(pi2 * sign(Mat32));
            else
                Ang.z(1,i) = rad2deg(atan2(-Mat12, Mat22));
                Ang.y(1,i) = rad2deg(atan2(-Mat31, Mat33));
                Ang.x(1,i) = rad2deg(asin(Mat32));
            end

    end
end

%
%