function output = setParameters(simCase,varargin)

%% Input Parser
p = inputParser;

% Required
addRequired(p,'simCase',@isnumeric);

% Initial "encounter" conditions
addOptional(p,'r0_ft',2000,@isnumeric); % Initial range 
addOptional(p,'h0_ft',50,@isnumeric); % Initial vertical sep.
addOptional(p,'numEnc',1e6,@isnumeric);
addOptional(p,'numPlanes',10000,@isnumeric);
addOptional(p,'cpaMaxTime_s',60*10,@isnumeric);

% Airspeed distribution
addOptional(p,'minSpeed_fps',10,@isnumeric);
addOptional(p,'speedRange_fps',160,@isnumeric);

% Vertical rate distribution
addOptional(p,'dhRange_fps',20,@isnumeric);

% Width (wingspan) distribution
addOptional(p,'widthRange_ft',24,@(x) isnumeric(x) & x>=0); % In statistics, the range of a set of data is the difference between the largest and smallest values. 
addOptional(p,'widthMin_ft',1,@(x) isnumeric(x) & x>0); % Minimum width
addOptional(p,'isEnforceWidth',true,@islogical); % If true, enforce distribution limits (used when generating a random distribution)

% Height distribution
addOptional(p,'heightRange_ft',11.5,@(x) isnumeric(x) & x>=0); % In statistics, the range of a set of data is the difference between the largest and smallest values. 
addOptional(p,'heightMin_ft',0.5,@(x) isnumeric(x) & x>0); % Minimum height
addOptional(p,'isEnforceHeight',true,@islogical); % If true, enforce distribution limits (used when generating a random distribution)

% HMD, VMD, CPA
addOptional(p,'maxHMD_ft',200,@isnumeric);
addOptional(p,'stepHMD_ft',5,@isnumeric);
addOptional(p,'maxVMD_ft',100,@isnumeric);
addOptional(p,'stepVMD_ft',5,@isnumeric);

% Candidates
addOptional(p,'sNMAC_vDef',[0:1:100],@isnumeric);

% Altimetry Error (default)
% Bosch BMP 388 for drones (2018)
% Absolute Accuracy Sea level,1013.25hPa150C, 0% humidity, +/-0.50 hPa ->+/-13.66 ft
% https://www.bosch-sensortec.com/en/bst/products/all_products/bmp380
addOptional(p,'sigmaAltBias',13.66,@isnumeric);

% Candidate sNMAC def range of interest
parse(p,simCase,varargin{:});

%% Assign initial output based on input parser
output = p.Results;

% Preallocate variables to be calculated
output.width0_ft = [];
output.width1_ft = [];

%% Warnings about aircraft size violate assumptions
% Refer to academic paper for more details
% Intentionally hardcoded to align with assumptions
if (output.widthMin_ft + output.widthRange_ft) > 25
   warning('setParameters:widthmax','Maximum effective width is greater than 25 feet, potentially violating an assumption\n'); 
end

if (output.heightMin_ft + output.heightRange_ft) > 12
   warning('setParameters:heightmax','Maximum effective height is greater than 12 feet, potentially violating an assumption\n'); 
end

%% Set height (tail) distributions (uniform for all use cases)
output.height0_ft = rand([output.numPlanes 1]) * output.heightRange_ft + output.heightMin_ft; % Effective height of aircraft 1
output.height1_ft = rand([output.numPlanes 1]) * output.heightRange_ft + output.heightMin_ft; % Effective height of aircraft 2

