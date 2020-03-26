function [h centers binInds] = scatterDensity(x,y,varargin)


% Inputs
% x: data for horizontal axis of scatter density
% y: data for vertical axis of scatter density

% Optional arguments
% 'xbins','ybins': used to specify the number of bins in the histogram along
% each axis (scalar arguments)
% 'xcenters','ycenters': used to specify the vector corresponding to each
% bin (vector arguments)
% 'figureNumber': plot to an existing specified figure (otherwise create a
% new figure)
% 'logscale': uses a logscale color map
% 'Weights',W: Assumes weighted samples instead of uniform weighting, W
% must be same size as x and y

% Example usage:
% scatterDensity(x,y,'xbins',10,'ybins',20);
% scatterDensity(x,y,'xcenters',[0:10:100],'ycenters',[0:5:100]);

%% Input Parser
p = inputParser;
p.KeepUnmatched = true;

% Optional
p.addOptional('xbins', 100);
p.addOptional('ybins', 100);
p.addOptional('xcenters', 0);
p.addOptional('ycenters', 0);

% Parameter Values
p.addParamValue('logscale', 0);
p.addParamValue('figureNumber', 0);
p.addParamValue('subplot_xDim', 1);
p.addParamValue('subplot_yDim', 1);
p.addParamValue('subplot_ind', 1);
p.addParamValue('weights', []);
p.addParamValue('normalize', []);
p.addParamValue('axes', 0);

% Parse
p.parse(varargin{:});

%% Create local variables for convenience
xbins = p.Results.xbins;
ybins = p.Results.ybins;
xcenters = p.Results.xcenters;
ycenters = p.Results.ycenters;
logscale = p.Results.logscale;
fignum = p.Results.figureNumber;
subplot_xDim = p.Results.subplot_xDim;
subplot_yDim = p.Results.subplot_yDim;
subplot_ind = p.Results.subplot_ind;
w = p.Results.weights;
normalize = p.Results.normalize;
ax = p.Results.axes;

%%
ux = unique(x);
if length(ux) < 20
    xcenters = ux;
    xbins = length(ux);
else
    xcenters = p.Results.xcenters;
    xbins = p.Results.xbins;
end
uy = unique(y);
if length(uy) < 20
    ycenters = uy;
    ybins = length(uy);
else
    ycenters = p.Results.ycenters;
    ybins = p.Results.ybins;
end

dim = size(x);
if(dim(1) < dim(2))
    x = x.';
end
dim = size(y);
if(dim(1) < dim(2))
    y = y.';
end

if(length(xcenters) > 1 && length(ycenters) > 1)
    [h, centers] = hist3([y x],{ycenters xcenters});
elseif(length(xcenters) > 1)
    [h, centers] = hist3([y x],[ybins length(xcenters)]);
    [h, centers] = hist3([y x],{centers{1} xcenters});
elseif(length(ycenters) > 1)
    [h, centers] = hist3([y x],[length(ycenters) xbins]);
    [h, centers] = hist3([y x],{ycenters centers{2}});
else
    [h, centers] = hist3([y x],[ybins xbins]);
end

%% Perform weighted binning...
if(~isempty(w) && isempty(normalize))
    [~,~,binsX] = histcounts(x,[-inf centers{2}(1:end-1) + diff(centers{2}(1:2))/2 inf]);
    [~,~,binsY] = histcounts(y,[-inf centers{1}(1:end-1) + diff(centers{1}(1:2))/2 inf]);
    wh = zeros(size(h));
    binInds = cell(size(h));
    for i = 1:numel(h(:,1))
        for j = 1:numel(h(1,:))
            inds = find(binsX == j & binsY == i);
            binInds{i,j} = inds;
            wh(i,j) = sum(w(inds));
        end
    end
    h = wh;
    
elseif(~isempty(w) && ~isempty(normalize))
    [~,~,binsX] = histcounts(x,[-inf centers{2}(1:end-1) + diff(centers{2}(1:2))/2 inf]);
    [~,~,binsY] = histcounts(y,[-inf centers{1}(1:end-1) + diff(centers{1}(1:2))/2 inf]);
    wh = zeros(size(h));
    binInds = cell(size(h));
    for i = 1:numel(h(:,1))
        for j = 1:numel(h(1,:))
            inds = find(binsX == j & binsY == i);
            binInds{i,j} = inds;
            wh(i,j) = sum(w(inds) .* normalize(inds)) / sum(w(inds));
        end
    end
    h = wh;
elseif(nargout() >= 3)
    [~,~,binsX] = histcounts(x,[-inf centers{2}(1:end-1) + diff(centers{2}(1:2))/2 inf]);
    [~,~,binsY] = histcounts(y,[-inf centers{1}(1:end-1) + diff(centers{1}(1:2))/2 inf]);
    binInds = cell(size(h));
    for i = 1:numel(h(:,1))
        for j = 1:numel(h(1,:))
            inds = find(binsX == j & binsY == i);
            binInds{i,j} = inds;
        end
    end
end

%% Plot
if(fignum ~= 0)
    if(ax== 0)
        figure(fignum);
    end
    if(ax ~= 0)
        axes(ax);
    else
        subplot(subplot_xDim, subplot_yDim, subplot_ind);
    end
else
    if(ax== 0)
        figure;
    end
end

if(logscale == 1)
    if(ax ~=0)
        imagesc(centers{2},centers{1},10*log10(h),'parent',ax);
    else
        imagesc(centers{2},centers{1},10*log10(h));
    end
else
    if(ax ~=0)
        imagesc(centers{2},centers{1},(h),'parent',ax);
    else
        imagesc(centers{2},centers{1},(h));
    end
end
if(ax ~= 0)
    set(ax,'ydir','normal')
else
    set(gca,'ydir','normal')
end

set(gcf,'name','scatterDensity');

end