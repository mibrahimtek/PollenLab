<img width="1175" height="259" alt="image" src="https://github.com/user-attachments/assets/759b1c3d-b579-4d89-99e2-d8f5d86b1a93" />



Image analysis for in vitro pollen germination assays. Count grains, score germination, measure pollen tubes, quantify FDA/PI viability, and get group statistics out the other end as CSV.

<img width="1848" height="1047" alt="image" src="https://github.com/user-attachments/assets/1f6f548e-777c-45d1-b17c-a45b9d04ad6f" />



The repository holds two tools that solve the same problem at different levels of effort:

  - PollenLab, a single HTML file that runs in a browser with no install and no server.
  - An ImageJ/Fiji macro for people who already work in Fiji and only need counts and areas.

------------------------

  **Quick start**

Download ```PollenLab.html``` and double click it. That is the whole installation.

It opens in your default browser and runs entirely on your machine. Images are never uploaded anywhere, and nothing is fetched from the internet, so it works offline and on an air-gapped lab machine.

Chrome or Edge are the safest choices. PNG and JPG both work. Browsers cannot decode TIFF, so convert first if your microscope writes TIFF (in Fiji: ```File > Save As > PNG```).


-----------

**What PollenLab does**
You load a whole set of images at the start, work through them one at a time, and save everything to the dataset at the end. Detection settings belong to the image you have open, so you can tune each one on its own, and one button copies a setting you like across the rest of the queue.

**Counting grains**

Grains are segmented with background flattening, a threshold (Otsu by default, computed separately for each image), hole filling, and a watershed step that separates touching grains. Size and circularity filters work the same way as ImageJ's Analyze Particles. Every grain is listed in a sortable table with its area and circularity.

Sorting that table by area is the fastest way to find problems, because an unresolved pair of grains sits at the top of the size distribution with a low circularity score.

Fixing what the algorithm gets wrong

Dense clumps are the main source of counting error and no threshold setting fixes them, so the correction tools are part of the normal workflow rather than an afterthought:

- Click a grain to select it. It fills red, so you can see exactly which pixels were measured.
- Drag a line across a merged pair to split it.
- Click the centre of a grain the detector missed to add it. The grain is segmented from that point with a local threshold, so it gets a real measured area instead of an assumed one. Clicking empty background is rejected rather than inventing an object.
- Right click anything to remove it, and right click a removed grain to bring it back.

You can also restrict counting to a rectangle, or mask out crowded patches. Neither touches the image itself, which stays at full resolution.

**Germination and tubes**

Germination is scored by clicking each germinated grain. Tube length is a polyline you click along the tube, so curved tubes are measured along their curve. Tube width is a drag across the tube. Both need a scale first.

This part is manual on purpose. Automated tube detection was implemented twice during development and neither version was good enough to ship on by default. The section on accuracy below has the numbers.

**Viability**

The viability tab takes the same queue approach for FDA/PI fluorescence images. Green is read as FDA (live), red as PI (dead), each with its own threshold, minimum object size, and optional correction for bleed-through between channels. Grains positive in both channels are scored dead by default, since PI entry means the membrane is compromised.

Viability is saved as its own record. That is the right structure when germination and viability run on separate aliquots and cannot be matched grain by grain.

**Data and statistics**

Each image produces one record, keyed to its filename, with a sample name and a group name. Records store the summary values and also the full list of individual grain areas and tube measurements, so distributions survive into the exported file instead of being flattened to a mean.

<img width="1844" height="795" alt="image" src="https://github.com/user-attachments/assets/0f9dedca-5827-4efb-bb16-b65aaf2fea0c" />


The statistics tab gives n, mean, SD, SEM and range per group, a Welch t test for two groups or one way ANOVA for more, and a plot with individual points over the group means. There is a second class of measurement that pools every grain or tube in a group, which is useful for looking at a distribution but is not a valid basis for a significance test, and the interface says so on screen when you pick one.

**Not losing your work**

Everything you do is auto-saved in the browser and restored when you reopen the page. Save session writes it to a file as well. By default that file stores the work and not the pixels, which keeps it small (a fully worked set of 30 images is about 14 KB), and dropping the same images back in re-attaches every correction by filename. There is an option to embed the images too if you want a file that restores on its own.

Auto-save lives in the browser and will not survive clearing browser data, so save a session file after anything you would hate to redo.

----------------

**The ImageJ macro**

```imagej/Pollen_Count_Area_batch.ijm``` runs the counting and area pipeline over a folder in Fiji, unattended. It exists for labs already standardised on ImageJ, and it only does total count and grain area. Germination, tube measurements and viability are not part of it.

Drag the macro into Fiji and press Run. It asks for an input folder and an output folder, then writes a particle table and a QC mask per image, one combined ```Summary_ALL.csv```, and a ```QC_log.txt``` that flags any image where the threshold looks wrong instead of silently counting the background.

Three values at the top of the file need calibrating once for your setup: the scale bar length in pixels, the fixed threshold cutoff, and the minimum grain area. The comments in the file explain how to measure each.

The macro uses a fixed dark threshold on a background-normalised image rather than a per-image automatic threshold. That sounds like the less clever choice and it is the more reliable one, because background subtraction pins the background near white, so a fixed dark cutoff cannot flip polarity and start segmenting the background. That failure is easy to miss when it happens and it ruins the counts.

------------

**Benchmark**

Raw image processing time was measured on 15 representative images, excluding the statistics module. PollenLab tracked the manual counts more closely than the macro and was slightly faster while doing it. Both are roughly an order of magnitude quicker than counting by hand. PollenLab has since been used on more than 600 images across the PGM optimisation experiments.

<img width="2908" height="2680" alt="Figure 1" src="https://github.com/user-attachments/assets/e86d9f40-8711-49a8-8ada-d65fb1073a76" />

**Test images**

```test-images/``` holds representative brightfield fields at several grain densities. They are there so you can see how the tool behaves before pointing it at your own data, and so anyone reproducing the benchmark has something concrete to run.

**Citing**