%% Overwrite defaults (if needed) and calculate variables
switch simCase
    case 0 %
        warning('setParameters:simCase1','simCase = %i, just the defaults and not calculating width0_ft\n',simCase);
    case 1
        fprintf('simCase = %i, manned aircraft\n',simCase);
        
        output.r0_ft = 10000; % Initial range
        output.h0_ft = 500; % ft
        output.numEnc = 1e7;
        
        output.minSpeed_fps = 100; %ft/s
        output.speedRange_fps = 1100; % ft/s
        output.dhRange_fps = 50; % ft/s
        
        % Winspan distribution
        output.widthRange_ft = 251;
        output.widthMin_ft = 1;
        
        % Height
        output.heightRange_ft = 70;
        output.heightMin_ft = 10;
        
        % HMD, VMD, CPA
        output.maxHMD_ft = 2000;
        output.stepHMD_ft = 50;
        output.maxVMD_ft = 1000;
        output.stepVMD_ft = 50;
        
        % Generate width distribution
        output.width0_ft = rand([output.numPlanes 1]) * output.widthRange_ft + output.widthMin_ft;
        output.width1_ft = rand([output.numPlanes 1]) * output.widthRange_ft + output.widthMin_ft;
        
        % Altimetry Error and sNMAC candidate
        output.sigmaAltBias = 30;
        output.sNMAC_vDef = [0:1:1000];
        
    case 2 % sUAS - uniform wingspans
        fprintf('simCase = %i, sUAS - uniform wingspans, uniform height\n',simCase);

        % Generate width distribution
        output.width0_ft = rand([output.numPlanes 1]) * output.widthRange_ft + output.widthMin_ft;
        output.width1_ft = rand([output.numPlanes 1]) * output.widthRange_ft + output.widthMin_ft;
        
        % Candidate sNMAC def range of interest
        output.sNMAC_vDef = [0:1:100];
        
    case 3 % sUAS - worst case indicator function
        fprintf('simCase = %i, sUAS - worst case width indicator function, uniform height\n',simCase);    
        
        % Overwrite default width and height to be worse case
        output.widthMin_ft = 24;
        output.widthRange_ft = 1;
        output.heightMin_ft = 11.5;
        output.heightRange_ft = 0.5;
        
        % Generate width distribution
        output.width0_ft = rand([output.numPlanes 1]) * output.widthRange_ft + output.widthMin_ft;
        output.width1_ft = rand([output.numPlanes 1]) * output.widthRange_ft + output.widthMin_ft;
        
    case 4 % sUAS - Left skew wingspans
        fprintf('simCase = %i, sUAS - left skew width (wingspan), uniform height\n',simCase);
        
        % Generate width distribution
        wingIncrements = 100;
        width0_ft = [];
        width1_ft = [];
        for wi = 1:wingIncrements
            tempRange = wi*output.widthRange_ft / wingIncrements;
            
            width0_ft = cat(1,width0_ft,rand([output.numPlanes / wingIncrements 1]) * tempRange + output.widthMin_ft);
            width1_ft = cat(1,width1_ft,rand([output.numPlanes / wingIncrements 1]) * tempRange + output.widthMin_ft);
        end
        
        % Assign
        output.width0_ft = width0_ft;
        output.width1_ft = width1_ft;
        
    case 5 % sUAS - Right skew wingspans
        fprintf('simCase = %i, sUAS - right skew width (wingspan), uniform height\n',simCase);
         
        % Generate width distribution
        wingIncrements = 100;
        width0_ft = [];
        width1_ft = [];
        for wi = 1:wingIncrements
            tempRange = wi*output.widthRange_ft / wingIncrements;
            
            width0_ft = cat(1,width0_ft,rand([output.numPlanes / wingIncrements 1]) * tempRange + output.widthMin_ft  + (wingIncrements - wi) / wingIncrements * output.widthRange_ft);
            width1_ft = cat(1,width1_ft,rand([output.numPlanes / wingIncrements 1]) * tempRange + output.widthMin_ft  + (wingIncrements - wi) / wingIncrements * output.widthRange_ft);
        end
        
         % Assign
        output.width0_ft = width0_ft;
        output.width1_ft = width1_ft;
        
    case 6
        fprintf('simCase = %i, sUAS - gaussian / normal wingspan, uniform height\n',simCase);
        
        % Generate width distribution
        wingIncrements = 100;
        output.width0_ft = normrnd(8,5,[output.numPlanes 1]);
        output.width1_ft = normrnd(8,5,[output.numPlanes 1]);
end

%% Enforce compliance (if needed)
% Width
if p.Results.isEnforceWidth
    % AC1
    lmin0 = output.width0_ft < output.widthMin_ft; % Min
    lmax0 = output.width0_ft > output.widthMin_ft + output.widthRange_ft; % Max
    output.width0_ft(lmin0) = output.widthMin_ft;
    output.width0_ft(lmax0) = output.widthMin_ft + output.widthRange_ft;
    
    % AC2
    lmin1 = output.width1_ft < output.widthMin_ft; % Min
    lmax1 = output.width1_ft > output.widthMin_ft + output.widthRange_ft; % Max
    output.width1_ft(lmin1) = output.widthMin_ft;
    output.width1_ft(lmax1) = output.widthMin_ft + output.widthRange_ft; 
end

% Width
if p.Results.isEnforceHeight
    % AC1
    lmin0 = output.height0_ft < output.heightMin_ft; % Min
    lmax0 = output.height0_ft > output.heightMin_ft + output.heightRange_ft; % Max
    output.height0_ft(lmin0) = output.heightMin_ft;
    output.height0_ft(lmax0) = output.heightMin_ft + output.heightRange_ft;
    
    % AC2
    lmin1 = output.height1_ft < output.heightMin_ft; % Min
    lmax1 = output.height1_ft > output.heightMin_ft + output.heightRange_ft; % Max
    output.height1_ft(lmin1) = output.heightMin_ft;
    output.height1_ft(lmax1) = output.heightMin_ft + output.heightRange_ft; 
end
