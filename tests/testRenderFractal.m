function tests = testRenderFractal
% Unit tests for the Fractal Creator render kernel (FractalCreator.renderFractal).
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
    fullfile(fileparts(mfilename("fullpath")), "..")));
end

function testMandelbrotKnownPoints(testCase)
% c = -2, -1, -0.25, 0 lie in the set; c = 0.5 and 1 escape.
r = render("Mandelbrot", [-2 -1 -0.25 0 0.5 1], 500);
verifyEqual(testCase, r.Inside, [true true true true false false]);
verifyGreaterThan(testCase, r.Values(5:6), 0);
end

function testJuliaZeroIsUnitDisk(testCase)
% For c = 0 the filled Julia set is the closed unit disk.
r = render("Julia", [0 0.5 0.99 1.01 1.5], 500, JuliaC=0);
verifyEqual(testCase, r.Inside, [true true true false false]);
end

function testNewtonFindsEachRoot(testCase)
% Starting points near each cube root of unity converge to that root; 0 never does.
z0 = [2, 2 * exp(2i * pi / 3), 2 * exp(4i * pi / 3), 0];
r = render("Newton", z0, 100, Power=3);
verifyEqual(testCase, double(r.Roots), [1 2 3 0]);
verifyEqual(testCase, r.Inside, [false false false true]);
end

function testBurningShipAndTricornOrigin(testCase)
for type = ["Burning Ship" "Tricorn"]
    r = render(type, [0 3], 200);
    verifyEqual(testCase, r.Inside, [true false], type);
end
end

function testMultibrotPowerThree(testCase)
r = render("Mandelbrot", [0 1], 200, Power=3);
verifyEqual(testCase, r.Inside, [true false]);
end

function testSmoothCountDecreasesAwayFromSet(testCase)
% Along the real axis right of the cusp, the smooth count falls monotonically.
r = render("Mandelbrot", linspace(0.3, 1.5, 400), 500);
verifyLessThanOrEqual(testCase, diff(double(r.Values)), 1e-6);
end

function testBandsCoverEveryRowOnce(testCase)
spec = makeSpec("Mandelbrot", [-2.5 1], [-1.3125 1.3125], 64, 48, 200);
spec.NumBands = 5;
msgs = {};
result = FractalCreator.renderFractal(spec, @(m) storeMessage(m));
rows = cellfun(@(m) m.Rows, msgs, UniformOutput=false);
verifyEqual(testCase, sort([rows{:}]), 1:48);
assembled = zeros(48, 64, "single");
for k = 1:numel(msgs)
    assembled(rows{k}, :) = msgs{k}.Values;
end
verifyEqual(testCase, assembled, result.Values);
verifyEqual(testCase, size(result.Inside), [48 64]);

    function storeMessage(m)
        msgs{end + 1} = m;
    end
end

function testInterleavedPartsMatchSingleRender(testCase)
% Splitting the rows across tasks, as the app does, reproduces the
% single-task image bit for bit.
spec = makeSpec("Mandelbrot", -0.7453 + [-0.006 0.006], 0.1127 + [-0.0045 0.0045], 160, 120, 500);
spec.NumBands = 3;
whole = FractalCreator.renderFractal(spec, @(~) []);
taskCount = 8;
values = zeros(120, 160, "single");
for i = 1:taskCount
    part = spec;
    part.Rows = i:taskCount:120;
    r = FractalCreator.renderFractal(part, @(~) []);
    values(r.Rows, :) = r.Values;
end
verifyEqual(testCase, values, whole.Values);
end

function r = render(type, points, maxIter, opts)
% Render each complex point as its own tiny view and collect the first pixel.
arguments
    type (1,1) string
    points double
    maxIter (1,1) double
    opts.Power (1,1) double = 2
    opts.JuliaC (1,1) double = complex(-0.8, 0.156)
end
r = struct(Inside=false(size(points)), Values=zeros(size(points), "single"), ...
    Roots=zeros(size(points), "uint8"));
for k = 1:numel(points)
    p = points(k);
    % A 2 x 2 grid whose first pixel center is exactly p.
    spec = makeSpec(type, real(p) + [0 1e-3], imag(p) + [0 1e-3], 2, 2, maxIter);
    spec.Power = opts.Power;
    spec.JuliaC = opts.JuliaC;
    one = FractalCreator.renderFractal(spec, @(~) []);
    r.Inside(k) = one.Inside(1, 1);
    r.Values(k) = one.Values(1, 1);
    r.Roots(k) = one.Roots(1, 1);
end
end

function spec = makeSpec(type, xlim, ylim, w, h, maxIter)
spec = struct(Type=type, Power=2, JuliaC=complex(-0.8, 0.156), ...
    MaxIter=maxIter, Width=w, Height=h, XLim=xlim, YLim=ylim, NumBands=1, Rows=1:h);
end
