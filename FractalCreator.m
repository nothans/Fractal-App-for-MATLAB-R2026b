classdef FractalCreator < matlab.apps.App

    % Used to locate and load the app's XML configuration file
    properties (Access = public, Constant)
        AppConfigFilename = './FractalCreator.xml'; % File path to the app configuration file containing component layout and settings
    end

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        MainGrid                        matlab.ui.container.GridLayout
        DisplayPanel                    matlab.ui.container.Panel
        DisplayGrid                     matlab.ui.container.GridLayout
        StatusLabel                     matlab.ui.control.Label
        UIAxes                          matlab.ui.control.UIAxes
        ControlPanel                    matlab.ui.container.Panel
        ControlGrid                     matlab.ui.container.GridLayout
        HintLabel                       matlab.ui.control.Label
        ActionGrid                      matlab.ui.container.GridLayout
        SaveButton                      matlab.ui.control.Button
        ResetViewButton                 matlab.ui.control.Button
        CancelButton                    matlab.ui.control.Button
        RenderButton                    matlab.ui.control.Button
        SmoothCheckBox                  matlab.ui.control.CheckBox
        InsideColorPicker               matlab.ui.control.ColorPicker
        InsideColorLabel                matlab.ui.control.Label
        OffsetSlider                    matlab.ui.control.Slider
        OffsetLabel                     matlab.ui.control.Label
        DensitySpinner                  matlab.ui.control.Spinner
        DensityLabel                    matlab.ui.control.Label
        ColormapDropDown                matlab.ui.control.DropDown
        ColormapLabel                   matlab.ui.control.Label
        ColorHeading                    matlab.ui.control.Label
        ResolutionDropDown              matlab.ui.control.DropDown
        ResolutionLabel                 matlab.ui.control.Label
        IterationsSpinner               matlab.ui.control.Spinner
        IterationsLabel                 matlab.ui.control.Label
        JuliaImSpinner                  matlab.ui.control.Spinner
        JuliaImLabel                    matlab.ui.control.Label
        JuliaReSpinner                  matlab.ui.control.Spinner
        JuliaReLabel                    matlab.ui.control.Label
        PowerSpinner                    matlab.ui.control.Spinner
        PowerLabel                      matlab.ui.control.Label
        PresetDropDown                  matlab.ui.control.DropDown
        PresetLabel                     matlab.ui.control.Label
        TypeDropDown                    matlab.ui.control.DropDown
        TypeLabel                       matlab.ui.control.Label
        FractalHeading                  matlab.ui.control.Label
    end

    properties (Access = private)
        Assembly = []
        ColorsChanged = false
        FractalImage = []
        FullViewMode = false
        PartsLeft = 0
        PendingSpec = []
        Presets = []
        RenderCancelled = false
        RenderError = []
        RenderStart = []
        RenderTask = struct('Fcn', [], 'CompleteFcn', [], 'ProgressFcn', [], 'Future', [], 'Queue', [], 'Running', false, 'StopRequested', false, 'Generation', 0)
        RenderTask2 = struct('Fcn', [], 'CompleteFcn', [], 'ProgressFcn', [], 'Future', [], 'Queue', [], 'Running', false, 'StopRequested', false, 'Generation', 0)
        RenderTask3 = struct('Fcn', [], 'CompleteFcn', [], 'ProgressFcn', [], 'Future', [], 'Queue', [], 'Running', false, 'StopRequested', false, 'Generation', 0)
        RenderTask4 = struct('Fcn', [], 'CompleteFcn', [], 'ProgressFcn', [], 'Future', [], 'Queue', [], 'Running', false, 'StopRequested', false, 'Generation', 0)
        RenderTask5 = struct('Fcn', [], 'CompleteFcn', [], 'ProgressFcn', [], 'Future', [], 'Queue', [], 'Running', false, 'StopRequested', false, 'Generation', 0)
        RenderTask6 = struct('Fcn', [], 'CompleteFcn', [], 'ProgressFcn', [], 'Future', [], 'Queue', [], 'Running', false, 'StopRequested', false, 'Generation', 0)
        RenderTask7 = struct('Fcn', [], 'CompleteFcn', [], 'ProgressFcn', [], 'Future', [], 'Queue', [], 'Running', false, 'StopRequested', false, 'Generation', 0)
        RenderTask8 = struct('Fcn', [], 'CompleteFcn', [], 'ProgressFcn', [], 'Future', [], 'Queue', [], 'Running', false, 'StopRequested', false, 'Generation', 0)
        RenderTasks = ["RenderTask" "RenderTask2" "RenderTask3" "RenderTask4" "RenderTask5" "RenderTask6" "RenderTask7" "RenderTask8"]
        Result = []
        RowsDone = 0
        View = []
    end

    methods (Access = private)

        function applyPreset(app, name)
        p = app.Presets(app.Presets.Type == app.TypeDropDown.Value & app.Presets.Name == name, :);
        if isempty(p)
            return
        end
        % A preset without a width is a full view, framed to fit the set when it renders.
        app.FullViewMode = isnan(p.Width);
        if ~app.FullViewMode
            app.View = struct(Center=p.Center, Width=p.Width);
        end
        app.IterationsSpinner.Value = p.Iterations;
        app.PowerSpinner.Value = p.Power;
        if ~isnan(p.JuliaC)
            app.JuliaReSpinner.Value = real(p.JuliaC);
            app.JuliaImSpinner.Value = imag(p.JuliaC);
        end
        app.updateEnables();
        end

        function presets = buildPresets(~)
        % Known views. The first row for each type is its full view. A NaN width
        % marks a full view, which fullView frames to fit the set; each Julia
        % preset is the full view of one constant.
        Type = ["Mandelbrot"; "Mandelbrot"; "Mandelbrot"; "Mandelbrot"; "Mandelbrot"; "Mandelbrot"
            "Julia"; "Julia"; "Julia"; "Julia"; "Julia"
            "Burning Ship"; "Burning Ship"; "Tricorn"; "Newton"];
        Name = ["Full set"; "Seahorse Valley"; "Elephant Valley"; "Spiral"; "Mini Mandelbrot"; "Branch junction"
            "Classic"; "Douady rabbit"; "Dendrite"; "Siegel disk"; "Spiral"
            "Full ship"; "Armada"; "Full set"; "Full view"];
        Center = [NaN; -0.7453 + 0.1127i; 0.2850 + 0.0110i; -0.77568377 + 0.13646737i; -1.7568; -0.1015 + 0.9563i
            NaN; NaN; NaN; NaN; NaN
            NaN; -1.755 + 0.02i; NaN; NaN];
        Width = [NaN; 0.012; 0.012; 0.0004; 0.08; 0.012
            NaN; NaN; NaN; NaN; NaN
            NaN; 0.10; NaN; NaN];
        Iterations = [300; 500; 500; 1200; 600; 800
            300; 300; 300; 400; 400
            200; 400; 200; 60];
        Power = [2; 2; 2; 2; 2; 2
            2; 2; 2; 2; 2
            2; 2; 2; 3];
        JuliaC = [NaN; NaN; NaN; NaN; NaN; NaN
            -0.8 + 0.156i; -0.123 + 0.745i; 1i; -0.391 - 0.587i; 0.285 + 0.01i
            NaN; NaN; NaN; NaN];
        presets = table(Type, Name, Center, Width, Iterations, Power, JuliaC);
        end

        function spec = buildSpec(app)
        % Collect the current settings into the struct the background task receives.
        w = app.ResolutionDropDown.Value;
        h = round(w * 3 / 4);
        halfW = app.View.Width / 2;
        halfH = halfW * h / w;
        c = app.View.Center;
        spec = app.fractalParams();
        spec.MaxIter = app.IterationsSpinner.Value;
        spec.Width = w;
        spec.Height = h;
        spec.XLim = real(c) + [-halfW halfW];
        spec.YLim = imag(c) + [-halfH halfH];
        spec.NumBands = 3;
        end

        function cancelRender(app)
        % Cancel every render task that is still running.
        for name = app.RenderTasks
            if app.(name).Running
                app.cancelBackground(name);
            end
        end
        end

        function rgb = colorize(app, values, inside, roots, spec, offset)
        % Map stored values to RGB. Escape-time fractals use a log-scaled, mirrored
        % colormap cycle; Newton colors each root's basin and darkens slow convergence.
        % Returns uint8 RGB, which is an eighth the size of double RGB to draw.
        cmap = single(feval(app.ColormapDropDown.Value, 256));
        density = app.DensitySpinner.Value;
        v = single(values);
        if spec.Type == "Newton"
            t = mod(offset + (single(roots) - 0.5) / spec.Power, 1);
            shade = 0.3 + 0.7 * exp(-v * density / 12);
        else
            if ~app.SmoothCheckBox.Value
                v = floor(v);
            end
            t = mod(offset + 4 * density * log1p(max(v, 0)) / log1p(spec.MaxIter), 1);
            t = 1 - abs(1 - 2 * t);
            shade = 1;
        end
        % One row per pixel: look up the colors, paint the inside pixels, then fold
        % the rows back into an image.
        rgb = cmap(1 + floor(t(:) * 255.999), :) .* shade(:);
        rgb(inside(:), :) = repmat(single(app.InsideColorPicker.Value), nnz(inside), 1);
        rgb = reshape(uint8(255 * rgb), [size(v) 3]);
        end

        function params = fractalParams(app)
        % The settings that define the set itself, independent of the view.
        params = struct(Type=string(app.TypeDropDown.Value), ...
            Power=app.PowerSpinner.Value, ...
            JuliaC=complex(app.JuliaReSpinner.Value, app.JuliaImSpinner.Value));
        end

        function name = fullViewPresetName(app)
        % Name the full-view preset that matches the current settings, so the
        % preset list stays accurate after Reset view or an edit to the Julia constant.
        params = app.fractalParams();
        p = app.Presets(app.Presets.Type == params.Type & isnan(app.Presets.Width), :);
        match = isnan(p.JuliaC) | (p.JuliaC == params.JuliaC & p.Power == params.Power);
        name = "Custom view";
        if any(match)
            name = p.Name(find(match, 1));
        end
        end

        function tf = isRendering(app)
        tf = false;
        for name = app.RenderTasks
            tf = tf || app.(name).Running;
        end
        end

        function onRenderComplete(app, part, error, wasCancelled)
        % Collect one finished part. When the last part reports, show the image,
        % or restore the previous one if the render was cancelled or failed.
        app.PartsLeft = app.PartsLeft - 1;
        if wasCancelled
            app.RenderCancelled = true;
        elseif ~isempty(error)
            app.RenderError = error;
        else
            app.Assembly.Values(part.Rows, :) = part.Values;
            app.Assembly.Inside(part.Rows, :) = part.Inside;
            app.Assembly.Roots(part.Rows, :) = part.Roots;
        end
        if app.PartsLeft > 0
            return
        end
        app.CancelButton.Enable = "off";
        if ~isempty(app.RenderError)
            uialert(app.UIFigure, app.RenderError.message, "Render failed");
        end
        if app.RenderCancelled || ~isempty(app.RenderError)
            if isempty(app.Result)
                app.StatusLabel.Text = "Render stopped. Press Render to start again.";
                return
            end
            app.View = app.viewFromSpec(app.Result.Spec);
            app.showResult(app.Result, app.OffsetSlider.Value);
            if app.RenderCancelled
                app.StatusLabel.Text = "Render cancelled. Showing the previous image. Press Render to apply the current settings.";
            else
                app.StatusLabel.Text = "Render failed. Showing the previous image.";
            end
            return
        end
        app.Result = struct(Values=app.Assembly.Values, Inside=app.Assembly.Inside, ...
            Roots=app.Assembly.Roots, Spec=app.PendingSpec, Seconds=toc(app.RenderStart));
        app.Assembly = [];
        % The bands already show these colors unless a color setting changed mid-render.
        if app.ColorsChanged
            app.showResult(app.Result, app.OffsetSlider.Value);
        end
        app.updateStatus();
        end

        function onRenderProgress(app, data)
        % Paint each finished band as it arrives and report overall progress.
        app.FractalImage.CData(data.Rows, :, :) = app.colorize(data.Values, data.Inside, ...
            data.Roots, app.PendingSpec, app.OffsetSlider.Value);
        app.RowsDone = app.RowsDone + numel(data.Rows);
        app.StatusLabel.Text = sprintf("Rendering %s: %d%%", app.PendingSpec.Type, ...
            floor(100 * app.RowsDone / app.PendingSpec.Height));
        end

        function openJulia(app, c)
        % Switch to the Julia set whose constant is the clicked point, framed to fit.
        lim = app.JuliaReSpinner.Limits;
        app.TypeDropDown.Value = "Julia";
        app.refreshPresetList();
        app.JuliaReSpinner.Value = min(max(real(c), lim(1)), lim(2));
        app.JuliaImSpinner.Value = min(max(imag(c), lim(1)), lim(2));
        app.FullViewMode = true;
        app.PresetDropDown.Value = app.fullViewPresetName();
        app.updateEnables();
        app.requestRender();
        end

        function recolor(app, offset)
        % Recolor the last finished render without recomputing. A render in
        % progress picks up the new colors when it completes.
        arguments
            app
            offset (1,1) double = app.OffsetSlider.Value
        end
        if app.isRendering()
            app.ColorsChanged = true;
            return
        end
        if isempty(app.Result)
            return
        end
        app.showResult(app.Result, offset);
        end

        function refreshPresetList(app)
        % Show the presets for the selected type, plus an entry for views reached by zooming.
        names = app.Presets.Name(app.Presets.Type == app.TypeDropDown.Value);
        app.PresetDropDown.Items = [names; "Custom view"];
        app.PresetDropDown.Value = names(1);
        end

        function requestRender(app)
        % Start a render with the current settings. A full view is refit to the
        % current set first. The rows are interleaved across the render tasks, so
        % each backgroundPool worker gets an even share of the expensive rows. A
        % render already running is cancelled first, so the newest settings always win.
        app.cancelRender();
        if app.FullViewMode
            app.View = FractalCreator.fullView(app.fractalParams());
        end
        spec = app.buildSpec();
        app.showPreview(spec);
        app.PendingSpec = spec;
        taskCount = numel(app.RenderTasks);
        app.PartsLeft = taskCount;
        app.RowsDone = 0;
        app.RenderCancelled = false;
        app.RenderError = [];
        app.ColorsChanged = false;
        app.Assembly = struct(Values=zeros(spec.Height, spec.Width, "single"), ...
            Inside=false(spec.Height, spec.Width), Roots=zeros(spec.Height, spec.Width, "uint8"));
        app.CancelButton.Enable = "on";
        app.StatusLabel.Text = sprintf("Rendering %s: 0%%", spec.Type);
        app.RenderStart = tic;
        for i = 1:taskCount
            part = spec;
            part.Rows = i:taskCount:spec.Height;
            app.startBackground(app.RenderTasks(i), part);
        end
        end

        function setImageView(app, spec)
        % Place the image at the view's coordinates; pixel centers sit on the grid.
        app.FractalImage.XData = spec.XLim;
        app.FractalImage.YData = spec.YLim;
        dx = diff(spec.XLim) / (spec.Width - 1) / 2;
        dy = diff(spec.YLim) / (spec.Height - 1) / 2;
        app.UIAxes.XLim = spec.XLim + [-dx dx];
        app.UIAxes.YLim = spec.YLim + [-dy dy];
        end

        function showPreview(app, spec)
        % Crop and scale the current image into the new view as a placeholder
        % until the new bands arrive. Areas outside the old image are gray.
        img = app.FractalImage;
        old = img.CData;
        [oh, ow, ~] = size(old);
        x = linspace(spec.XLim(1), spec.XLim(2), spec.Width);
        y = linspace(spec.YLim(1), spec.YLim(2), spec.Height);
        ox = img.XData;
        oy = img.YData;
        ix = round(1 + (x - ox(1)) / max(diff(ox), eps) * (ow - 1));
        iy = round(1 + (y - oy(1)) / max(diff(oy), eps) * (oh - 1));
        okx = ix >= 1 & ix <= ow;
        oky = iy >= 1 & iy <= oh;
        preview = repmat(reshape(uint8([128 128 128]), 1, 1, 3), spec.Height, spec.Width);
        preview(oky, okx, :) = old(iy(oky), ix(okx), :);
        img.CData = preview;
        app.setImageView(spec);
        end

        function showResult(app, result, offset)
        app.FractalImage.CData = app.colorize(result.Values, result.Inside, ...
            result.Roots, result.Spec, offset);
        app.setImageView(result.Spec);
        end

        function updateEnables(app)
        % Enable only the parameters the selected fractal uses.
        type = string(app.TypeDropDown.Value);
        usesPower = any(type == ["Mandelbrot" "Julia" "Newton"]);
        isJulia = type == "Julia";
        app.PowerSpinner.Enable = usesPower;
        app.PowerLabel.Enable = usesPower;
        app.JuliaReSpinner.Enable = isJulia;
        app.JuliaReLabel.Enable = isJulia;
        app.JuliaImSpinner.Enable = isJulia;
        app.JuliaImLabel.Enable = isJulia;
        end

        function updateStatus(app)
        r = app.Result;
        s = r.Spec;
        zoom = FractalCreator.fullView(s).Width / diff(s.XLim);
        if zoom < 1e4
            zoomText = sprintf("%.0f", zoom);
        else
            zoomText = sprintf("%.2e", zoom);
        end
        app.StatusLabel.Text = sprintf("%s  |  center %.10g %+.10gi  |  zoom %sx  |  %d x %d  |  %d iterations  |  %.2f s", ...
            s.Type, mean(s.XLim), mean(s.YLim), zoomText, s.Width, s.Height, s.MaxIter, r.Seconds);
        end

        function view = viewFromSpec(~, spec)
        view = struct(Center=complex(mean(spec.XLim), mean(spec.YLim)), ...
            Width=diff(spec.XLim));
        end

    end

    methods (Access = public)

        function clickImage(app, point, selectionType)
        % Act on a click at a point in the complex plane, as a mouse click on the
        % image does: "normal" zooms in, "alt" zooms out, and "extend" on the
        % Mandelbrot set opens the Julia set for that point.
        arguments
            app
            point (1,1) double
            selectionType (1,1) string = "normal"
        end
        switch selectionType
            case "normal"
                app.zoomAt(point, 0.5, false);
            case "alt"
                app.zoomAt(point, 2, false);
            case "extend"
                if app.TypeDropDown.Value == "Mandelbrot"
                    app.openJulia(point);
                else
                    app.zoomAt(point, 0.5, false);
                end
        end
        end

        function exportImage(app, file)
        % Write the last finished render as a PNG with its parameters as JSON in
        % the PNG Comment field.
        arguments
            app
            file (1,1) string
        end
        r = app.Result;
        s = r.Spec;
        rgb = app.colorize(r.Values, r.Inside, r.Roots, s, app.OffsetSlider.Value);
        meta = struct(Type=s.Type, Power=s.Power, ...
            JuliaC=[real(s.JuliaC) imag(s.JuliaC)], MaxIterations=s.MaxIter, ...
            XLim=s.XLim, YLim=s.YLim, Colormap=app.ColormapDropDown.Value, ...
            Density=app.DensitySpinner.Value, Offset=app.OffsetSlider.Value, ...
            Smooth=app.SmoothCheckBox.Value, InsideColor=app.InsideColorPicker.Value);
        imwrite(flipud(rgb), file, Comment=jsonencode(meta), ...
            Software="Fractal Creator, MATLAB R2026b");
        end

        function zoomAt(app, point, factor, keepPointFixed)
        arguments
            app
            point (1,1) double
            factor (1,1) double {mustBePositive}
            keepPointFixed (1,1) logical = false
        end
        % Scale the view by factor. Scroll zoom keeps the point under the pointer
        % fixed; click zoom centers the view on the point.
        newWidth = app.View.Width * factor;
        if newWidth < 1e-12 * max(1, abs(point))
            app.StatusLabel.Text = "Zoom limit reached: double precision cannot resolve a smaller view.";
            return
        end
        if keepPointFixed
            app.View.Center = point + (app.View.Center - point) * factor;
        else
            app.View.Center = point;
        end
        app.View.Width = newWidth;
        app.FullViewMode = false;
        app.PresetDropDown.Value = "Custom view";
        app.requestRender();
        end

    end

    methods (Static)

        function view = fullView(params)
        % Frame the whole set in a 4:3 view with a margin. The set's extent comes
        % from a coarse render of the square |x|, |y| <= 2.5, which holds every
        % bounded orbit the controls allow; points still bounded after 20
        % iterations count as the set. Newton's method has no bounded set, so its
        % view frames the roots of unity.
        view = struct(Center=0, Width=4);
        if params.Type == "Newton"
            return
        end
        g = linspace(-2.5, 2.5, 241);
        step = g(2) - g(1);
        [gx, gy] = meshgrid(g);
        params.MaxIter = 20;
        [~, inside] = FractalCreator.iterateFractal(complex(gx, gy), params);
        if ~any(inside, "all")
            % A Julia constant far outside the Mandelbrot set leaves no visible set.
            return
        end
        xl = [min(gx(inside)) max(gx(inside))] + [-step step];
        yl = [min(gy(inside)) max(gy(inside))] + [-step step];
        view = struct(Center=complex(mean(xl), mean(yl)), ...
            Width=1.25 * max(diff(xl), diff(yl) * 4 / 3));
        end

        function [values, inside, roots] = iterateFractal(pts, spec)
        % Smooth escape count for escape-time fractals, or root index and
        % iteration count for Newton's method, for a block of complex points.
        sz = size(pts);
        values = zeros(sz, "single");
        inside = false(sz);
        roots = zeros(sz, "uint8");
        p = spec.Power;
        idx = (1:numel(pts)).';
        if spec.Type == "Newton"
            r = exp(2i * pi * (0:p-1) / p);
            z = pts(:);
            for k = 1:spec.MaxIter
                z = z - (z.^p - 1) ./ (p * z.^(p-1));
                [dmin, j] = min(abs(z - r), [], 2);
                done = dmin < 1e-6;
                values(idx(done)) = k;
                roots(idx(done)) = j(done);
                keep = ~done & isfinite(z);
                idx = idx(keep);
                z = z(keep);
                if isempty(idx)
                    break
                end
            end
            inside(:) = roots == 0;
            return
        end
        bailout2 = 256^2;
        switch spec.Type
            case "Julia"
                z = pts(:);
                c = spec.JuliaC;
            case "Burning Ship"
                % Conjugate so the ship sits upright with the imaginary axis pointing up
                z = zeros(numel(pts), 1);
                c = conj(pts(:));
            otherwise
                z = zeros(numel(pts), 1);
                c = pts(:);
        end
        if any(spec.Type == ["Burning Ship" "Tricorn"])
            p = 2;
        end
        for k = 1:spec.MaxIter
            switch spec.Type
                case "Burning Ship"
                    z = complex(abs(real(z)), abs(imag(z)));
                    z = z .* z + c;
                case "Tricorn"
                    z = conj(z);
                    z = z .* z + c;
                otherwise
                    if p == 2
                        z = z .* z + c;
                    else
                        z = z.^p + c;
                    end
            end
            m2 = real(z).^2 + imag(z).^2;
            out = m2 > bailout2;
            if any(out)
                values(idx(out)) = k + 1 - log(0.5 * log(m2(out))) / log(p);
                keep = ~out;
                idx = idx(keep);
                z = z(keep);
                if ~isscalar(c)
                    c = c(keep);
                end
                if isempty(idx)
                    break
                end
            end
        end
        inside(idx) = true;
        end

        function result = renderFractal(spec, sendProgress)
        % Render the rows listed in spec.Rows of one view, in bands, and stream
        % each band back to the app. Rows index the full image grid, so any split
        % of the rows across tasks reproduces the single-task image exactly.
        x = linspace(spec.XLim(1), spec.XLim(2), spec.Width);
        y = linspace(spec.YLim(1), spec.YLim(2), spec.Height);
        rows = spec.Rows;
        n = numel(rows);
        values = zeros(n, spec.Width, "single");
        inside = false(n, spec.Width);
        roots = zeros(n, spec.Width, "uint8");
        edges = round(linspace(0, n, spec.NumBands + 1));
        timer = tic;
        for b = 1:spec.NumBands
            k = edges(b)+1:edges(b+1);
            if isempty(k)
                continue
            end
            [gx, gy] = meshgrid(x, y(rows(k)));
            [v, in, r] = FractalCreator.iterateFractal(complex(gx, gy), spec);
            values(k, :) = v;
            inside(k, :) = in;
            roots(k, :) = r;
            sendProgress(struct(Rows=rows(k), Values=v, Inside=in, Roots=r));
        end
        result = struct(Rows=rows, Values=values, Inside=inside, Roots=roots, ...
            Seconds=toc(timer));
        end

    end

    % Background task execution
    methods (Access = private)

        function cancelBackground(app, taskName)
        % cancelBackground  Cancel a running background task (no-op if idle).
            task = app.(taskName);
            hadFuture = ~isempty(task.Future);
            task.StopRequested = true;
            task.Running = false;
            app.(taskName) = task;
            if hadFuture
                cancel(task.Future);
            end
        end

        function cleanupBackground(app)
        % cleanupBackground  Cancel all background tasks (called on app close).
            if ~isempty(app.RenderTask.Future); cancel(app.RenderTask.Future); end
            if ~isempty(app.RenderTask2.Future); cancel(app.RenderTask2.Future); end
            if ~isempty(app.RenderTask3.Future); cancel(app.RenderTask3.Future); end
            if ~isempty(app.RenderTask4.Future); cancel(app.RenderTask4.Future); end
            if ~isempty(app.RenderTask5.Future); cancel(app.RenderTask5.Future); end
            if ~isempty(app.RenderTask6.Future); cancel(app.RenderTask6.Future); end
            if ~isempty(app.RenderTask7.Future); cancel(app.RenderTask7.Future); end
            if ~isempty(app.RenderTask8.Future); cancel(app.RenderTask8.Future); end
        end

        function handleBackgroundComplete(app, taskName, future, generation)
        % handleBackgroundComplete  Routes results/errors to the task's CompleteFcn.
            if ~isvalid(app); return; end
            task = app.(taskName);
            if generation ~= task.Generation; return; end
            task.Running = false;
            task.Future = [];
            task.Queue = [];
            app.(taskName) = task;
            wasCancelled = task.StopRequested || ...
                (~isempty(future.Error) && ...
                 strcmp(future.Error.identifier, "parallel:fevalqueue:ExecutionCancelled"));
            try
                if wasCancelled
                    task.CompleteFcn([], [], true);
                elseif ~isempty(future.Error)
                    task.CompleteFcn([], future.Error, false);
                else
                    nOut = max(0, nargout(task.Fcn));
                    if nOut == 0
                        task.CompleteFcn([], [], false);
                    elseif nOut == 1
                        task.CompleteFcn(fetchOutputs(future), [], false);
                    else
                        results = cell(1, nOut);
                        [results{:}] = fetchOutputs(future);
                        task.CompleteFcn(results, [], false);
                    end
                end
            catch cbErr
                fprintf(2, 'Error in CompleteFcn for task ''%s'': %s\n', taskName, cbErr.getReport());
                if isvalid(app)
                    uialert(app.UIFigure, cbErr.message, 'Background Task Error');
                end
            end
        end

        function safeProgress(app, taskName, msg, generation)
        % safeProgress  Wraps progress callbacks so errors appear in Command Window.
            if ~isvalid(app); return; end
            task = app.(taskName);
            if generation ~= task.Generation; return; end
            if msg.Type == "Progress"
                if ~task.Running; return; end
                if isempty(task.ProgressFcn); return; end
                try
                    task.ProgressFcn(msg.Data);
                catch bgErr
                    fprintf(2, 'Progress callback error (disabling): %s\n', bgErr.getReport());
                    task.ProgressFcn = [];
                    app.(taskName) = task;
                end
            else
                app.handleBackgroundComplete(taskName, task.Future, generation);
            end
        end

        function startBackground(app, taskName, varargin)
        % startBackground  Launch a background task. Pass task arguments after the name.
        %   app.startBackground('TaskName', arg1, arg2, ...)
            task = app.(taskName);
            if task.Running
                error('Background work is already running. Cancel it first.');
            end
            task.Running = true;
            task.StopRequested = false;
            task.Generation = task.Generation + 1;
            generation = task.Generation;
            nOut = max(0, nargout(task.Fcn));
            if ~isempty(task.ProgressFcn)
                task.Queue = parallel.pool.DataQueue;
                afterEach(task.Queue, @(d) app.safeProgress(taskName, d, generation));
                queue = task.Queue;
                sendProgress = @(data) send(queue, struct(Type="Progress", Data={data}));
                task.Future = parfeval(backgroundPool, task.Fcn, nOut, varargin{:}, sendProgress);
                afterAll(task.Future, @(~) send(queue, struct(Type="Finished")), 0, 'PassFuture', true);
            else
                task.Future = parfeval(backgroundPool, task.Fcn, nOut, varargin{:});
                afterAll(task.Future, @(f) app.handleBackgroundComplete(taskName, f, generation), 0, 'PassFuture', true);
            end
            app.(taskName) = task;
        end

    end

    % Callbacks that handle component events
    methods

        % Code that executes after component creation
        function startupFcn(app)
            app.RenderTask.Fcn = @FractalCreator.renderFractal;
            app.RenderTask.CompleteFcn = @app.onRenderComplete;
            app.RenderTask.ProgressFcn = @app.onRenderProgress;
            app.RenderTask2.Fcn = @FractalCreator.renderFractal;
            app.RenderTask2.CompleteFcn = @app.onRenderComplete;
            app.RenderTask2.ProgressFcn = @app.onRenderProgress;
            app.RenderTask3.Fcn = @FractalCreator.renderFractal;
            app.RenderTask3.CompleteFcn = @app.onRenderComplete;
            app.RenderTask3.ProgressFcn = @app.onRenderProgress;
            app.RenderTask4.Fcn = @FractalCreator.renderFractal;
            app.RenderTask4.CompleteFcn = @app.onRenderComplete;
            app.RenderTask4.ProgressFcn = @app.onRenderProgress;
            app.RenderTask5.Fcn = @FractalCreator.renderFractal;
            app.RenderTask5.CompleteFcn = @app.onRenderComplete;
            app.RenderTask5.ProgressFcn = @app.onRenderProgress;
            app.RenderTask6.Fcn = @FractalCreator.renderFractal;
            app.RenderTask6.CompleteFcn = @app.onRenderComplete;
            app.RenderTask6.ProgressFcn = @app.onRenderProgress;
            app.RenderTask7.Fcn = @FractalCreator.renderFractal;
            app.RenderTask7.CompleteFcn = @app.onRenderComplete;
            app.RenderTask7.ProgressFcn = @app.onRenderProgress;
            app.RenderTask8.Fcn = @FractalCreator.renderFractal;
            app.RenderTask8.CompleteFcn = @app.onRenderComplete;
            app.RenderTask8.ProgressFcn = @app.onRenderProgress;
            app.Presets = app.buildPresets();
            ax = app.UIAxes;
            disableDefaultInteractivity(ax);
            ax.Toolbar.Visible = "off";
            ax.XAxis.Visible = "off";
            ax.YAxis.Visible = "off";
            ax.Color = "none";
            ax.DataAspectRatio = [1 1 1];
            app.FractalImage = image(ax, CData=zeros(1, 1, 3, "uint8"), XData=[0 1], YData=[0 1]);
            app.FractalImage.ButtonDownFcn = @(~, event) app.clickImage(complex(event.IntersectionPoint(1), event.IntersectionPoint(2)), app.UIFigure.SelectionType);
            ax.YDir = "normal";
            app.refreshPresetList();
            app.applyPreset(app.PresetDropDown.Value);
            app.requestRender();
        end

        % Close request function: UIFigure
        function CloseRequestFcn(app, ~)
            app.cleanupBackground();
            delete(app.UIFigure);
        end

        % Window scroll wheel function: UIFigure
        function UIFigureWindowScrollWheel(app, event)
            pt = app.UIAxes.CurrentPoint(1, 1:2);
            xl = app.UIAxes.XLim;
            yl = app.UIAxes.YLim;
            if pt(1) < xl(1) || pt(1) > xl(2) || pt(2) < yl(1) || pt(2) > yl(2)
                return
            end
            app.zoomAt(complex(pt(1), pt(2)), 1.25 ^ event.VerticalScrollCount, true);
        end

        % Value changed function: TypeDropDown
        function TypeDropDownValueChanged(app, ~)
            app.refreshPresetList();
            app.applyPreset(app.PresetDropDown.Value);
            app.requestRender();
        end

        % Value changed function: PresetDropDown
        function PresetDropDownValueChanged(app, ~)
            if app.PresetDropDown.Value == "Custom view"
                return
            end
            app.applyPreset(app.PresetDropDown.Value);
            app.requestRender();
        end

        % Value changed function: IterationsSpinner, JuliaImSpinner, 
        % ...and 3 other components
        function FractalParameterChanged(app, ~)
            if app.FullViewMode
                app.PresetDropDown.Value = app.fullViewPresetName();
            end
            app.requestRender();
        end

        % Value changed function: ColormapDropDown, DensitySpinner, 
        % ...and 3 other components
        function ColorSettingChanged(app, ~)
            app.recolor();
        end

        % Value changing function: OffsetSlider
        function OffsetSliderValueChanging(app, event)
            app.recolor(event.Value);
        end

        % Button pushed function: RenderButton
        function RenderButtonPushed(app, ~)
            app.requestRender();
        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, ~)
            app.cancelRender();
        end

        % Button pushed function: ResetViewButton
        function ResetViewButtonPushed(app, ~)
            app.FullViewMode = true;
            app.PresetDropDown.Value = app.fullViewPresetName();
            app.requestRender();
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, ~)
            if isempty(app.Result)
                uialert(app.UIFigure, "Nothing to save yet. Wait for the first render to finish.", "Save PNG", Icon="info");
                return
            end
            [file, folder] = uiputfile("*.png", "Save fractal image", "fractal.png");
            figure(app.UIFigure);
            if isequal(file, 0)
                return
            end
            app.exportImage(fullfile(folder, file));
            app.StatusLabel.Text = "Saved " + fullfile(folder, file);
        end
    end

    % App creation
    methods (Access = public)

        % Construct app
        function app = FractalCreator(varargin)
            app = app@matlab.apps.App(varargin{:});

            if nargout == 0
                clear app
            end
        end
    end
end