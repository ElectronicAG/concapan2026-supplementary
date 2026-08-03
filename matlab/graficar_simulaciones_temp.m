%% plot_simulations.m
%  3D SURFACE plot: Z=Power, X=Voltage, Y=Technology node
%  The user selects: circuit, power type, and temperature (via terminal).
%
%  Usage: run plot_simulations in MATLAB
%  Requires: Simulaciones_Adder.mat, Simulaciones_Multiplicador.mat,
%            Simulaciones_MUX.mat in the same directory.
% -------------------------------------------------------------------------

clearvars; clear; clc;

% ── 1. USER SELECTION (terminal) ─────────────────────────────────────────
fprintf('========================================\n');
fprintf('   3D PLOT CONFIGURATION\n');
fprintf('========================================\n\n');

% Circuit
fprintf('Circuit to plot:\n');
fprintf('  1) Adder\n');
fprintf('  2) Multiplier\n');
fprintf('  3) MUX\n');
while true
    op_circ = input('Select [1-3]: ');
    if ismember(op_circ, [1 2 3]), break; end
    fprintf('  Invalid option, try again.\n');
end
circuit_opts     = {'Adder', 'Multiplier', 'MUX'};
circuit_opts_mat = {'Adder', 'Multiplicador', 'MUX'};   % keys inside .mat files
circuit_tag      = {'Adder', 'Multiplier', 'MUX'};      % LaTeX-safe filename tokens
resp_circ        = circuit_opts{op_circ};
resp_circ_mat    = circuit_opts_mat{op_circ};
circ_tag         = circuit_tag{op_circ};

% Power type
fprintf('\nPower type:\n');
fprintf('  1) Dynamic\n');
fprintf('  2) Static\n');
while true
    op_pow = input('Select [1-2]: ');
    if ismember(op_pow, [1 2]), break; end
    fprintf('  Invalid option, try again.\n');
end
if op_pow == 1
    pfield   = 'dyn_W';
    plabel   = 'Dynamic power';
    resp_pow = 'Dynamic';
    pow_tag  = 'Dynamic';
else
    pfield   = 'sta_W';
    plabel   = 'Static power';
    resp_pow = 'Static';
    pow_tag  = 'Static';
end

% Temperature
fprintf('\nTemperature:\n');
fprintf('  1) Minimum (−40 °C)\n');
fprintf('  2) Maximum (80 °C)\n');
while true
    op_temp = input('Select [1-2]: ');
    if ismember(op_temp, [1 2]), break; end
    fprintf('  Invalid option, try again.\n');
end

temp_opts = {'T_min_equal_minus_40Cel', 'T_max_equal_80Cel'};   % LaTeX-safe tokens
temp_label = {'T_{min} = -40 C', 'T_{max} = 80 C'};
temp_tag   = temp_opts{op_temp};

fprintf('\n----------------------------------------\n');
fprintf('Circuit     : %s\n', resp_circ);
fprintf('Power type  : %s\n', resp_pow);
fprintf('Temperature : %s\n', strrep(temp_label{op_temp}, '{', ''));
fprintf('----------------------------------------\n\n');

% ── 2. LOAD .MAT FILES ───────────────────────────────────────────────────
fprintf('Loading .mat files ...\n');

circuits_all = {'Adder', 'Multiplier', 'MUX'};
mat_files    = {'Simulaciones_Adder.mat', ...
                'Simulaciones_Multiplicador.mat', ...
                'Simulaciones_MUX.mat'};
mat_keys     = {'Adder', 'Multiplicador', 'MUX'};   % internal .mat struct names

ALL = struct();
for c = 1:numel(mat_files)
    raw  = load(mat_files{c});
    vars = fieldnames(raw);
    tbl  = table();
    for v = 1:numel(vars)
        s = raw.(vars{v});
        t = table( ...
            s.nodo(:), s.familia(:), s.vdd_V(:), s.temp_C(:), ...
            s.dynamic_power_W(:), s.static_power_W(:), ...
            'VariableNames', {'nodo','familia','vdd_V','temp_C','dyn_W','sta_W'});
        tbl = [tbl; t]; %#ok<AGROW>
    end
    ALL.(circuits_all{c}) = tbl;
    fprintf('  [OK] %s\n', mat_files{c});
end

% Selected temperature
temps_all = unique(ALL.(circuits_all{1}).temp_C);
T_min = min(temps_all);
T_max = max(temps_all);

if op_temp == 1
    T_sel    = T_min;
    temp_str = sprintf('T_{min} = %d C', T_min);
else
    T_sel    = T_max;
    temp_str = sprintf('T_{max} = %d C', T_max);
end

fprintf('\nCircuit: %s  |  %s power  |  %s\n\n', resp_circ, resp_pow, temp_str);

