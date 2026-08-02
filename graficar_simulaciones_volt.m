%% plot_simulations_vs_temp.m
%  3D SURFACE plot: Z=Power, X=Temperature, Y=Technology node
%  The user selects: circuit, power type, and supply voltage (via terminal).
%
%  Usage: run plot_simulations_vs_temp in MATLAB
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
circuit_opts_mat = {'Adder', 'Multiplicador', 'MUX'};  % internal .mat struct keys
circuit_tag      = {'Adder', 'Multiplier', 'MUX'};     % LaTeX-safe filename tokens
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

% Supply voltage (loaded from data — shown after files are read)
fprintf('\nAvailable supply voltages:\n');

% ── 2. LOAD .MAT FILES (before showing voltage options) ──────────────────
fprintf('\nLoading .mat files ...\n');

circuits_all = {'Adder', 'Multiplier', 'MUX'};
mat_files    = {'Simulaciones_Adder.mat', ...
                'Simulaciones_Multiplicador.mat', ...
                'Simulaciones_MUX.mat'};

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

% Show available voltages and prompt selection
vdds_all = sort(unique(ALL.(resp_circ).vdd_V));
for vi = 1:numel(vdds_all)
    fprintf('  %d) %.2f V\n', vi, vdds_all(vi));
end
while true
    op_vdd = input(sprintf('Select [1-%d]: ', numel(vdds_all)));
    if ismember(op_vdd, 1:numel(vdds_all)), break; end
    fprintf('  Invalid option, try again.\n');
end
V_sel    = vdds_all(op_vdd);
vdd_str  = sprintf('V_{DD} = %.2f V', V_sel);
resp_vdd = sprintf('%.2f V', V_sel);

% LaTeX-safe voltage token: e.g. 1.80 V -> VDD_equal_1p80V
%   Decimal point replaced with 'p' to avoid filename/LaTeX issues
vdd_tag = sprintf('VDD_equal_%s', strrep(sprintf('%.2fV', V_sel), '.', 'p'));
% Result examples: VDD_equal_0p60V, VDD_equal_1p20V, VDD_equal_1p80V

fprintf('\n----------------------------------------\n');
fprintf('Circuit : %s\n', resp_circ);
fprintf('Power   : %s\n', resp_pow);
fprintf('Voltage : %s\n', resp_vdd);
fprintf('----------------------------------------\n\n');

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
tbl_V      = ALL.(resp_circ);
tbl_V      = tbl_V(tbl_V.vdd_V == V_sel, :);

% Nodes present in this circuit, in global order
nodos_circ = ALL_NODOS(ismember(ALL_NODOS, unique(tbl_V.nodo)));
N_nodos    = numel(nodos_circ);

temps   = sort(unique(tbl_V.temp_C));
N_temps = numel(temps);

% ── 5. BUILD MATRICES FOR SURF ────────────────────────────────────────────
% X (N_temps x N_nodos): temperature
% Y (N_temps x N_nodos): node index
% Z (N_temps x N_nodos): power

X = zeros(N_temps, N_nodos);
Y = zeros(N_temps, N_nodos);
Z = zeros(N_temps, N_nodos);

for n = 1:N_nodos
    nd  = nodos_circ{n};
    row = tbl_V(strcmp(tbl_V.nodo, nd), :);

    % Global Y index for consistent spacing
    y_idx = find(strcmp(ALL_NODOS, nd));

    for ti = 1:N_temps
        rt = row(row.temp_C == temps(ti), :);
        X(ti, n) = temps(ti);
        Y(ti, n) = y_idx;
        if ~isempty(rt)
            Z(ti, n) = rt.(pfield)(1);
        else
            Z(ti, n) = NaN;
        end
    end
end

% ── 6. PLOT SURFACE ──────────────────────────────────────────────────────
fprintf('Generating plot...\n');

fig = figure('Name', sprintf('%s - %s Power - %s', resp_circ, resp_pow, vdd_str), ...
             'NumberTitle', 'off', 'Color', 'w', ...
             'Position', [100 100 980 700]);

ax = axes(fig); %#ok<LAXES>

surf(ax, X, Y, Z, log10(Z), ...
     'EdgeColor', [0.3 0.3 0.3], ...
     'EdgeAlpha', 0.4, ...
     'FaceAlpha', 0.92);

colormap(ax, parula);
cb = colorbar(ax);
cb.Label.String = [plabel ' Exponent'];
cb.Label.FontSize = 10;

% Y labels → node names
y_ticks = cellfun(@(nd) find(strcmp(ALL_NODOS, nd)), nodos_circ);
set(ax, 'YTick',      y_ticks, ...
        'YTickLabel', nodos_circ, ...
        'YTickLabelRotation', 20, ...
        'XTick', temps, ...
        'ZScale', 'log');

view(ax, -40, 28);
grid(ax, 'on');
box(ax, 'on');

xlabel(ax, 'Temperature (°C)',    'FontWeight', 'bold', 'FontSize', 11);
ylabel(ax, 'Technology (node)',   'FontWeight', 'bold', 'FontSize', 11);
zlabel(ax, plabel,                'FontWeight', 'bold', 'FontSize', 11);

title(ax, sprintf('%s  |  %s Power  |  %s', resp_circ, resp_pow, vdd_str), ...
      'FontSize', 13, 'FontWeight', 'bold');

% ── 7. SAVE FIGURE (LaTeX-compatible filename) ───────────────────────────
% Format: <Circuit>_<PowerType>_Power_<VDD_tag>.png
% Examples:
%   Adder_Dynamic_Power_VDD_equal_1p20V.png
%   MUX_Static_Power_VDD_equal_0p60V.png
%   Multiplier_Dynamic_Power_VDD_equal_1p80V.png
%
% Rules applied:
%   - No spaces         → underscores _
%   - No decimal point  → letter p  (1.20 → 1p20)
%   - No degree symbol, no braces, no special chars

fprintf('Saving figure...\n');

% Format: Adder_Dynamic_Power_VDD_equal_1p20V
fig_filename = sprintf('%s_%s_Power_%s', circ_tag, pow_tag, vdd_tag);

% Export as PNG (300 dpi — suitable for LaTeX \includegraphics)
exportgraphics(fig, [fig_filename '.png'], 'Resolution', 300);
fprintf('  [OK] Saved as %s.png\n', fig_filename);

% Optional: also save as PDF vector (uncomment if preferred for LaTeX)
% exportgraphics(fig, [fig_filename '.pdf'], 'ContentType', 'vector');
% fprintf('  [OK] Saved as %s.pdf\n', fig_filename);

fprintf('Done.\n');