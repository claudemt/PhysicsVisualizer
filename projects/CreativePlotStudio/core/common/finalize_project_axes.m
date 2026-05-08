function finalize_project_axes(ax, titleText)
%FINALIZE_PROJECT_AXES Apply common style and compact title after rendering.
apply_axes_style(ax);
set_latex_title(ax, titleText);
try
    ax.UserData.rendered = true;
catch
end
end
