classdef NIRS_HCR < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        Toolbar                  matlab.ui.container.Toolbar
        convertICON              matlab.ui.container.toolbar.PushTool
        openICON                 matlab.ui.container.toolbar.PushTool
        SaveICON                 matlab.ui.container.toolbar.PushTool
        HCR                      matlab.ui.container.toolbar.PushTool
        save_csv                 matlab.ui.container.toolbar.PushTool
        refreshICON              matlab.ui.container.toolbar.PushTool
        NIRS_nadir_value         matlab.ui.control.Label
        NIRS_label_2             matlab.ui.control.Label
        NIRS_recovery_value      matlab.ui.control.Label
        NIRS_recovery_label      matlab.ui.control.Label
        SaveCSVButton            matlab.ui.control.Button
        NIRS_value               matlab.ui.control.Label
        NIRS_label               matlab.ui.control.Label
        HCR_on_target            matlab.ui.control.Label
        CalculateButton          matlab.ui.control.Button
        MaxPowerNEditField       matlab.ui.control.NumericEditField
        MaxPowerNEditFieldLabel  matlab.ui.control.Label
        HCRfilename              matlab.ui.control.Label
        HCR_value                matlab.ui.control.Label
        HCRAUCLabel              matlab.ui.control.Label
        fileLabel                matlab.ui.control.Label
        SelectsegmentsPanel      matlab.ui.container.Panel
        ExerciseButton           matlab.ui.control.Button
        BaselineButton           matlab.ui.control.Button
        FilterPanel              matlab.ui.container.Panel
        lowpassHzSpinner_2       matlab.ui.control.Spinner
        lowpassHzSpinner_2Label  matlab.ui.control.Label
        filter                   matlab.ui.control.CheckBox
        ax1                      matlab.ui.control.UIAxes
        ax2                      matlab.ui.control.UIAxes
        ax3                      matlab.ui.control.UIAxes
    end

    % Properties for data storage and app state
    properties (Access = private)
        Data % Main data structure for NIRS and HCR data
        
        % Constants for HCR target calculation
        HCR_TARGET_LOW_PERCENT = 0.35;
        HCR_TARGET_HIGH_PERCENT = 0.45;
    end

    
    methods (Access = private)
        
        %% DATA LOADING AND INITIALIZATION %%

        function resetAppData(app)
            % Resets the app's data properties to an empty state.
            % This is called when opening a new file.
            app.Data = [];
            cla(app.ax1,"reset");
            cla(app.ax2,"reset");
            cla(app.ax3,"reset");
            
            % Reset UI labels
            app.fileLabel.Text = 'No file open';
            app.NIRS_value.Text = 'Segments not selected';
            app.NIRS_nadir_value.Text = 'Segments not selected';
            app.NIRS_recovery_value.Text = 'Segments not selected';
            app.HCR_value.Text = 'No HCR selected';
            app.HCRfilename.Text = '';
            app.HCR_on_target.Text = '';
        end

        function loadNIRSData(app, nirs_data, short_filename)
            % Loads NIRS data into the app's data structure.
            % Add validation to ensure nirs_data is a structure
            if ~isstruct(nirs_data)
                error('NIRS data must be a structure, but received %s', class(nirs_data));
            end
            
            app.Data.NIRS = nirs_data;
            if ~isfield(nirs_data, 'filename')
                app.Data.NIRS.filename = short_filename;
            end
            app.Data.HCR = []; % Clear any existing HCR data
        end

        function loadHCRData(app, HCR_data, short_filename)
            % Loads HCR data into the app's data structure.
            % Add validation to ensure HCR_data is a structure or empty
            if ~isempty(HCR_data) && ~isstruct(HCR_data)
                error('HCR data must be a structure or empty, but received %s', class(HCR_data));
            end
            
            app.Data.HCR = HCR_data;
            if ~isempty(HCR_data) && ~isfield(HCR_data, 'filename')
                app.Data.HCR.filename = short_filename;
            end
            
            % Set MaxPowerNEditField if HCR data has max field
            if ~isempty(HCR_data) && isfield(HCR_data, 'max')
                app.MaxPowerNEditField.Value = HCR_data.max;
                fprintf('Set MaxPowerNEditField to: %.2f\n', HCR_data.max);
            end
        end

        %% MAIN UPDATE FUNCTION %%

        function refreshDisplay(app)
            % Main function to update all visual components of the app.
            % It orchestrates calculations, plot updates, and UI state changes.
            if isempty(app.Data) || ~isfield(app.Data, 'NIRS')
                return; % Do nothing if no data is loaded
            end
            
            performCalculations(app);
            updateNIRSPlots(app);
            updateHCRPlot(app);
            updateUIState(app);
        end

        %% CALCULATION METHODS %%
        
        function performCalculations(app)
            % Performs all NIRS and HCR calculations based on selected segments.
            
            % NIRS Calculations
            if isfield(app.Data.NIRS, 'baseline') && isfield(app.Data.NIRS, 'exercise')
                TSI = app.Data.NIRS.TSI;
                if app.filter.Value
                    % Apply filter if enabled
                    Fs = app.Data.NIRS.Fs;
                    Fp1 = app.lowpassHzSpinner_2.Value;
                    d = designfilt('lowpassfir', 'FilterOrder', 1000, ...
                        'CutoffFrequency', Fp1, 'SampleRate', Fs, 'DesignMethod', 'window');
                    TSI = filtfilt(d, TSI);
                end
                
                baseline_data = TSI(app.Data.NIRS.baseline);
                exercise_data = TSI(app.Data.NIRS.exercise);
                
                mean_baseline_TSI = mean(baseline_data);
                
                % Nadir calculation
                [min_exercise_TSI, idx_nadir] = min(exercise_data);
                app.Data.NIRS.reduction_nadir = 100 * (min_exercise_TSI - mean_baseline_TSI) / mean_baseline_TSI;
                
                time_to_nadir_idx = idx_nadir + app.Data.NIRS.exercise(1);
                exercise_start_idx = app.Data.NIRS.exercise(1);
                app.Data.NIRS.time_nadir = app.Data.NIRS.time(time_to_nadir_idx) - app.Data.NIRS.time(exercise_start_idx);
                
                % Area Under Curve (AUC) and Mean Reduction
                mean_exercise_TSI = mean(exercise_data);
                app.Data.NIRS.mean_reduction = 100 * (mean_exercise_TSI - mean_baseline_TSI) / mean_baseline_TSI;
                
                exercise_data_normalized = (exercise_data - mean_baseline_TSI) / mean_baseline_TSI;
                app.Data.NIRS.AUC = sum(exercise_data_normalized);
                
                % TSI Cumulative Sum at 30s intervals
                app.Data.NIRS.TSI_cumsum = cumsum(exercise_data_normalized);
                time_step = diff(app.Data.NIRS.time(1:2));
                interval_indices = round((30:30:180) / time_step);
                if interval_indices(end) > length(app.Data.NIRS.TSI_cumsum)
                    interval_indices(end) = length(app.Data.NIRS.TSI_cumsum);
                end
                app.Data.NIRS.TSI_halfmin = app.Data.NIRS.TSI_cumsum(interval_indices);
                
                % Total Hb (O2Hb + HHb) analysis
                O2Hb_exercise = app.Data.NIRS.absO2Hb(app.Data.NIRS.exercise);
                HHb_exercise = app.Data.NIRS.absHHb(app.Data.NIRS.exercise);
                TotalHb_exercise = O2Hb_exercise + HHb_exercise;
                
                % Apply same filter to Total Hb if enabled
                if app.filter.Value
                    TotalHb_exercise = filtfilt(d, TotalHb_exercise);
                end
                
                % Calculate baseline Total Hb for normalization
                O2Hb_baseline = app.Data.NIRS.absO2Hb(app.Data.NIRS.baseline);
                HHb_baseline = app.Data.NIRS.absHHb(app.Data.NIRS.baseline);
                TotalHb_baseline = O2Hb_baseline + HHb_baseline;
                
                if app.filter.Value
                    TotalHb_baseline = filtfilt(d, TotalHb_baseline);
                end
                
                mean_baseline_TotalHb = mean(TotalHb_baseline);
                
                % Total Hb normalized data and cumulative sum
                TotalHb_exercise_normalized = (TotalHb_exercise - mean_baseline_TotalHb) / mean_baseline_TotalHb;
                app.Data.NIRS.TotalHb_cumsum = cumsum(TotalHb_exercise_normalized);
                
                % Total Hb cumulative sum at 30s intervals
                if interval_indices(end) > length(app.Data.NIRS.TotalHb_cumsum)
                    interval_indices_TotalHb = interval_indices;
                    interval_indices_TotalHb(end) = length(app.Data.NIRS.TotalHb_cumsum);
                else
                    interval_indices_TotalHb = interval_indices;
                end
                app.Data.NIRS.TotalHb_halfmin = app.Data.NIRS.TotalHb_cumsum(interval_indices_TotalHb);
                
                % Recovery calculations (T50 and T100) if recovery data exists
                if isfield(app.Data.NIRS, 'recorvery') && ~isempty(app.Data.NIRS.recorvery)
                    recovery_data = TSI(app.Data.NIRS.recorvery);
                    recovery_time = app.Data.NIRS.time(app.Data.NIRS.recorvery);
                    
                    % Calculate target values for recovery
                    target_50 = mean_baseline_TSI - 0.5 * (mean_baseline_TSI - min_exercise_TSI);  % 50% recovery
                    target_100 = mean_baseline_TSI;  % 100% recovery (back to baseline)
                    
                    % Find T50 (time to 50% recovery)
                    recovery_start_time = app.Data.NIRS.time(app.Data.NIRS.exercise(end));
                    idx_50 = find(recovery_data >= target_50, 1, 'first');
                    if ~isempty(idx_50)
                        app.Data.NIRS.T50 = recovery_time(idx_50) - recovery_start_time;
                    else
                        app.Data.NIRS.T50 = NaN;  % Recovery to 50% not achieved
                    end
                    
                    % Find T100 (time to 100% recovery)
                    idx_100 = find(recovery_data >= target_100, 1, 'first');
                    if ~isempty(idx_100)
                        app.Data.NIRS.T100 = recovery_time(idx_100) - recovery_start_time;
                    else
                        app.Data.NIRS.T100 = NaN;  % Full recovery not achieved
                    end
                    
                else
                    app.Data.NIRS.T50 = NaN;
                    app.Data.NIRS.T100 = NaN;
                end
            end

            % HCR Calculations
            if isfield(app.Data, 'HCR') && ~isempty(app.Data.HCR) && isfield(app.Data.HCR, 'SumN')
                if ~isfield(app.Data.HCR, 'max')
                    app.Data.HCR.max = max(app.Data.HCR.SumN);
                end
                
                % Cumulative Sum at 30s intervals
                dt = app.Data.HCR.dt;
                app.Data.HCR.cumsum = cumsum(app.Data.HCR.SumN * dt);
                interval_indices = round((30:30:180) / dt);
                
                % Ensure interval_indices don't exceed the cumsum array length
                valid_indices = interval_indices <= length(app.Data.HCR.cumsum);
                if any(~valid_indices)
                    fprintf('Warning: Some HCR interval indices exceed data length. Adjusting...\n');
                    interval_indices = interval_indices(valid_indices);
                    if isempty(interval_indices)
                        % If no valid indices, use the last available index
                        interval_indices = length(app.Data.HCR.cumsum);
                    end
                end
                
                app.Data.HCR.halfmin = app.Data.HCR.cumsum(interval_indices);
                % Pad with NaN if we have fewer than 6 values (30s, 60s, 90s, 120s, 150s, 180s)
                if length(app.Data.HCR.halfmin) < 6
                    app.Data.HCR.halfmin(end+1:6) = NaN;
                end
                
                % Time on Target calculation with bounds checking
                if app.MaxPowerNEditField.Value > 0  % Only if max power is set
                    max_power = app.MaxPowerNEditField.Value;
                    low_thresh = app.HCR_TARGET_LOW_PERCENT * max_power;
                    high_thresh = app.HCR_TARGET_HIGH_PERCENT * max_power;
                    
                    on_target_binary = app.Data.HCR.SumN > low_thresh & app.Data.HCR.SumN < high_thresh;
                    alltarget = cumsum(on_target_binary) * dt;
                    
                    aux = round((0:30:180) / dt);
                    aux(1) = 1;
                    
                    % Ensure aux indices don't exceed alltarget length
                    valid_aux = aux <= length(alltarget);
                    if any(~valid_aux)
                        fprintf('Warning: Some target calculation indices exceed data length. Adjusting...\n');
                        aux = aux(valid_aux);
                    end
                    
                    if length(aux) > 1
                        app.Data.HCR.target = diff(alltarget(aux));
                        % Pad with NaN if we have fewer than 6 values
                        if length(app.Data.HCR.target) < 6
                            app.Data.HCR.target(end+1:6) = NaN;
                        end
                    else
                        app.Data.HCR.target = zeros(1, 6);  % Default to zeros if calculation fails
                    end
                end
            end
        end

        %% PLOTTING METHODS %%

        function updateNIRSPlots(app)
            % Updates the NIRS plots (ax1 and ax2).
            
            % Extract data, applying filter if necessary
            O2Hb = app.Data.NIRS.absO2Hb; 
            HHb = app.Data.NIRS.absHHb;
            TSI = app.Data.NIRS.TSI;
            time = app.Data.NIRS.time;
            
            if app.filter.Value
                Fs = app.Data.NIRS.Fs;
                Fp1 = app.lowpassHzSpinner_2.Value;
                d = designfilt('lowpassfir', 'FilterOrder', 1000, 'CutoffFrequency', Fp1, 'SampleRate', Fs, 'DesignMethod','window');
                O2Hb = filtfilt(d,O2Hb);
                HHb = filtfilt(d,HHb);
                TSI = filtfilt(d,TSI);
            end

            % --- Plot ax1: Oxy and Deoxy Hb ---
            cla(app.ax1);
            yyaxis(app.ax1, "left");
            hold(app.ax1, 'on');
            plot(app.ax1, time, O2Hb, 'r-', 'DisplayName', 'O2Hb');
            plot(app.ax1, time, HHb, 'b-', 'DisplayName', 'HHb');
            plot(app.ax1, time, O2Hb + HHb, 'k-', 'DisplayName', 'Total Hb');
            ylabel(app.ax1, 'Concentration (\mug)');
            legend(app.ax1, 'Location', 'northwest');
            hold(app.ax1, 'off');
            
            % --- Plot ax2: TSI ---
            cla(app.ax2);
            yyaxis(app.ax2, "left");
            plot(app.ax2, time, TSI, 'k', 'DisplayName', 'TSI');
            ylabel(app.ax2, 'TSI (%)');
            hold(app.ax2, 'on');

            % Plot selected segments
            if isfield(app.Data.NIRS, 'baseline')
                plot(app.ax2, time(app.Data.NIRS.baseline), TSI(app.Data.NIRS.baseline), 'b-', 'LineWidth', 2, 'DisplayName', 'Baseline');
            end
            if isfield(app.Data.NIRS, 'exercise')
                plot(app.ax2, time(app.Data.NIRS.exercise), TSI(app.Data.NIRS.exercise), 'g-', 'LineWidth', 2, 'DisplayName', 'Exercise');
            end
            if isfield(app.Data.NIRS, 'recorvery')
                plot(app.ax2, time(app.Data.NIRS.recorvery), TSI(app.Data.NIRS.recorvery), 'm-', 'LineWidth', 2, 'DisplayName', 'Recovery');
            end
            
            % Plot annotations if baseline and exercise are selected
            if isfield(app.Data.NIRS, 'baseline') && isfield(app.Data.NIRS, 'exercise')
                mean_baseline_TSI = mean(TSI(app.Data.NIRS.baseline));
                [min_exercise_TSI, idx_nadir] = min(TSI(app.Data.NIRS.exercise));
                time_at_nadir = app.Data.NIRS.time(app.Data.NIRS.exercise(1) + idx_nadir -1);
                
                % Mark nadir point
                plot(app.ax2, time_at_nadir, min_exercise_TSI, 'r*', 'MarkerSize', 10, 'DisplayName', 'Nadir');
                
                % Add recovery target lines and T50/T100 markers if recovery exists
                if isfield(app.Data.NIRS, 'recorvery') && ~isempty(app.Data.NIRS.recorvery)
                    recovery_time = app.Data.NIRS.time(app.Data.NIRS.recorvery);
                    x_lim_recovery = [recovery_time(1), recovery_time(end)];
                    
                    % 50% recovery line
                    target_50 = mean_baseline_TSI - 0.5 * (mean_baseline_TSI - min_exercise_TSI);
                    plot(app.ax2, x_lim_recovery, [target_50, target_50], 'g--', 'LineWidth', 1, 'DisplayName', '50% Recovery Target');
                    
                    % 100% recovery line (baseline)
                    plot(app.ax2, x_lim_recovery, [mean_baseline_TSI, mean_baseline_TSI], 'b--', 'LineWidth', 1, 'DisplayName', '100% Recovery Target');
                    
                    % Mark T50 and T100 as vertical lines if achieved
                    y_limits = ylim(app.ax2);
                    if isfield(app.Data.NIRS, 'T50') && ~isnan(app.Data.NIRS.T50)
                        t50_time = app.Data.NIRS.time(app.Data.NIRS.exercise(end)) + app.Data.NIRS.T50;
                        plot(app.ax2, [t50_time, t50_time], y_limits, 'g-', 'LineWidth', 2, 'DisplayName', 'T50');
                    end
                    
                    if isfield(app.Data.NIRS, 'T100') && ~isnan(app.Data.NIRS.T100)
                        t100_time = app.Data.NIRS.time(app.Data.NIRS.exercise(end)) + app.Data.NIRS.T100;
                        plot(app.ax2, [t100_time, t100_time], y_limits, 'b-', 'LineWidth', 2, 'DisplayName', 'T100');
                    end
                end
                
                % Set up relative y-axis
                yyaxis(app.ax2, "right");
                current_ylim = get(app.ax2, 'YLim');
                current_ytick = get(app.ax2, 'YTick');
                relative_ticks = 100 * (current_ytick - mean_baseline_TSI) / mean_baseline_TSI;
                yticklabels(app.ax2, sprintfc('%.1f', relative_ticks));
                ylabel(app.ax2, 'Reduction (%)');
            else
                yyaxis(app.ax2, "right");
                yticklabels(app.ax2, []);
            end
            
            hold(app.ax2, 'off');
            linkaxes([app.ax1, app.ax2], 'x');
        end
        
        function updateHCRPlot(app)
            % Updates the HCR plot (ax3).
            cla(app.ax3);
            if ~isfield(app.Data, 'HCR') || isempty(app.Data.HCR) || ~isfield(app.Data.HCR, 'SumN')
                title(app.ax3, 'HCR Data - No Data Loaded');
                return;
            end
            
            hold(app.ax3, 'on');
            plot(app.ax3, app.Data.HCR.Time, app.Data.HCR.SumN, 'DisplayName', 'HCR Power');
            
            % Plot target range
            max_power = app.MaxPowerNEditField.Value;
            x_lim = [app.Data.HCR.Time(1), app.Data.HCR.Time(end)];
            y1 = [app.HCR_TARGET_LOW_PERCENT * max_power, app.HCR_TARGET_LOW_PERCENT * max_power];
            y2 = [app.HCR_TARGET_HIGH_PERCENT * max_power, app.HCR_TARGET_HIGH_PERCENT * max_power];
            
            plot(app.ax3, x_lim, y1, 'r--', 'LineWidth', 1);
            plot(app.ax3, x_lim, y2, 'r--', 'LineWidth', 1);
            
            % Shade the target area
            fill(app.ax3, [x_lim, fliplr(x_lim)], [y1, fliplr(y2)], 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.1, 'DisplayName', 'Target Zone');
            
            ylabel(app.ax3, 'Power (N)');
            xlabel(app.ax3, 'Time (s)');
            title(app.ax3, 'HCR Data');

            % Only show legend for HCR Power and Target Zone
            h_fill = findobj(app.ax3, 'Type', 'Patch');
            legend(h_fill(1), 'Target Zone', 'Location', 'best');
            hold(app.ax3, 'off');
        end

        %% UI STATE MANAGEMENT %%
        
        function updateUIState(app)
            % Updates the state of UI controls (labels, buttons) based on app.Data.
            
            % Panels and file info
            app.FilterPanel.Visible = 'on';
            app.SelectsegmentsPanel.Visible = 'on';
            app.fileLabel.Text = app.Data.NIRS.filename;
            
            % NIRS value labels
            if isfield(app.Data.NIRS, 'TSI_halfmin') && isfield(app.Data.NIRS, 'TotalHb_halfmin')
                app.NIRS_value.Text = sprintf('TSI - 30s: %.2f, 60s: %.2f, 90s: %.2f, 120s: %.2f, 150s: %.2f, 180s: %.2f \nTotalHb - 30s: %.2f, 60s: %.2f, 90s: %.2f, 120s: %.2f, 150s: %.2f, 180s: %.2f', ...
                    app.Data.NIRS.TSI_halfmin, app.Data.NIRS.TotalHb_halfmin);
                
                % Nadir display (exercise-related)
                nadir_text = sprintf('Reduction of %.2f %% after %.1f s', app.Data.NIRS.reduction_nadir, app.Data.NIRS.time_nadir);
                app.NIRS_nadir_value.Text = nadir_text;
                
                % Recovery display (recovery-related)
                if isfield(app.Data.NIRS, 'T50') && isfield(app.Data.NIRS, 'T100')
                    recovery_text = '';
                    if ~isnan(app.Data.NIRS.T50)
                        recovery_text = sprintf('T50: %.1f s', app.Data.NIRS.T50);
                    else
                        recovery_text = 'T50: Not achieved';
                    end
                    
                    if ~isnan(app.Data.NIRS.T100)
                        recovery_text = [recovery_text, sprintf(', T100: %.1f s', app.Data.NIRS.T100)];
                    else
                        recovery_text = [recovery_text, ', T100: Not achieved'];
                    end
                    app.NIRS_recovery_value.Text = recovery_text;
                else
                    app.NIRS_recovery_value.Text = 'Recovery analysis not performed';
                end
            else
                app.NIRS_value.Text = 'Segments not selected';
                app.NIRS_nadir_value.Text = 'Segments not selected';
                app.NIRS_recovery_value.Text = 'Segments not selected';
            end
            
            % HCR value labels and controls
            if isfield(app.Data, 'HCR') && ~isempty(app.Data.HCR) && isfield(app.Data.HCR, 'halfmin')
                app.HCR_value.Text = sprintf('30s: %.2f, 60s: %.2f, 90s: %.2f, 120s: %.2f, 150s: %.2f, 180s: %.2f', app.Data.HCR.halfmin);
                app.HCRfilename.Text = app.Data.HCR.filename;
                app.MaxPowerNEditField.Enable = 'on';
                app.CalculateButton.Enable = 'on';
                app.MaxPowerNEditField.Value = app.Data.HCR.max;
            else
                app.HCR_value.Text = 'No HCR selected';
                app.HCRfilename.Text = '';
                app.MaxPowerNEditField.Enable = 'off';
                app.CalculateButton.Enable = 'off';
            end
            
            if isfield(app.Data, 'HCR') && ~isempty(app.Data.HCR) && isfield(app.Data.HCR, 'target')
                app.HCR_on_target.Text = sprintf('On Target (s):\n30s: %.2f, 60s: %.2f\n90s: %.2f, 120s: %.2f\n150s: %.2f, 180s: %.2f', app.Data.HCR.target);
            else
                app.HCR_on_target.Text = '';
            end

            % Enable/disable main action buttons
            app.SaveICON.Enable = 'on';
            app.refreshICON.Enable = 'on';
            app.HCR.Enable = 'on';
            
            can_save_csv = isfield(app.Data.NIRS, 'recorvery') && ...
                           isfield(app.Data.NIRS, 'TSI_halfmin') && ...
                           isfield(app.Data.NIRS, 'TotalHb_halfmin') && ...
                           isfield(app.Data, 'HCR') && ~isempty(app.Data.HCR) && ...
                           isfield(app.Data.HCR, 'target');
            app.save_csv.Enable = matlab.lang.OnOffSwitchState(can_save_csv);
            app.SaveCSVButton.Enable = matlab.lang.OnOffSwitchState(can_save_csv);
        end

        %% HELPER FUNCTIONS %%
        
        function time_indices = selectTimeSegment(app)
            % Opens ginput for the user to select a time range on ax2
            % and returns the corresponding data indices.
            time_indices = [];
            try
                % Set up figure handle visibility, run ginput, and return state
                fhv = app.UIFigure.HandleVisibility;        % Current status
                app.UIFigure.HandleVisibility = 'callback'; % Temp change (or, 'on') 
                set(0, 'CurrentFigure', app.UIFigure)       % Make fig current
                [x_coords, ~] = ginput(2);
                app.UIFigure.HandleVisibility = fhv;        % return original state

                if length(x_coords) < 2
                    return; % User cancelled or didn't select two points
                end

                time_indices = find(app.Data.NIRS.time > min(x_coords) & app.Data.NIRS.time < max(x_coords));
            catch ME
                uialert(app.UIFigure, ['Could not select segment: ' ME.message], 'Selection Error');
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Initialize app state
            app.Data = [];
        end

        % --- TOOLBAR CALLBACKS --- %

        function ConvertMenuSelected(app, event)
            % Callback for the 'Convert' toolbar button.
            % Converts .oxy files to .mat format.
            
            % Check for dependency
            if ~exist('oxysoft2matlab', 'file')
                uialert(app.UIFigure, ...
                    'The "oxysoft2matlab" function was not found. Please add it to your MATLAB path.', ...
                    'Dependency Missing');
                return;
            end

            % Get input file
            [oxy_file, oxy_path] = uigetfile({'*.oxy3;*.oxy4;*.oxy5', 'Oxysoft Files'}, 'Select Oxysoft Data File');
            if isequal(oxy_file, 0); return; end
            full_oxy_path = fullfile(oxy_path, oxy_file);

            % Get project file
            [proj_file, proj_path] = uigetfile('*.oxyproj', 'Select Oxysoft Project File');
            if isequal(proj_file, 0); return; end
            full_proj_path = fullfile(proj_path, proj_file);

            % Get save location
            [save_file, save_path] = uiputfile('*.mat', 'Save Converted NIRS Data As', [oxy_file(1:end-5) '.mat']);
            if isequal(save_file, 0); return; end
            full_save_path = fullfile(save_path, save_file);
            
            % Perform conversion
            try
                uiprogress(app.UIFigure, 'Title', 'Converting Oxysoft File...', 'Message', 'This may take a moment.');
                [nirs_data, events] = oxysoft2matlab(full_oxy_path, 'oxy/dxy', full_save_path, true, full_proj_path);
                nirs_data.events = events;
                nirs_data.filename = save_file;
                
                % Load data into app
                resetAppData(app);
                loadNIRSData(app, nirs_data, save_file);
                refreshDisplay(app);
                uialert(app.UIFigure, 'Conversion successful!', 'Success');
            catch ME
                uialert(app.UIFigure, ['File conversion failed: ' ME.message], 'Conversion Error');
            end
            close(uiprogress);
        end

        function OpenMenuSelected(app, event)
            % Callback for the 'Open' toolbar button.
            % Loads a previously saved .mat file containing NIRS/HCR data.
            [filename, pathname] = uigetfile({'*.mat', 'MAT-files (*.mat)'}, 'Select Saved Data File');
            if isequal(filename, 0); return; end
            
            try
                loaded_data = load(fullfile(pathname, filename));
                resetAppData(app);
                
                % Debug: Check what variables are in the loaded file
                fprintf('Variables in loaded file: %s\n', strjoin(fieldnames(loaded_data), ', '));
                
                if isfield(loaded_data, 'nirs_data')
                    % Debug: Check the type of nirs_data
                    fprintf('nirs_data type: %s\n', class(loaded_data.nirs_data));
                    if isstruct(loaded_data.nirs_data)
                        fprintf('nirs_data fields: %s\n', strjoin(fieldnames(loaded_data.nirs_data), ', '));
                    end
                    loadNIRSData(app, loaded_data.nirs_data, filename);
                else
                    uialert(app.UIFigure, 'The selected file does not contain "nirs_data".', 'Loading Error');
                    return;
                end
                
                if isfield(loaded_data, 'HCR_data')
                    % Debug: Check the type of HCR_data
                    fprintf('HCR_data type: %s\n', class(loaded_data.HCR_data));
                    if isstruct(loaded_data.HCR_data)
                        fprintf('HCR_data fields: %s\n', strjoin(fieldnames(loaded_data.HCR_data), ', '));
                        % Check if HCR_data has filename field before accessing it
                        if isfield(loaded_data.HCR_data, 'filename')
                            loadHCRData(app, loaded_data.HCR_data, loaded_data.HCR_data.filename);
                        else
                            loadHCRData(app, loaded_data.HCR_data, 'Unknown HCR file');
                        end
                    else
                        loadHCRData(app, loaded_data.HCR_data, 'Unknown HCR file');
                    end
                end
                
                refreshDisplay(app);
            catch ME
                % More detailed error reporting
                fprintf('Error details:\n');
                fprintf('Message: %s\n', ME.message);
                fprintf('Identifier: %s\n', ME.identifier);
                fprintf('Stack trace:\n');
                for i = 1:length(ME.stack)
                    fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
                end
                uialert(app.UIFigure, ['Failed to load file: ' ME.message], 'Loading Error');
            end
        end

        function SaveICONClicked(app, event)
            % Callback for the 'Save' toolbar button.
            % Saves the current app data (NIRS and HCR) to a .mat file.
            if isempty(app.Data); return; end
            
            default_name = [app.Data.NIRS.filename(1:end-4) '_app.mat'];
            [filename, pathname] = uiputfile('*.mat', 'Save Session As', default_name);
            if isequal(filename, 0); return; end
            
            try
                nirs_data = app.Data.NIRS; %#ok<NASGU>
                HCR_data = app.Data.HCR; %#ok<NASGU>
                save(fullfile(pathname, filename), "nirs_data", "HCR_data");
                uialert(app.UIFigure, 'Session saved successfully.', 'Save Complete');
            catch ME
                uialert(app.UIFigure, ['Could not save session: ' ME.message], 'Save Error');
            end
        end

        function save_csvClicked(app, event)
            % Callback for 'Save CSV' button. Appends current results to a CSV file.
            
            % Check if required data exists
            if ~isfield(app.Data.NIRS, 'recorvery')
                uialert(app.UIFigure, 'Please select all NIRS segments (baseline, exercise, recovery) before saving.', 'Data Missing');
                return;
            end
            
            if ~isfield(app.Data.NIRS, 'TSI_halfmin') || ~isfield(app.Data.NIRS, 'TotalHb_halfmin')
                uialert(app.UIFigure, 'NIRS analysis not complete. Please ensure all segments are selected and calculations performed.', 'Analysis Missing');
                return;
            end
            
            if ~isfield(app.Data, 'HCR') || isempty(app.Data.HCR) || ~isfield(app.Data.HCR, 'target')
                uialert(app.UIFigure, 'Please load and process HCR data before saving.', 'HCR Data Missing');
                return;
            end
            
            [file, path] = uigetfile('*.csv', 'Select (data will be appended) or Create Output CSV File', 'NIRS_HCR_output.csv');
            if isequal(file, 0); return; end
            csv_filename = fullfile(path, file);

            % Check if file exists and inform user about appending
            if exist(csv_filename, 'file')
                choice = uiconfirm(app.UIFigure, ...
                    sprintf('The file "%s" already exists. Your data will be appended as a new row to the existing data.', file), ...
                    'Append to Existing File', ...
                    'Options', {'Continue', 'Cancel'}, ...
                    'DefaultOption', 'Continue', ...
                    'Icon', 'info');
                if strcmp(choice, 'Cancel')
                    return;
                end
            end

            % Define table structure with clear TSI and TotalHb labeling
            var_names = {'NIRS_filename', 'NIRS_reduction', 'TimeNadir','MeanRed', ...
                         'TSI_30s','TSI_60s','TSI_90s','TSI_120s','TSI_150s','TSI_180s', ...
                         'TotalHb_30s','TotalHb_60s','TotalHb_90s','TotalHb_120s','TotalHb_150s','TotalHb_180s', ...
                         'T50', 'T100', ...
                         'HCR_filename','HCR_30s','HCR_60s','HCR_90s','HCR_120s','HCR_150s','HCR_180s','Max_HCR',...
                         'HCR_target_30s','HCR_target_60s','HCR_target_90s','HCR_target_120s','HCR_target_150s','HCR_target_180s'};
            var_types = {'string', 'double','double','double', ...
                         'double','double','double','double','double','double', ...
                         'double','double','double','double','double','double', ...
                         'double', 'double', ...
                         'string','double','double','double','double','double','double','double','double','double','double','double','double','double'};

            % Read existing table or create a new one
            if exist(csv_filename, 'file')
                try
                    output_table = readtable(csv_filename);
                catch ME
                    uialert(app.UIFigure, ['Could not read existing CSV file. Please check the file. Error: ' ME.message], 'CSV Error');
                    return;
                end
            else
                output_table = table('Size', [0, length(var_names)], 'VariableTypes', var_types, 'VariableNames', var_names);
            end
            
            % Create new row by expanding the arrays into individual cells
            TSI_halfmin_cell = num2cell(app.Data.NIRS.TSI_halfmin);
            TotalHb_halfmin_cell = num2cell(app.Data.NIRS.TotalHb_halfmin);
            hcr_halfmin_cell = num2cell(app.Data.HCR.halfmin);
            hcr_target_cell = num2cell(app.Data.HCR.target);

            newRow = {app.Data.NIRS.filename, ...
                      app.Data.NIRS.reduction_nadir, ...
                      app.Data.NIRS.time_nadir, ...
                      app.Data.NIRS.mean_reduction, ...
                      TSI_halfmin_cell{:}, ...
                      TotalHb_halfmin_cell{:}, ...
                      app.Data.NIRS.T50, ...
                      app.Data.NIRS.T100, ...
                      app.Data.HCR.filename, ...
                      hcr_halfmin_cell{:}, ...
                      app.Data.HCR.max, ...
                      hcr_target_cell{:}};
            
            % Append and write
            try
                output_table = [output_table; newRow];
                writetable(output_table, csv_filename);
                uialert(app.UIFigure, 'Data successfully appended to CSV.', 'Save Complete');
            catch ME
                uialert(app.UIFigure, ['Could not write to CSV file. Is it open in another program? Error: ' ME.message], 'CSV Write Error');
            end
        end

        function HCRClicked(app, event)
            % Callback for 'Load HCR' toolbar button.
            [filename, pathname] = uigetfile('*.*', 'Select HCR Data File');
            if isequal(filename, 0); return; end
            
            opts = delimitedTextImportOptions("NumVariables", 4, "DataLines", [2, Inf], "Delimiter", ",", ...
                "VariableNames", ["Time", "LoadCell1ForceN", "LoadCell2ForceN", "SumN"], ...
                "VariableTypes", ["double", "double", "double", "double"], ...
                "ExtraColumnsRule", "ignore", "EmptyLineRule", "read");
            
            try
                tbl = readtable(fullfile(pathname, filename), opts);
                app.Data.HCR.filename = filename;
                app.Data.HCR.Time = tbl.Time;
                app.Data.HCR.SumN = tbl.SumN;
                app.Data.HCR.dt = diff(app.Data.HCR.Time(1:2));
                app.Data.HCR.fs = 1 / app.Data.HCR.dt;
                app.Data.HCR.max = max(app.Data.HCR.SumN);
                
                refreshDisplay(app);
            catch ME
                uialert(app.UIFigure, ['Failed to import HCR data: ' ME.message], 'Import Error');
            end
        end

        function refreshICONButtonPushed(app, event)
            refreshDisplay(app);
        end

        % --- UI CONTROL CALLBACKS --- %

        function CalculateButtonPushed(app, event)         
            % Only perform calculation if HCR data exists and is not empty
            if isfield(app.Data, 'HCR') && ~isempty(app.Data.HCR) && isfield(app.Data.HCR, 'SumN')
                app.Data.HCR.max = get(app.MaxPowerNEditField, 'value');
                refreshDisplay(app); % Recalculate and replot with new max power
            else
                uialert(app.UIFigure, 'No HCR data loaded. Please load HCR data first.', 'HCR Data Missing');
            end
        end

        function BaselineButtonPushed(app, event)
            app.Data.NIRS.baseline = selectTimeSegment(app);
            refreshDisplay(app);
        end

        function ExerciseButtonPushed(app, event)
            exercise_indices = selectTimeSegment(app);
            if ~isempty(exercise_indices)
                app.Data.NIRS.exercise = exercise_indices;
                
                % Automatically define recovery as from end of exercise to end of data
                if ~isempty(exercise_indices)
                    recovery_start = exercise_indices(end) + 1;
                    recovery_end = length(app.Data.NIRS.time);
                    if recovery_start <= recovery_end
                        app.Data.NIRS.recorvery = recovery_start:recovery_end;
                        fprintf('Recovery automatically set from index %d to %d\n', recovery_start, recovery_end);
                    else
                        app.Data.NIRS.recorvery = []; % No recovery data available
                        fprintf('Warning: No recovery data available after exercise\n');
                    end
                end
            end
            refreshDisplay(app);
        end

        function filterValueChanged(app, event)
            app.lowpassHzSpinner_2.Enable = app.filter.Value;
            refreshDisplay(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1186 544];
            app.UIFigure.Name = 'NIRS & HCR Analysis Tool';

            % Create Toolbar
            app.Toolbar = uitoolbar(app.UIFigure);
            app.Toolbar.BackgroundColor = [0.9608 0.9608 0.9608];

            % Create convertICON
            app.convertICON = uipushtool(app.Toolbar);
            app.convertICON.Tag = 'Convert';
            app.convertICON.Tooltip = {'Convert .oxy file to .mat'};
            app.convertICON.ClickedCallback = createCallbackFcn(app, @ConvertMenuSelected, true);
            app.convertICON.Icon = 'ICON_convert.png';
            app.convertICON.Separator = 'on';

            % Create openICON
            app.openICON = uipushtool(app.Toolbar);
            app.openICON.Tag = 'Open';
            app.openICON.Tooltip = {'Open existing .mat session'};
            app.openICON.ClickedCallback = createCallbackFcn(app, @OpenMenuSelected, true);
            app.openICON.Icon = 'ICON_open.png';
            app.openICON.Separator = 'on';

            % Create SaveICON
            app.SaveICON = uipushtool(app.Toolbar);
            app.SaveICON.Tag = 'Save';
            app.SaveICON.Tooltip = {'Save current session to .mat'};
            app.SaveICON.ClickedCallback = createCallbackFcn(app, @SaveICONClicked, true);
            app.SaveICON.Enable = 'off';
            app.SaveICON.Icon = 'ICON_save.png';
            app.SaveICON.Separator = 'on';

            % Create HCR
            app.HCR = uipushtool(app.Toolbar);
            app.HCR.Tooltip = {'Load HCR data from a text/csv file'};
            app.HCR.ClickedCallback = createCallbackFcn(app, @HCRClicked, true);
            app.HCR.Enable = 'off';
            app.HCR.Icon = 'ICON_loadHCR.png'; % Assumes this is in the path
            app.HCR.Separator = 'on';

            % Create save_csv
            app.save_csv = uipushtool(app.Toolbar);
            app.save_csv.Tag = 'csv';
            app.save_csv.Tooltip = {'Save results to CSV file'};
            app.save_csv.ClickedCallback = createCallbackFcn(app, @save_csvClicked, true);
            app.save_csv.Enable = 'off';
            app.save_csv.Icon = 'ICON_CSV.png';

            % Create refreshICON
            app.refreshICON = uipushtool(app.Toolbar);
            app.refreshICON.Tag = 'refresh';
            app.refreshICON.Tooltip = {'Refresh plots and calculations'};
            app.refreshICON.ClickedCallback = createCallbackFcn(app, @refreshICONButtonPushed, true);
            app.refreshICON.Enable = 'off';
            app.refreshICON.Icon = 'ICON_refresh.png';
            app.refreshICON.Separator = 'on';

            % Create ax3
            app.ax3 = uiaxes(app.UIFigure);
            title(app.ax3, 'HCR')
            xlabel(app.ax3, 'Time (s)')
            ylabel(app.ax3, 'Power (N)')
            app.ax3.Position = [635 330 538 213];

            % Create ax2
            app.ax2 = uiaxes(app.UIFigure);
            title(app.ax2, 'TSI')
            xlabel(app.ax2, 'Time (s)')
            ylabel(app.ax2, 'TSI (%)')
            app.ax2.Position = [14 56 609 245];

            % Create ax1
            app.ax1 = uiaxes(app.UIFigure);
            title(app.ax1, 'Oxy and Deoxy Hb')
            xlabel(app.ax1, 'Time (s)')
            ylabel(app.ax1, 'Concentration (\mug)')
            app.ax1.Position = [14 300 609 242];

            % Create FilterPanel
            app.FilterPanel = uipanel(app.UIFigure);
            app.FilterPanel.Title = 'Filter';
            app.FilterPanel.Visible = 'off';
            app.FilterPanel.Position = [14 0 171 53];

            % Create filter
            app.filter = uicheckbox(app.FilterPanel);
            app.filter.ValueChangedFcn = createCallbackFcn(app, @filterValueChanged, true);
            app.filter.Text = '';
            app.filter.Position = [46 30 25 22];

            % Create lowpassHzSpinner_2Label
            app.lowpassHzSpinner_2Label = uilabel(app.FilterPanel);
            app.lowpassHzSpinner_2Label.HorizontalAlignment = 'right';
            app.lowpassHzSpinner_2Label.Enable = 'off';
            app.lowpassHzSpinner_2Label.Position = [9 7 78 22];
            app.lowpassHzSpinner_2Label.Text = 'low pass (Hz)';

            % Create lowpassHzSpinner_2
            app.lowpassHzSpinner_2 = uispinner(app.FilterPanel);
            app.lowpassHzSpinner_2.Step = 0.05;
            app.lowpassHzSpinner_2.Limits = [0.001 0.4];
            app.lowpassHzSpinner_2.ValueDisplayFormat = '%5.2f';
            app.lowpassHzSpinner_2.ValueChangedFcn = createCallbackFcn(app, @filterValueChanged, true);
            app.lowpassHzSpinner_2.Enable = 'off';
            app.lowpassHzSpinner_2.Position = [100 7 66 22];
            app.lowpassHzSpinner_2.Value = 0.2;

            % Create SelectsegmentsPanel
            app.SelectsegmentsPanel = uipanel(app.UIFigure);
            app.SelectsegmentsPanel.TitlePosition = 'centertop';
            app.SelectsegmentsPanel.Title = 'Select segments';
            app.SelectsegmentsPanel.Visible = 'off';
            app.SelectsegmentsPanel.Position = [195 0 213 53];

            % Create BaselineButton
            app.BaselineButton = uibutton(app.SelectsegmentsPanel, 'push');
            app.BaselineButton.ButtonPushedFcn = createCallbackFcn(app, @BaselineButtonPushed, true);
            app.BaselineButton.Position = [1 2 100 29];
            app.BaselineButton.Text = 'Baseline';

            % Create ExerciseButton
            app.ExerciseButton = uibutton(app.SelectsegmentsPanel, 'push');
            app.ExerciseButton.ButtonPushedFcn = createCallbackFcn(app, @ExerciseButtonPushed, true);
            app.ExerciseButton.Position = [105 2 100 29];
            app.ExerciseButton.Text = 'Exercise';

            % Create fileLabel
            app.fileLabel = uilabel(app.UIFigure);
            app.fileLabel.FontSize = 24;
            app.fileLabel.FontWeight = 'bold';
            app.fileLabel.Position = [420 2 304 51];
            app.fileLabel.Text = 'No file open';

            % Create HCRAUCLabel
            app.HCRAUCLabel = uilabel(app.UIFigure);
            app.HCRAUCLabel.FontWeight = 'bold';
            app.HCRAUCLabel.Position = [633 135 64 22];
            app.HCRAUCLabel.Text = 'HCR AUC:';

            % Create HCR_value
            app.HCR_value = uilabel(app.UIFigure);
            app.HCR_value.Position = [706 134 466 22];
            app.HCR_value.Text = 'No HCR selected';

            % Create HCRfilename
            app.HCRfilename = uilabel(app.UIFigure);
            app.HCRfilename.Position = [788 265 188 22];
            app.HCRfilename.Text = '';

            % Create MaxPowerNEditFieldLabel
            app.MaxPowerNEditFieldLabel = uilabel(app.UIFigure);
            app.MaxPowerNEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxPowerNEditFieldLabel.FontWeight = 'bold';
            app.MaxPowerNEditFieldLabel.Position = [632 299 92 22];
            app.MaxPowerNEditFieldLabel.Text = 'Max Power (N):';

            % Create MaxPowerNEditField
            app.MaxPowerNEditField = uieditfield(app.UIFigure, 'numeric');
            app.MaxPowerNEditField.FontWeight = 'bold';
            app.MaxPowerNEditField.Enable = 'off';
            app.MaxPowerNEditField.Position = [739 298 96 23];

            % Create CalculateButton
            app.CalculateButton = uibutton(app.UIFigure, 'push');
            app.CalculateButton.Enable = 'off';
            app.CalculateButton.Position = [850 297 65 25];
            app.CalculateButton.Text = 'Calculate!';
            app.CalculateButton.ButtonPushedFcn = createCallbackFcn(app, @CalculateButtonPushed, true);

            % Create HCR_on_target
            app.HCR_on_target = uilabel(app.UIFigure);
            app.HCR_on_target.Position = [953 280 210 66];
            app.HCR_on_target.Text = '';
            app.HCR_on_target.FontWeight = 'bold';
            app.HCR_on_target.VerticalAlignment = 'top';

            
            % Create SaveCSVButton
            app.SaveCSVButton = uibutton(app.UIFigure, 'push');
            app.SaveCSVButton.FontSize = 18;
            app.SaveCSVButton.FontWeight = 'bold';
            app.SaveCSVButton.Enable = 'off';
            app.SaveCSVButton.Position = [740 51 285 49];
            app.SaveCSVButton.Text = 'Save to CSV';
            app.SaveCSVButton.ButtonPushedFcn = createCallbackFcn(app, @save_csvClicked, true);
            

            % Create NIRS_Nadir
            app.NIRS_label_2 = uilabel(app.UIFigure);
            app.NIRS_label_2.FontWeight = 'bold';
            app.NIRS_label_2.Position = [633 182 72 22];
            app.NIRS_label_2.Text = 'NIRS Nadir:';

            % Create NIRS_nadir_value
            app.NIRS_nadir_value = uilabel(app.UIFigure);
            app.NIRS_nadir_value.Position = [706 182 466 22];
            app.NIRS_nadir_value.Text = 'No NIRS selected';
            
            % Create NIRS_Recovery
            app.NIRS_recovery_label = uilabel(app.UIFigure);
            app.NIRS_recovery_label.FontWeight = 'bold';
            app.NIRS_recovery_label.Position = [633 158 85 22];
            app.NIRS_recovery_label.Text = 'NIRS Recovery:';

            % Create NIRS_recovery_value
            app.NIRS_recovery_value = uilabel(app.UIFigure);
            app.NIRS_recovery_value.Position = [706 158 466 22];
            app.NIRS_recovery_value.Text = 'No NIRS selected';
            
            % Create NIRS_AUC
            app.NIRS_label = uilabel(app.UIFigure);
            app.NIRS_label.FontWeight = 'bold';
            app.NIRS_label.Position = [633 224 67 22];
            app.NIRS_label.Text = 'NIRS AUC:';

            % Create NIRS_value
            app.NIRS_value = uilabel(app.UIFigure);
            app.NIRS_value.Position = [706 212 500 44];
            app.NIRS_value.WordWrap = 'on';
            app.NIRS_value.Text = 'No NIRS selected';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = NIRS_HCR
            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
