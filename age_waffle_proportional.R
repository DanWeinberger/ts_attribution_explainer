# Age Group Proportional Waffle Grids — RSV Incidence
# Output: 8 x 3 inches, suitable for an 8.5x11" document

library(ggplot2)
library(dplyr)

# ── Data ──────────────────────────────────────────────────────────
age_labels    <- c("<1y","1y","2-4y","5-9y","10-19y","20-44y","45-65y","65-84y","85+y")
shaded_frac   <- c(0.72, 0.46, 0.32, 0.12, 0.08, 0.06, 0.16, 0.04, 0.03)
rsv_incidence <- c(1500, 500, 180, 40, 12, 9.3, 20, 130, 500)

highlight_color <- "#D94F3D"
base_color      <- "#909090"
grid_color      <- "white"
COLS            <- 10L
GAP             <- 2L

# ── Grid dimensions ───────────────────────────────────────────────
max_inc   <- max(rsv_incidence)
min_rows  <- ceiling(1L / (shaded_frac * COLS))
grid_rows <- pmax(round(10 * rsv_incidence / max_inc), min_rows, 1L)
n_red     <- round(shaded_frac * COLS * grid_rows)
max_rows  <- max(grid_rows)
total_x   <- length(age_labels) * COLS + (length(age_labels) - 1L) * GAP

# ── Tile data ─────────────────────────────────────────────────────
# Cells numbered top-to-bottom, left-to-right; red fills from the top.
# Grids are bottom-aligned: bottom of every grid sits at y = 0.
tile_df <- do.call(rbind, lapply(seq_along(age_labels), function(i) {
  rows  <- grid_rows[i]
  total <- COLS * rows
  cells <- seq_len(total)
  x0    <- (i - 1L) * (COLS + GAP)
  cell_row <- (cells - 1L) %/% COLS   # 0 = top row
  cell_col <- (cells - 1L) %% COLS
  data.frame(
    x      = x0 + cell_col + 0.5,
    y      = (rows - 1L - cell_row) + 0.5,   # flip: top row → highest y
    shaded = cells <= n_red[i]
  )
}))

# ── Labels ────────────────────────────────────────────────────────
x_centres <- (seq_along(age_labels) - 1L) * (COLS + GAP) + COLS / 2

pct_df <- data.frame(
  x     = x_centres,
  y     = max_rows + 0.15,
  label = paste0(round(n_red / (COLS * grid_rows) * 100), "%")
)

age_df <- data.frame(
  x     = x_centres,
  y     = -0.15,
  label = age_labels
)

# ── Plot ──────────────────────────────────────────────────────────
p <- ggplot(tile_df, aes(x = x, y = y)) +
  geom_tile(aes(fill = shaded), width = 1, height = 1,
            color = grid_color, linewidth = 0.35) +
  scale_fill_manual(
    values = c("FALSE" = base_color, "TRUE" = highlight_color),
    guide  = "none"
  ) +
  geom_text(data = pct_df, aes(x = x, y = y, label = label),
            inherit.aes = FALSE,
            fontface = "bold", size = 2.4, color = highlight_color, vjust = 0) +
  geom_text(data = age_df, aes(x = x, y = y, label = label),
            inherit.aes = FALSE,
            fontface = "bold", size = 2.4, color = "#222222", vjust = 1) +
  ggtitle("Proportion affected by age group  \u2022  height proportional to RSV incidence") +
  coord_equal(
    xlim   = c(-0.5, total_x + 0.5),
    ylim   = c(-0.9, max_rows + 0.9),
    expand = FALSE
  ) +
  theme_void() +
  theme(
    plot.title = element_text(face = "bold", size = 8.5, hjust = 0.5,
                              margin = margin(b = 4)),
    plot.margin = margin(6, 4, 4, 4)
  )

ggsave("age_waffle_proportional.png", p,
       width = 8, height = 3, dpi = 200, bg = "white")

message("Saved: age_waffle_proportional.png")
