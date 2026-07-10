function apply_latex_formatting(figHandle, axHandle)
%APPLY_LATEX_FORMATTING Keep plot typography consistent.

set(figHandle, 'DefaultTextInterpreter', 'latex');
set(axHandle, 'TickLabelInterpreter', 'latex');
box(axHandle, 'on');
xlabel(axHandle, '$x$', 'Interpreter','latex');
ylabel(axHandle, '$y$', 'Interpreter','latex');
end
