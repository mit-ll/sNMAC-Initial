%% Inputs
simCase = 5; % Use case and variables set using setParameters(simCase)
rng(42); % Set random seed for reproducibility

%% Warn about potential MATLAB version
[~, d] = version;
if datetime(d) < datetime(2018,9,5)
    warning('sNMAC:matlabversion','Code developed using R2018a released on 2018-09-05...you are using an older version of MATLAB\n');
end

%% Set parameters
params = setParameters(simCase);
figstart = simCase*10; % Starting figure number

%% Extract variables from output to local workspace
fn = fieldnames(params);
for i = 1:numel(fn)
    assignin('caller', fn{i}, params.(fn{i}));
end

%% Sample initial speed, vertical rate, and position
% Sample initial speed
s0_fps = rand([numEnc 1]) * speedRange_fps + minSpeed_fps; % Speed of aircraft 1
s1_fps = rand([numEnc 1]) * speedRange_fps + minSpeed_fps; % Speed of aircraft 2

% Sample initial vertical rate
dh0_fps = 2*(rand([numEnc 1]) - 0.5) * dhRange_fps; % Vertical rate of aircraft 1
dh1_fps = 2*(rand([numEnc 1]) - 0.5) * dhRange_fps; % Vertical rate of aircraft 2

% Initial heading
heading0_deg = 2*(rand([numEnc 1]) - 0.5) * rad2deg(pi); % Heading of aircraft 1
heading1_deg = 2*(rand([numEnc 1]) - 0.5) * rad2deg(pi); % Heading of aircraft 2

% Initial position of aircraft 1
posx0 = 0;
posy0 = 0;

% Sample initial position of aircraft 2
absAngleToIntruder1 = 2*(rand([numEnc 1]) - 0.5) * pi;
posx1 = r0_ft * cos(absAngleToIntruder1);
posy1 = r0_ft * sin(absAngleToIntruder1);

%% Generate HMD, VMD distribution
% Sample Initial Altitude Difference, Speed and Vertical Rates
hInit_ft = 2*(rand([numEnc 1]) - 0.5) * h0_ft;

% Simulate movement
dx = s0_fps .* cosd(heading0_deg) - s1_fps .* cosd(heading1_deg);
dy = s0_fps .* sind(heading0_deg) - s1_fps .* sind(heading1_deg);

% Calculate CPA
cpaTime_s = (-posx1 .* dx - posy1 .* dy) ./ (dx .* dx + dy.* dy);

% Assume a max cpaTime_s and enforce this condition
% cpaMaxTime_s should be set to something large and should encompass less than 1% of cpaTime_s elements
l = abs(cpaTime_s) > cpaMaxTime_s;
cpaTime_s(l) = sign(cpaTime_s(l)) * cpaMaxTime_s;

% Calculate HMD & VMD at CPA
cpaHMD_ft = hypot(posx1 + dx .* cpaTime_s, posy1 + dy .* cpaTime_s);
cpaVMD_ft = hInit_ft + (dh0_fps - dh1_fps) .* cpaTime_s;

% Plot independent HMD & VMD distributions
figure(figstart); set(gcf,'name','Histogram: minHMD'); histogram(cpaHMD_ft,[0:stepHMD_ft:ceil(max(cpaHMD_ft))]); xlabel('HMD (ft)'); ylabel('Count'); grid on;
figure(figstart+1); set(gcf,'name','Histogram: minVMD'); histogram(cpaVMD_ft,[floor(min(cpaVMD_ft)) -3e3:100:3e3 ceil(max(cpaVMD_ft))]); xlabel('VMD (ft)'); ylabel('Count'); grid on;

% Plot and calculate HMD & VMD joint distribution
[encFreq centers binInds] = scatterDensity(cpaHMD_ft,cpaVMD_ft,'xCenters',[0:stepHMD_ft:maxHMD_ft], 'yCenters',[-maxVMD_ft:stepVMD_ft:maxVMD_ft],'logScale',1,'figureNumber',figstart+2); xlabel('HMD (ft)'); ylabel('VMD (ft)')

