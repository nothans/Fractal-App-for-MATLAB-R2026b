classdef FractalCreatorAppTest < matlab.unittest.TestCase
    % App-level tests. Each test launches Fractal Creator, fires the same
    % component callbacks a user's clicks fire, and waits for the background
    % render to settle.

    properties
        App
    end

    methods (TestClassSetup)
        function addAppToPath(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(fileparts(mfilename("fullpath")), "..")));
        end

        function startRenderWorkers(~)
            % Start the background pool and load the render kernel on every
            % worker before the first app launch.
            pool = backgroundPool;
            spec = struct(Type="Mandelbrot", Power=2, JuliaC=0, MaxIter=10, ...
                Width=2, Height=2, XLim=[0 1], YLim=[0 1], NumBands=1, Rows=1:2);
            for k = pool.NumWorkers:-1:1
                futures(k) = parfeval(pool, @FractalCreator.renderFractal, 1, spec, @(~) []);
            end
            wait(futures);
        end
    end

    methods (TestMethodSetup)
        function launchApp(testCase)
            testCase.App = FractalCreator;
            testCase.addTeardown(@delete, testCase.App);
            testCase.waitForRender();
        end
    end

    methods (Test)
        function startupRendersDefaultView(testCase)
            img = testCase.image();
            full = testCase.fullView("Mandelbrot");
            testCase.verifySize(img.CData, [720 960 3]);
            testCase.verifyEqual(diff(img.XData), full.Width, AbsTol=1e-12);
            testCase.verifyEqual(mean(img.XData), real(full.Center), AbsTol=1e-12);
            testCase.verifyTrue(contains(testCase.App.StatusLabel.Text, "zoom 1x"));
            testCase.verifyTrue(startsWith(testCase.App.StatusLabel.Text, "Mandelbrot"));
            testCase.verifyEqual(testCase.App.JuliaReSpinner.Enable, matlab.lang.OnOffSwitchState.off);
        end

        function clickZoomsInAtPoint(testCase)
            full = testCase.fullView("Mandelbrot");
            testCase.App.clickImage(complex(-0.745, 0.11));
            testCase.waitForRender();
            img = testCase.image();
            testCase.verifyEqual(diff(img.XData), full.Width / 2, RelTol=1e-9);
            testCase.verifyEqual(mean(img.XData), -0.745, AbsTol=1e-12);
            testCase.verifyEqual(mean(img.YData), 0.11, AbsTol=1e-12);
            testCase.verifyEqual(string(testCase.App.PresetDropDown.Value), "Custom view");
        end

        function rightClickZoomsOut(testCase)
            full = testCase.fullView("Mandelbrot");
            testCase.App.clickImage(-0.75, "alt");
            testCase.waitForRender();
            testCase.verifyEqual(diff(testCase.image().XData), 2 * full.Width, RelTol=1e-9);
        end

        function shiftClickOpensJuliaForPoint(testCase)
            app = testCase.App;
            app.clickImage(complex(-0.4, 0.6), "extend");
            testCase.waitForRender();
            testCase.verifyEqual(string(app.TypeDropDown.Value), "Julia");
            testCase.verifyEqual(app.JuliaReSpinner.Value, -0.4, AbsTol=1e-12);
            testCase.verifyEqual(app.JuliaImSpinner.Value, 0.6, AbsTol=1e-12);
            testCase.verifyEqual(app.JuliaReSpinner.Enable, matlab.lang.OnOffSwitchState.on);
            testCase.verifyTrue(startsWith(app.StatusLabel.Text, "Julia"));
            testCase.verifyEqual(string(app.PresetDropDown.Value), "Custom view");
        end

        function fullViewsShowWholeSet(testCase)
            % Each type's full view contains its whole set. The Burning Ship
            % and Tricorn presets once cut off the top of the set.
            app = testCase.App;
            for type = ["Burning Ship" "Tricorn" "Julia" "Mandelbrot"]
                fire(app.TypeDropDown, type);
                testCase.waitForRender();
                testCase.verifyViewContainsSet(type);
            end
        end

        function shiftClickFramesWideJuliaSet(testCase)
            % The Julia set for c = -1.9 spans nearly [-2, 2] on the real axis.
            testCase.App.clickImage(-1.9, "extend");
            testCase.waitForRender();
            testCase.verifyViewContainsSet("Julia");
        end

        function powerChangeRefitsFullView(testCase)
            % Higher powers give sets centered on the origin; the full view follows.
            app = testCase.App;
            fire(app.PowerSpinner, 3);
            testCase.waitForRender();
            testCase.verifyEqual(mean(testCase.image().XData), 0, AbsTol=0.03);
            testCase.verifyEqual(string(app.PresetDropDown.Value), "Full set");
            testCase.verifyViewContainsSet("Mandelbrot");
        end

        function zoomedViewKeepsViewOnParameterChange(testCase)
            % After a zoom, changing a parameter keeps the zoomed view.
            app = testCase.App;
            app.clickImage(complex(-0.745, 0.11));
            testCase.waitForRender();
            before = [testCase.image().XData testCase.image().YData];
            fire(app.PowerSpinner, 3);
            testCase.waitForRender();
            testCase.verifyEqual([testCase.image().XData testCase.image().YData], before);
            testCase.verifyEqual(string(app.PresetDropDown.Value), "Custom view");
        end

        function resetViewRestoresFullView(testCase)
            app = testCase.App;
            fire(app.TypeDropDown, "Burning Ship");
            testCase.waitForRender();
            full = [testCase.image().XData testCase.image().YData];
            app.clickImage(complex(-1.75, 0));
            testCase.waitForRender();
            push(app.ResetViewButton);
            testCase.waitForRender();
            testCase.verifyEqual([testCase.image().XData testCase.image().YData], full, AbsTol=1e-12);
            testCase.verifyEqual(string(app.PresetDropDown.Value), "Full ship");
        end

        function editingJuliaConstantRenamesPreset(testCase)
            % A Julia preset names one constant; editing it makes the view custom.
            app = testCase.App;
            fire(app.TypeDropDown, "Julia");
            testCase.waitForRender();
            testCase.verifyEqual(string(app.PresetDropDown.Value), "Classic");
            fire(app.JuliaReSpinner, -0.5);
            testCase.waitForRender();
            testCase.verifyEqual(string(app.PresetDropDown.Value), "Custom view");
            testCase.verifyViewContainsSet("Julia");
        end

        function scrollZoomKeepsPointerFixed(testCase)
            % Scrolling zooms around the pointer: the point under it stays put.
            full = testCase.fullView("Mandelbrot");
            pointer = complex(0, 0.5);
            testCase.App.zoomAt(pointer, 1 / 1.25, true);
            testCase.waitForRender();
            img = testCase.image();
            expectedCenter = pointer + (full.Center - pointer) / 1.25;
            testCase.verifyEqual(diff(img.XData), full.Width / 1.25, RelTol=1e-9);
            testCase.verifyEqual(mean(img.XData), real(expectedCenter), AbsTol=1e-12);
            testCase.verifyEqual(mean(img.YData), imag(expectedCenter), AbsTol=1e-12);
        end

        function switchingTypeLoadsItsPresets(testCase)
            app = testCase.App;
            fire(app.TypeDropDown, "Newton");
            testCase.waitForRender();
            testCase.verifyEqual(string(app.PresetDropDown.Items), ["Full view" "Custom view"]);
            testCase.verifyEqual(app.PowerSpinner.Value, 3);
            testCase.verifyEqual(app.JuliaImSpinner.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.verifyTrue(startsWith(app.StatusLabel.Text, "Newton"));
        end

        function presetSetsViewAndIterations(testCase)
            app = testCase.App;
            fire(app.PresetDropDown, "Mini Mandelbrot");
            testCase.waitForRender();
            img = testCase.image();
            testCase.verifyEqual(app.IterationsSpinner.Value, 600);
            testCase.verifyEqual(diff(img.XData), 0.08, RelTol=1e-9);
            testCase.verifyEqual(mean(img.XData), -1.7568, AbsTol=1e-12);
        end

        function cancelKeepsPreviousImage(testCase)
            app = testCase.App;
            before = testCase.image().CData;
            fire(app.ResolutionDropDown, 1600);
            testCase.verifyEqual(app.CancelButton.Enable, matlab.lang.OnOffSwitchState.on);
            push(app.CancelButton);
            testCase.waitForRender();
            testCase.verifyTrue(startsWith(app.StatusLabel.Text, "Render cancelled"));
            testCase.verifyEqual(testCase.image().CData, before);
            testCase.verifyFalse(backgroundPool().Busy, "Cancel should stop the worker");
        end

        function newestSettingsWin(testCase)
            app = testCase.App;
            for n = [400 800 1200]
                fire(app.IterationsSpinner, n);
            end
            testCase.waitForRender();
            testCase.verifyTrue(contains(app.StatusLabel.Text, "1200 iterations"));
        end

        function colorChangeDoesNotRecompute(testCase)
            app = testCase.App;
            before = testCase.image().CData;
            status = app.StatusLabel.Text;
            fire(app.ColormapDropDown, "turbo");
            testCase.verifyEqual(app.CancelButton.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.verifyNotEqual(testCase.image().CData, before);
            testCase.verifyEqual(app.StatusLabel.Text, status);
        end

        function exportWritesPngWithParameters(testCase)
            folder = testCase.createTemporaryFolder();
            file = fullfile(folder, "fractal.png");
            testCase.App.exportImage(file);
            testCase.verifySize(imread(file), [720 960 3]);
            meta = jsondecode(imfinfo(file).Comment);
            testCase.verifyEqual(meta.Type, 'Mandelbrot');
            testCase.verifyEqual(meta.MaxIterations, 300);
            testCase.verifyEqual(meta.Colormap, 'hot');
        end

        function paintedBandsMatchFinalColors(testCase)
            % The image painted band by band equals a full recolor of the
            % finished render, which is what Save PNG writes.
            app = testCase.App;
            fire(app.PresetDropDown, "Seahorse Valley");
            testCase.waitForRender();
            file = fullfile(testCase.createTemporaryFolder(), "check.png");
            app.exportImage(file);
            testCase.verifyEqual(flipud(imread(file)), testCase.image().CData);
        end

        function closingDuringRenderStopsWork(testCase)
            fire(testCase.App.PresetDropDown, "Spiral");
            delete(testCase.App);
            testCase.verifyThat(@() backgroundPool().Busy, ...
                matlab.unittest.constraints.Eventually( ...
                matlab.unittest.constraints.IsFalse, WithTimeoutOf=10));
        end
    end

    methods (Access = private)
        function waitForRender(testCase)
            % Eventually processes pending callbacks while it polls.
            testCase.assertThat(@() testCase.App.CancelButton.Enable, ...
                matlab.unittest.constraints.Eventually( ...
                matlab.unittest.constraints.IsEqualTo(matlab.lang.OnOffSwitchState.off), ...
                WithTimeoutOf=60), "Render did not finish within 60 s");
        end

        function img = image(testCase)
            img = findobj(testCase.App.UIAxes, Type="image");
        end

        function view = fullView(testCase, type)
            app = testCase.App;
            view = FractalCreator.fullView(struct(Type=type, Power=app.PowerSpinner.Value, ...
                JuliaC=complex(app.JuliaReSpinner.Value, app.JuliaImSpinner.Value)));
        end

        function verifyViewContainsSet(testCase, type)
            % Every point of the set, sampled on a fine grid, lies inside the
            % image's extent.
            app = testCase.App;
            spec = struct(Type=type, Power=app.PowerSpinner.Value, ...
                JuliaC=complex(app.JuliaReSpinner.Value, app.JuliaImSpinner.Value), MaxIter=300);
            [gx, gy] = meshgrid(linspace(-2.5, 2.5, 601));
            [values, inside] = FractalCreator.iterateFractal(complex(gx, gy), spec);
            visible = inside | values > 100;
            img = testCase.image();
            testCase.verifyGreaterThan(min(gx(visible)), img.XData(1), type);
            testCase.verifyLessThan(max(gx(visible)), img.XData(2), type);
            testCase.verifyGreaterThan(min(gy(visible)), img.YData(1), type);
            testCase.verifyLessThan(max(gy(visible)), img.YData(2), type);
        end
    end
end

function fire(component, value)
% Set a control's value and run its ValueChangedFcn, as a user edit does.
component.Value = value;
component.ValueChangedFcn(component, []);
end

function push(button)
% Run a button's ButtonPushedFcn, as a user press does.
button.ButtonPushedFcn(button, []);
end
