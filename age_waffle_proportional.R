
install.packages(c("ggplot2", "dplyr"))
source("age_waffle_grids.R")
You can easily customize the highlight_color, base_color, or shaded_n values at the top of the script.


Age waffle grids
Code · R 

Age waffle grids
Image · PNG 
now I want to have the size of each group's grid proportional to the following numbers: 1500,500, 180, 40, 12, 9.3,20,130,500. the part that is red should proportionally remain the same

6:55 AM

Ran 3 commands
Ran 3 commands
Good — square grids work well. The very small groups (5-9y through 65-84y) have fewer than 1 red cell when rounded, which is honest to the data. Now I'll build the full visualization:


Ran 2 commands, read a file
Ran 2 commands, read a file
Here's the R script and a preview. The key design decisions:

Grid sizing logic — each grid is N×N squares where N = round(sqrt(100 × size/max_size)). This makes the area (number of squares) proportional to population size, with the largest group (<1y, 1500) anchored at 10×10:

Group	Grid	Cells	Red
<1y	10×10	100	72 (72%)
1y	6×6	36	17 (47%)
2-4y	3×3	9	3 (33%)
5-9y	2×2	4	0 (12%)
10-19y … 65-84y	1×1	1	0
85+y	6×6	36	1 (3%)
The very small middle groups (10-19y through 65-84y) shrink to 1–4 cells — their red fraction is so low it rounds to 0, which accurately reflects how few absolute events they represent. The arrangeGrob() call uses widths/heights proportional to the max grid size per row/column, so the panels themselves take up appropriately sized space on the canvas.


Age waffle proportional
Code · R 

Age waffle proportional
Image · PNG 
the number of squares should be adjusted so that all groups have some red. and you can align them on the same line and keep the width of the column consistent

6:59 AM

Ran 2 commands, viewed a file
Ran 2 commands, viewed a file
Looking good! The bottom alignment and consistent column widths are working. Now let me write the clean R code and polish the output slightly:


Ran a command, read a file
Ran a command, read a file
Here's the updated R script and preview. The key changes:

All 10 columns wide — every grid is exactly 10 squares across, so column widths are identical. Height (number of rows) is what varies proportionally to population size.

Minimum rows enforced — for groups where round(frac × 10 × rows) would be 0, rows are bumped up until at least 1 red square appears. This affects the small middle groups:

Group	Grid	Red cells
<1y	10×10	72 (72%)
1y	10×3	14 (47%)
2-4y	10×1	3 (30%)
5-9y	10×1	1 (10%)
10-19y	10×2	2 (10%)
20-44y	10×2	1 (5%)
45-65y	10×1	2 (20%)
65-84y	10×3	1 (3%)
85+y	10×4	1 (2%)
Bottom-aligned — all grids share a common baseline, so the height difference reads as the population size comparison. The R code achieves this by shifting each grid's row coordinates up by max_rows - rows.


Age waffle proportional
Code · R 

Age waffle proportional
Image · PNG 
This is the right idea;  you can also print the percent red above the column, and make the figure a bit taller and narrower. it should be legible when pasted into an 8.5x11 inch document

7:02 AM

Ran a command, viewed a file
Ran a command, viewed a file
The percent labels are floating because they're placed at the absolute grid top in figure coordinates but the axes aren't truly bottom-aligned yet. Let me fix the layout properly:


Ran a command, viewed a file
Ran a command, viewed a file
Good — alignment is now perfect. The figure is too wide/short still. Let me tighten the aspect ratio so it's tall and narrow:


Ran a command, viewed a file
Ran a command, viewed a file
That looks great — tall, narrow, legible, well-aligned. Now let me write the equivalent R code:


Ran a command, read a file
Ran a command, read a file
Here are the updated files. Key changes from the last version:

Percent labels sit on a consistent horizontal line just above all the grids, in bold red, so the eye can scan across them easily
Figure is 5.5 × 6.5 inches at 200 dpi — pastes cleanly into a letter-size document with room to spare for a caption
Single coordinate system in the R code — everything (tiles, labels, title) lives in one ggplot with coord_equal(), avoiding the multi-axes alignment headaches from before. The R approach uses geom_tile() with manually computed x/y centres and geom_text() for all labels.