%% Plot and Calculate (pMAC | HMD, VMD)
% Calculate sum if width and heights
% Divide by 2 beacuse we assume CPA is center of aircraft (so half wingspan)
sumWidth_ft = (width0_ft + width1_ft)/2;
sumHeight_ft = (height0_ft + height1_ft)/2;

% Preallocate probability of MAC
pMAC = zeros(size(binInds));

% Iterate over bins
for i = 1:numel(binInds(:,1))
    for j = 1:numel(binInds(1,:))
        % Assume HMD,VMD center represents the points in the cell
        vmd_ft = centers{1}(i);
        hmd_ft = centers{2}(j);
        
        % Determine which "encounters" had a MAC and divide to get rate
        pMAC(i,j) = sum(abs(vmd_ft) < sumHeight_ft & hmd_ft < sumWidth_ft)/numPlanes;
    end
end

% Plot
figure(figstart+3); set(gcf,'name','Width (wingspan) distribution'); histogram(width0_ft,0.5:0.5:ceil(max(width0_ft))); xlabel('Width (ft)'); ylabel('Count'); grid on; title('Width (wingspan) distribution');
figure(figstart+4); set(gcf,'name','Height (tail) distribution'); histogram(height0_ft,0.5:0.5:ceil(max(height0_ft))); xlabel('Height (ft)'); ylabel('Count'); grid on; title('Height( tail) distribution');

%% Calculate pMAC | sNMAC (which is the encounter weighted pMAC / total
% encounter weight inside sNMAC)

pMACgSNMAC = zeros(size(binInds));
for i = 1:numel(binInds(:,1))
    for j = 1:numel(binInds(1,:))
        if(i < ceil(numel(binInds(:,1))/2))
            pMACgSNMAC(i,j) = sum(sum(pMAC(i:(end-i+1), 1:j) .* encFreq(i:(end-i+1), 1:j))) / sum(sum(encFreq(i:(end-i+1), 1:j)));
        elseif(i == ceil(numel(binInds(:,1))/2))
            pMACgSNMAC(i,j) = sum(sum(pMAC(i, 1:j) .* encFreq(i, 1:j))) / sum(sum(encFreq(i, 1:j)));
        else
            ind = (numel(binInds(:,1)) - i)+1;
            pMACgSNMAC(i,j) = sum(sum(pMAC(ind:(end-ind+1), 1:j) .* encFreq(ind:(end-ind+1), 1:j))) / sum(sum(encFreq(ind:(end-ind+1), 1:j)));
        end
    end
end

% Plot contours
figure(figstart+5); [C,h] = contour(centers{2}, centers{1}, (pMACgSNMAC),'ShowText','on'); set(gca,'YDir','Normal'); clabel(C,h,'FontSize',15,'Color','red')
set (gcf,'name','p(MAC | SNMAC)');
title('p(MAC | SNMAC)');
xlabel('sNMAC definition horizontal component (ft)')
ylabel('sNMAC definition vertical component (ft)')
h.LineWidth=2;
set(gca,'FontSize',25,'YLim',[min(sNMAC_vDef) max(sNMAC_vDef)],'YGrid','on','XGrid','on');

figure(figstart+6); imagesc(centers{2}, centers{1}, (pMACgSNMAC)); set(gca,'YDir','Normal');
xlabel('sNMAC definition horizontal component (ft)')
ylabel('sNMAC definition vertical component (ft)')
set(gca,'FontSize',25,'YLim',[min(sNMAC_vDef) max(sNMAC_vDef)],'YGrid','on','XGrid','on');

%% Now estimate pMD, pFA for a given vertical separation, given the altimeter error model
% p(sNMAC|sNMACObserved) pD
% p(!sNMAC|sNMACObserved) (pFA)

