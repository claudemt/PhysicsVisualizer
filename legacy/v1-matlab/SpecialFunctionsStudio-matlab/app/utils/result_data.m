function varargout = result_data(action,varargin)
switch lower(action)
    case 'make_curve_result'
        curves = varargin{1}; ttl = varargin{2}; xl = varargin{3}; yl = varargin{4};
        result = struct('kind','1d','curves',{curves},'title',ttl,'xlabel',xl,'ylabel',yl);
        varargout{1} = result;
    case 'arg_matrix'
        params = varargin{1};
        if isfield(params,'arg_matrix'), varargout{1} = params.arg_matrix; else, varargout{1}=zeros(1,0); end
    case 'column'
        params = varargin{1}; idx = varargin{2}; default_value = varargin{3};
        A = result_data('arg_matrix',params);
        if isempty(A), varargout{1} = default_value; return; end
        if size(A,2) < idx, varargout{1} = repmat(default_value,size(A,1),1); else, varargout{1} = A(:,idx); end
    otherwise
        error('Unknown helper action: %s',action);
end
end