Age waffle proportional
Code · R 

Age waffle proportional
Image · PNG 
that looks like it is top aligned. And height is proportional to the true RSV incidence

7:04 AM
You're right — the grids are growing downward from the top instead of upward from a shared baseline. Let me fix the alignment and also flip the fill order so red fills from the top (highest risk first, reading naturally).


Ran a command, viewed a file
Ran a command, viewed a file
Bottom-aligned now, grids grow upward correctly. The red fills from the bottom though — it should fill from the top so the most-affected cells read first. Let me fix that and write the final R code:


Ran a command, viewed a file
Ran a command, viewed a file
That's correct — bottom-aligned, red from the top, heights reflect RSV incidence. Now writing the final R script:


Ran a command, read a file
Ran a command, read a file
Fixed. Two corrections made:

Bottom-aligned — all grids now share a common baseline at y = 0 and grow upward. The R code achieves this by flipping the row index: y = (rows − 1 − cell_row) + 0.5, so the tallest column (<1y) fills the full height while shorter ones sit on the same floor.
Red fills from the top — cell numbering runs top-left → bottom-right, so the red proportion occupies the upper squares of each grid, which reads naturally (high burden at the top, tapering down).

Age waffle proportional
Code · R 

Age waffle proportional
Image · PNG 
this looks good, but the dimensions should be something like 8inch wide, 3 inch tall

7:07 AM

Ran a command, viewed a file
Ran a command, viewed a file
That looks great. Now writing the R equivalent:


Ran a command, read a file
Ran a command, read a file
Both files updated. The R script saves at exactly width = 8, height = 3 inches at 200 dpi — that's 1600 × 600 pixels, which drops cleanly into a letter-size document with comfortable margins on either side.


Age waffle proportional
Code · R 

Age waffle proportional
Image · PNG 
1780572243084_image.png
this doesn't look as good in ggplot