% ── 3. GLOBAL NODE ORDER (7nm → 130nm_bulk) ──────────────────────────────
all_nodos_raw = {};
for c = 1:numel(circuits_all)
    all_nodos_raw = [all_nodos_raw; unique(ALL.(circuits_all{c}).nodo)]; %#ok<AGROW>
end
all_nodos_raw = unique(all_nodos_raw);
nodo_nm       = cellfun(@(x) sscanf(x,'%d',1), all_nodos_raw);
[~, si]       = sort(nodo_nm);
ALL_NODOS     = all_nodos_raw(si);

% ── 4. FILTER DATA ───────────────────────────────────────────────────────
tbl_T      = ALL.(resp_circ);
tbl_T      = tbl_T(tbl_T.temp_C == T_sel, :);

% Nodes present in this circuit, in global order
nodos_circ = ALL_NODOS(ismember(ALL_NODOS, unique(tbl_T.nodo)));
N_nodos    = numel(nodos_circ);

vdds   = sort(unique(tbl_T.vdd_V));
N_vdds = numel(vdds);

% ── 5. BUILD MATRICES FOR SURF ────────────────────────────────────────────
% X (N_vdds x N_nodos): voltage
% Y (N_vdds x N_nodos): node index
% Z (N_vdds x N_nodos): power

X = zeros(N_vdds, N_nodos);
Y = zeros(N_vdds, N_nodos);
Z = zeros(N_vdds, N_nodos);

for n = 1:N_nodos
    nd  = nodos_circ{n};
    row = tbl_T(strcmp(tbl_T.nodo, nd), :);

    % Global Y index for consistent spacing
    y_idx = find(strcmp(ALL_NODOS, nd));

    for vi = 1:N_vdds
        rv = row(row.vdd_V == vdds(vi), :);
        X(vi, n) = vdds(vi);
        Y(vi, n) = y_idx;
        if ~isempty(rv)
            Z(vi, n) = rv.(pfield)(1);
        else
            Z(vi, n) = NaN;
        end
    end
end

% ── 6. PLOT SURFACE ──────────────────────────────────────────────────────
fprintf('Generating plot...\n');

fig = figure('Name', sprintf('%s - %s Power - %s', resp_circ, resp_pow, temp_str), ...
             'NumberTitle', 'off', 'Color', 'w', ...
             'Position', [100 100 980 700]);

ax = axes(fig); %#ok<LAXES>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
surf(ax, X, Y, Z, log10(Z), ...
     'EdgeColor', [0.3 0.3 0.3], ...
     'EdgeAlpha', 0.4, ...
     'FaceAlpha', 0.92);

colormap(ax, parula);
cb = colorbar(ax);
cb.Label.String = [plabel ' Exponent'];
cb.Label.FontSize = 10;

y_ticks = cellfun(@(nd) find(strcmp(ALL_NODOS, nd)), nodos_circ);
set(ax, 'YTick',      y_ticks, ...
        'YTickLabel', nodos_circ, ...
        'YTickLabelRotation', 20, ...
        'XTick', vdds, ...   % <-- vdds o temps segun el script
        'ZScale', 'log', ...
        'ZTick', 10.^(-8:1:0));

zt = get(ax, 'ZTick');
zt_labels = arrayfun(@(v) sprintf('10^{%d}', round(log10(v))), zt, 'UniformOutput', false);
set(ax, 'ZTickLabel', zt_labels);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
view(ax, -40, 28);
grid(ax, 'on');
box(ax, 'on');

xlabel(ax, 'V_{DD} (V)',          'FontWeight', 'bold', 'FontSize', 11);
ylabel(ax, 'Technology (node)',   'FontWeight', 'bold', 'FontSize', 11);
zlabel(ax, plabel,                'FontWeight', 'bold', 'FontSize', 11);

title(ax, sprintf('%s  |  %s Power  |  %s', resp_circ, resp_pow, temp_str), ...
      'FontSize', 13, 'FontWeight', 'bold');

% ── 7. SAVE FIGURE (LaTeX-compatible filename) ───────────────────────────
% Format: <Circuit>_<PowerType>_Power_<TempTag>.png
% Example: Adder_Dynamic_Power_T_min_equal_minus_40Cel.png
%          MUX_Static_Power_T_max_equal_80Cel.png
% No spaces, no special characters (no °, -, +, {, }).

% Format: Adder_Dynamic_Power_T_min_equal_minus_40Cel
fig_filename = sprintf('%s_%s_Power_%s', circ_tag, pow_tag, temp_tag);

% Export as PNG (300 dpi — suitable for LaTeX \includegraphics)
exportgraphics(fig, [fig_filename '.png'], 'Resolution', 300);
fprintf('Figure saved: %s.png\n', fig_filename);

% Optional: also save as PDF vector (uncomment if preferred for LaTeX)
% exportgraphics(fig, [fig_filename '.pdf'], 'ContentType', 'vector');
% fprintf('Figure saved: %s.pdf\n', fig_filename);

fprintf('Done.\n');