function db = lognormal(this, db, varargin)
% lognormal  Characteristics of log-normal distributions returned from filter of forecast.
%
% Syntax
% =======
%
%     D = lognormal(M,D,...)
%
% Input arguments
% ================
%
% * `M` [ model ] - Model on which the `filter` or `forecast` function has
% been run.
%
% * `D` [ struct ] - Struct or database returned from the `filter`
% or `forecast` function.
%
% Output arguments
% =================
%
% * `D` [ struct ] - Struct including new sub-databases with requested
% log-normal statistics.
%
% Options
% ========
%
% * `'fresh='` [ `true` | *`false`* ] - Output structure will include only
% the newly computed databases.
%
% * `'mean='` [ *`true`* | `false` ] - Compute the mean of the log-normal
% distributions.
%
% * `'median='` [ *`true`* | `false` ] - Compute the median of the log-normal
% distributions.
%
% * `'mode='` [ *`true`* | `false` ] - Compute the mode of the log-normal
% distributions.
%
% * `'prctile='` [ numeric | *`[5,95]`* ] - Compute the selected
% percentiles of the log-normal distributions.
%
% * `'prefix='` [ char | *`'lognormal'`* ] - Prefix used in the names of
% the newly created databases.
%
% * `'std='` [ *`true`* | `false` ] - Compute the std deviations of the
% log-normal distributions.
%
% Description
% ============
%

% -IRIS Macroeconomic Modeling Toolbox.
% -Copyright (c) 2007-2017 IRIS Solutions Team.

TEMPLATE_SERIES = Series( );

pp = inputParser( );
pp.addRequired('D', ...
    @(x) isstruct(x) && isfield(x, 'mean') && isfield(x, 'std'));
pp.parse(db);

Opt = passvalopt('model.lognormal',varargin{:});

%--------------------------------------------------------------------------

lsExist = fieldnames(db);
field = @(x) sprintf('%s%s%', Opt.prefix, x);

doInitStruct( );

for posName = find(this.Quantity.IxLog)
    name = this.Quantity.Name{posName};
    doPopulate( );
end

if Opt.fresh 
    db = rmfield(db, lsExist);
end

return



    
    function doInitStruct( )
        if Opt.median
            db.(field('median')) = struct( );
        end
        if Opt.mode
            db.(field('mode')) = struct( );
        end
        if Opt.mean
            db.(field('mean')) = struct( );
        end
        if Opt.std
            db.(field('std')) = struct( );
        end
        if ~isequal(Opt.prctile,false) && ~isempty(Opt.prctile)
            Opt.prctile = Opt.prctile(:).';
            Opt.prctile = round(Opt.prctile);
            Opt.prctile(Opt.prctile <= 0 | Opt.prctile >= 100) = [ ];
            db.(field('pct')) = struct( );
        end
    end 



    
    function doPopulate( )
        [expmu,range] = rangedata(db.mean.(name),Inf);
        if isempty(range)
            return
        end
        sgm = rangedata(db.std.(name),range);
        sgm = log(sgm);
        sgm2 = sgm.^2;
        co = comment(db.mean.(name));
        start = range(1);
        if Opt.median
            x = getMedian(expmu,sgm,sgm2);
            db.(field('median')).(name) = replace(TEMPLATE_SERIES,x,start,co);
        end
        if Opt.mode
            x = getMode(expmu,sgm,sgm2);
            db.(field('mode')).(name) = replace(TEMPLATE_SERIES,x,start,co);
        end
        if Opt.mean
            x = getMean(expmu,sgm,sgm2);
            db.(field('mean')).(name) = replace(TEMPLATE_SERIES,x,start,co);
        end
        if Opt.std
            x = getStd(expmu,sgm,sgm2);
            db.(field('std')).(name) = replace(TEMPLATE_SERIES,x,start,co);
        end
        if ~isequal(Opt.prctile,false) && ~isempty(Opt.prctile)
            x = [ ];
            for p = Opt.prctile
                x = [x,getPrctile(expmu,sgm,sgm2,p/100)]; %#ok<AGROW>
            end
            co = repmat(co,1,length(Opt.prctile));
            db.(field('pct')).(name) = replace(TEMPLATE_SERIES,x,start,co);
        end
    end
end




function X = getMedian(ExpMu,~,~)
X = ExpMu;
end




function X = getMode(ExpMu,~,Sgm2)
X = ExpMu ./ exp(Sgm2);
end




function X = getMean(ExpMu,~,Sgm2)
X = ExpMu .* exp(0.5*Sgm2);
end




function X = getStd(ExpMu,Sgm,Sgm2)
X = getMean(ExpMu,Sgm,Sgm2) .* sqrt(exp(Sgm2)-1);
end




function X = getPrctile(ExpMu,Sgm,~,P)
A = -sqrt(2).*erfcinv(2*P);
X = exp(Sgm.*A) .* ExpMu;
end