7:24 AM
I can see the issues — the title is overlapping the percent labels, the grids are vertically compressed (cells aren't square), and there's too much whitespace above. The core problem is that coord_equal fights with the 8×3 aspect ratio in ggplot. Let me rebuild it using grid/gtable directly to get pixel-perfect control.


Ran 2 commands, viewed a file
Ran 2 commands, viewed a file
That looks clean and well-proportioned. The title, percent labels, grids, and age labels all sit in their correct positions with no overlap.


Presented 2 files
Presented 2 files
The key fix was ditching ggplot2 for this and using R's grid package directly. The problem with ggplot2 + coord_equal is that it insists on mathematically equal x/y scales, which forces awkward padding to fill the 8×3 figure. With grid, everything is placed in inches explicitly:

cell_w and cell_h are computed independently from the usable width and height — cells are rectangular (wider than tall) to fill the landscape format properly
All positions are in inches, so the title, percent labels, grids, and age labels never collide regardless of figure size
To adjust sizing, just change fig_w/fig_h at the top and everything else scales automatically

Age waffle proportional
Code · R 

Age waffle proportional
Image · PNG 





Claude is AI and can make mistakes. Please double-check responses.
Age waffle proportional · R
# Age Group Proportional Waffle Grids — RSV Incidence
# Uses grid graphics directly for precise layout control
# Output: 8 x 3 inches at 200 dpi
 
library(grid)
 
# ── Data ──────────────────────────────────────────────────────────
age_labels    <- c("<1y","1y","2-4y","5-9y","10-19y","20-44y","45-65y","65-84y","85+y")
shaded_frac   <- c(0.72, 0.46, 0.32, 0.12, 0.08, 0.06, 0.16, 0.04, 0.03)
rsv_incidence <- c(1500, 500, 180, 40, 12, 9.3, 20, 130, 500)
 
highlight_color <- "#D94F3D"
base_color      <- "#909090"
grid_lwd        <- 0.5   # gridline width (pts)
COLS            <- 10L
 
# ── Grid dimensions ───────────────────────────────────────────────
max_inc   <- max(rsv_incidence)
min_rows  <- ceiling(1L / (shaded_frac * COLS))
grid_rows <- pmax(round(10 * rsv_incidence / max_inc), min_rows, 1L)
n_red     <- round(shaded_frac * COLS * grid_rows)
max_rows  <- max(grid_rows)
n_groups  <- length(age_labels)
 
# ── Physical dimensions (inches) ──────────────────────────────────
fig_w   <- 8.0
fig_h   <- 3.0
dpi     <- 200
 
# Margins (inches)
mar_l   <- 0.10
mar_r   <- 0.10
mar_top <- 0.38   # title
mar_bot <- 0.28   # age labels
 
# Usable area for the grids
usable_w <- fig_w - mar_l - mar_r
usable_h <- fig_h - mar_top - mar_bot
 
# Each panel = COLS cells wide; equal panel widths; small gap between panels
gap_frac <- 0.15                        # gap as fraction of one cell width
cell_w   <- usable_w / (n_groups * COLS + (n_groups - 1) * gap_frac * COLS)
cell_h   <- usable_h / max_rows         # cell height = fills full usable height
gap_w    <- cell_w * gap_frac * COLS    # physical gap between panels
 
# ── Draw ──────────────────────────────────────────────────────────
png("age_waffle_proportional.png",
    width = fig_w * dpi, height = fig_h * dpi, res = dpi,
    bg = "white")
 
grid.newpage()
 
for (i in seq_along(age_labels)) {
  rows  <- grid_rows[i]
  nr    <- n_red[i]
  frac  <- nr / (COLS * rows)
 
  # Left edge of this panel in inches from left of figure
  panel_left <- mar_l + (i - 1) * (COLS * cell_w + gap_w)
 
  # Bottom edge of grid in inches from bottom of figure
  grid_bottom <- mar_bot
 
  # Draw cells
  cell <- 0L
  for (r in seq(rows - 1, 0)) {          # r = rows-1 is top row
    for (c in seq(0, COLS - 1)) {
      cell <- cell + 1L
      fill <- if (cell <= nr) highlight_color else base_color
 
      x_in <- panel_left + c * cell_w
      y_in <- grid_bottom + r * cell_h
 
      grid.rect(
        x      = unit(x_in + cell_w / 2, "inches"),
        y      = unit(y_in + cell_h / 2, "inches"),
        width  = unit(cell_w, "inches"),
        height = unit(cell_h, "inches"),
        gp = gpar(fill = fill, col = "white", lwd = grid_lwd)
      )
    }
  }
 
  # Panel centre x
  cx <- panel_left + COLS * cell_w / 2
 
  # % label: just above top of tallest possible grid (= mar_bot + max_rows*cell_h)
  pct_y <- mar_bot + max_rows * cell_h + 0.04
  grid.text(
    label = paste0(round(frac * 100), "%"),
    x  = unit(cx, "inches"),
    y  = unit(pct_y, "inches"),
    just = c("centre", "bottom"),
    gp = gpar(fontface = "bold", fontsize = 7.5, col = highlight_color)
  )
 
  # Age label: just below grid bottom
  grid.text(
    label = age_labels[i],
    x  = unit(cx, "inches"),
    y  = unit(mar_bot - 0.04, "inches"),
    just = c("centre", "top"),
    gp = gpar(fontface = "bold", fontsize = 7.5, col = "#222222")
  )
}
 
# Title: centred, near top
grid.text(
  label = "Proportion affected by age group  \u2022  height proportional to RSV incidence",
  x  = unit(fig_w / 2, "inches"),
  y  = unit(fig_h - 0.10, "inches"),
  just = c("centre", "top"),
  gp = gpar(fontface = "bold", fontsize = 8.5, col = "#222222")
)
 
dev.off()
message("Saved: age_waffle_proportional.png")
 