sigmaAltBCombined = sqrt(2) * sigmaAltBias; % Distribution of difference between two aircraft (assuming same sigma for each, and independence).
pSNMAC = zeros(size(sNMAC_vDef));
for si = 1:numel(sNMAC_vDef)
    
    % Use numeric integration of ERF function
    dX = 0.01;
    X = [0:dX:sNMAC_vDef(si)];
    
    pSNMAC(si) = sum(erf((sNMAC_vDef(si) - X) / sigmaAltBCombined))  / sNMAC_vDef(si) * dX;
end

% Plot
figure(figstart+7); plot(sNMAC_vDef, pSNMAC)
hold on; plot(sNMAC_vDef, 1-pSNMAC)
grid on
xlabel('sNMAC Definition Vertical Component (ft)');
ylabel('Probability')
legend({'p(sNMAC | sNMACObserved)', 'p(!sNMAC | sNMACObserved)'})
title(['Altitude error impacts on observed sNMACs - Assuming \sigma = ' num2str(sigmaAltBias) ' ft'])

%% Now estimate pMD, pFA for a given vertical separation, given the sNMAC vertical component
% p(sNMAC|sNMACObserved) pD
% p(!sNMAC|sNMACObserved) (pFA)

sigmaVec = [0.01 1:1:50];
vSNMACDef_ft = 15;

sigmaAltBCombined = sqrt(2) * sigmaAltBias; % Distribution of difference between two aircraft (assuming same sigma for each, and independence).
pSNMAC = zeros(size(sigmaVec));
for si = 1:numel(sigmaVec)
    
    % Use numeric integration of ERF function
    dX = 0.01;
    X = [0:dX:vSNMACDef_ft];
    
    pSNMAC(si) = sum(erf((vSNMACDef_ft - X) /( sqrt(2) * sigmaVec(si))))  / vSNMACDef_ft * dX;
end

% Plot
figure(figstart+8); plot(sigmaVec, pSNMAC)
hold on; plot(sigmaVec, 1-pSNMAC)
grid on
xlabel('Altitude Error Sigma (ft)'); ylabel('Probability')
legend({'p(sNMAC | sNMACObserved)', 'p(!sNMAC | sNMACObserved)'})
title(['Altitude error impacts on observed sNMACs - Assuming Vertical sNMAC Height = ' num2str(vSNMACDef_ft) ' ft'])

%% Now estimate NMAC | VMD
figure(figstart+9);  hold on;

sigmas = [99 121.6 130.4]; % Two-aircraft standard deviation (assuming indepdent error) - values from ASARP/ICAO
alts = [2300 10000 20000];

vmdVec = [0:1:500];
vNMACDef = 100;

pNMAC = zeros(size(vmdVec));
for si = 1:numel(sigmas)
for vi = 1:numel(vmdVec)

    % Use ERF function (assuming gaussian noise)
    if(vmdVec(vi) > vNMACDef)
       % Sum  
       X = [(vmdVec(vi) + vNMACDef)];        
       Y = [(vmdVec(vi) - vNMACDef)];        
       pNMAC(vi) = erfc(Y / (sqrt(2) * sigmas(si)))/2 - ...
           erfc(X / (sqrt(2) * sigmas(si)))/2;
    else
       X = abs(vmdVec(vi) + vNMACDef);        
       Y = abs(vmdVec(vi) - vNMACDef);        
       pNMAC(vi) = 1 - (erfc((X) / (sqrt(2) * sigmas(si)))/2 + ...
           erfc((Y) / (sqrt(2) * sigmas(si)))/2);
    end
end
plot(vmdVec, pNMAC)
lgs{si} = ['\sigma: ' num2str(sigmas(si))];
lgs{si} = ['Altitude: ' num2str(alts(si))];
end
grid on
xlabel('Observed VMD (ft)');
ylabel('p(NMAC | VMD Observed)')

legend(lgs)
title(['Altimetry error impacts on pNMAC']);
