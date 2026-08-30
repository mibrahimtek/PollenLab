// ============================================================
//  Pollen Total Count + Area  —  Fiji/ImageJ batch macro
//  Brightfield: dark pollen on a light background
//  - forces dark-object polarity (threshold can NEVER flip to background)
//  - fixed cutoff on a background-normalized image = robust + reproducible
//  - flags suspicious images instead of counting them silently
//  Run: Plugins > Macros > Run...  (or drag into Fiji and press Run)
// ============================================================

// ------------------- CONFIG (edit these) -------------------

// --- Scale ---
// Measure the scale bar length in pixels ONCE (Line tool -> read px), put it below.
// If magnification is identical for all images, this single value is correct for all.
useManualScale   = true;
knownDistance    = 1000;      // value written next to the scale bar
distanceInPixels = 506;       // <-- MEASURE ONCE and set this
pixelUnit        = "um";

// --- Optional: crop out the scale bar (only if it is ALWAYS in the same spot) ---
cropScaleBar = false;
cropX = 0; cropY = 0; cropW = 1000; cropH = 700;   // rectangle that EXCLUDES the bar

// --- Preprocessing ---
bgRadius    = 50;    // rolling-ball radius (px); larger than one grain
doDespeckle = true;

// --- Threshold ---
//  "fixed" : recommended. bg-subtraction pins background ~white, so a fixed dark
//            range always grabs pollen and never the background.
//  "auto"  : adapts per image; polarity still forced to dark objects.
thresholdMode = "fixed";     // "fixed" or "auto"
fixedMax      = 200;         // pixels 0..fixedMax = pollen (calibrate once)
autoMethod    = "Default";   // if "auto"; try "Triangle" when density varies a lot

// --- Sanity guard ---
// If selected foreground exceeds this %, the threshold is probably wrong -> flag it.
maxForegroundPct = 60;

// --- Particle analysis ---
minSize    = 200;          // µm^2  (min real grain area; measure one grain to set)
maxSizeStr = "2000";
minCirc    = 0.20;
maxCirc    = 1.00;

// --- QC ---
saveQCmask = true;        // save a mask image per input to eyeball what was counted
// -----------------------------------------------------------

inputDir  = getDirectory("Choose INPUT folder (images)");
outputDir = getDirectory("Choose OUTPUT folder (results)");
list = getFileList(inputDir);

setOption("BlackBackground", true);
run("Set Measurements...", "area mean integrated shape area_fraction centroid redirect=None decimal=3");
run("Clear Results");
if (isOpen("Summary")) { selectWindow("Summary"); run("Close"); }

qcLog = "file\tcount\tforeground_pct\tflag\n";

setBatchMode(true);
for (i = 0; i < list.length; i++) {
    name = list[i];
    low = toLowerCase(name);
    if (!(endsWith(low,".tif")||endsWith(low,".tiff")||endsWith(low,".png")||
          endsWith(low,".jpg")||endsWith(low,".jpeg")||endsWith(low,".bmp"))) continue;

    // base name without extension (for output files)
    base = name;
    dot = lastIndexOf(base, ".");
    if (dot > 0) base = substring(base, 0, dot);

    open(inputDir + name);

    // --- Scale ---
    if (useManualScale)
        run("Set Scale...", "distance="+distanceInPixels+" known="+knownDistance+" unit="+pixelUnit);

    // --- Crop scale bar ---
    if (cropScaleBar) { makeRectangle(cropX, cropY, cropW, cropH); run("Crop"); }

    // --- Preprocess ---
    if (bitDepth() != 8) run("8-bit");
    run("Subtract Background...", "rolling="+bgRadius+" light sliding");
    if (doDespeckle) run("Despeckle");

    // --- Threshold (dark-object polarity forced) ---
    if (thresholdMode == "fixed")
        setThreshold(0, fixedMax);
    else
        setAutoThreshold(autoMethod);   // no "dark" keyword => selects dark objects

    // --- Foreground % guard ---
    getHistogram(values, counts, 256);
    getThreshold(lo, hi);
    fg = 0; tot = 0;
    for (v = 0; v < 256; v++) { tot += counts[v]; if (v >= lo && v <= hi) fg += counts[v]; }
    fgPct = 100 * fg / tot;
    flag = "";
    if (fgPct > maxForegroundPct) flag = "CHECK_THRESHOLD";

    // --- Binary ---
    run("Convert to Mask");
    run("Fill Holes");
    run("Watershed");

    // --- Count + area ---
    run("Clear Results");
    run("Analyze Particles...",
        "size="+minSize+"-"+maxSizeStr+" circularity="+minCirc+"-"+maxCirc+
        " show=Masks display exclude summarize add");
    count = nResults;

    // save per-image particle table
    saveAs("Results", outputDir + base + "_particles.csv");

    // save QC mask (active image after show=Masks)
    if (saveQCmask) saveAs("PNG", outputDir + base + "_QCmask.png");

    qcLog += base + "\t" + count + "\t" + d2s(fgPct,1) + "\t" + flag + "\n";

    roiManager("reset");
    close("*");
}
setBatchMode(false);

// --- Save combined outputs ---
if (isOpen("Summary")) { selectWindow("Summary"); saveAs("Results", outputDir + "Summary_ALL.csv"); }
f = File.open(outputDir + "QC_log.txt");
print(f, qcLog);
File.close(f);

print("Done. Results saved to: " + outputDir);
print("Check QC_log.txt for any images flagged CHECK_THRESHOLD.");
