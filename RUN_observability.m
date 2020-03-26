figstart = 100;

%% Estimate NMAC | VMD
figure(figstart+1);  hold on;

sigmas = [99 121.6 130.4]; % Two-aircraft standard deviation (assuming indepdent error) - values from ASARP/ICAO
alt_ft = [1200 3000 18000];

vmdVec_ft = [0:1:500];
vNMACDef_ft = 100;

pNMAC = zeros(size(vmdVec_ft));
for si = 1:numel(sigmas)
for vi = 1:numel(vmdVec_ft)

    % Use ERF function (assuming gaussian noise)
    if(vmdVec_ft(vi) > vNMACDef_ft)
       % Sum  
       X = [(vmdVec_ft(vi) + vNMACDef_ft)];        
       Y = [(vmdVec_ft(vi) - vNMACDef_ft)];        
       pNMAC(vi) = erfc(Y / (sqrt(2) * sigmas(si)))/2 - ...
           erfc(X / (sqrt(2) * sigmas(si)))/2;
    else
       X = abs(vmdVec_ft(vi) + vNMACDef_ft);        
       Y = abs(vmdVec_ft(vi) - vNMACDef_ft);        
       pNMAC(vi) = 1 - (erfc((X) / (sqrt(2) * sigmas(si)))/2 + ...
           erfc((Y) / (sqrt(2) * sigmas(si)))/2);
    end
end
plot(vmdVec_ft, pNMAC)
lgs{si} = ['\sigma: ' num2str(sigmas(si))];
lgs{si} = ['Altitude: ' num2str(alt_ft(si))];
end
grid on
xlabel('Observed VMD (ft)');
ylabel('p(NMAC | VMD Observed)')

legend(lgs)
title(sprintf('Altimetry error impacts on NMAC when vertical dimension = %0.1f\n',vNMACDef_ft))

%% EstimatepsNMAC | VMD
figure(figstart+2); hold on;

sigmas = [10 20 40 80]; % Two-aircraft standard deviation (assuming indepdent error)

vmdVec_ft = [0:1:50];
vNMACDef_ft = 20;

pNMAC = zeros(size(vmdVec_ft));
for si = 1:numel(sigmas)
for vi = 1:numel(vmdVec_ft)

    % Use ERF function (assuming gaussian noise)
    if(vmdVec_ft(vi) > vNMACDef_ft)
       % Sum  
       X = [(vmdVec_ft(vi) + vNMACDef_ft)];        
       Y = [(vmdVec_ft(vi) - vNMACDef_ft)];        
       pNMAC(vi) = erfc(Y / (sqrt(2) * sigmas(si)))/2 - ...
           erfc(X / (sqrt(2) * sigmas(si)))/2;
    else
       X = abs(vmdVec_ft(vi) + vNMACDef_ft);        
       Y = abs(vmdVec_ft(vi) - vNMACDef_ft);        
       pNMAC(vi) = 1 - (erfc((X) / (sqrt(2) * sigmas(si)))/2 + ...
           erfc((Y) / (sqrt(2) * sigmas(si)))/2);
    end
end
plot(vmdVec_ft, pNMAC)
lgs{si} = ['\sigma: ' num2str(sigmas(si)/2) ' ft']; % Divide by 2 to convert to single aircraft sigma
end
grid on
xlabel('Observed VMD (ft)');
ylabel('p(sNMAC | VMD Observed)')

legend(lgs)
title(sprintf('Altimetry error impacts on sNMAC when vertical dimension = %0.1f\n',vNMACDef_ft))