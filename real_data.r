library(tidyverse)
library(MMWRweek)
library(epidatr)
library(RSocrata)

cache_file <- "data/flu_pi_weekly.rds"

if (file.exists(cache_file)) {
  combined <- readRDS(cache_file)
  pi_deaths <- combined %>% select(date, deaths_from_pneumonia)
  flu       <- combined %>% select(date, rate_overall, season, location)
} else {
  pi_deaths <- read.socrata('https://data.cdc.gov/api/v3/views/pp7x-dyj2/') %>%
    filter(region == 1) %>%
    arrange(mmwr_year_week) %>%
    mutate(
      mmwr_year = as.integer(substr(mmwr_year_week, 1, 4)),
      mmwr_week = as.integer(substr(mmwr_year_week, 5, 6)),
      date      = MMWRweek2Date(MMWRyear = mmwr_year, MMWRweek = mmwr_week)
    ) %>%
    dplyr::select(date, deaths_from_pneumonia)

  flu_raw <- epidatr::pub_flusurv(locations = "CT", epiweeks = epirange(201001, 202013)) %>%
    dplyr::select(location, season, epiweek, rate_overall) %>%
    mutate(
      mmwr_year = MMWRweek::MMWRweek(epiweek)$MMWRyear,
      mmwr_week = MMWRweek::MMWRweek(epiweek)$MMWRweek,
      date      = MMWRweek2Date(MMWRyear = mmwr_year, MMWRweek = mmwr_week)
    )

  # pub_flusurv only reports during the flu season; fill spring/summer gaps with 0
  flu <- tibble(date = seq(min(flu_raw$date), max(flu_raw$date), by = "1 week")) %>%
    left_join(flu_raw, by = "date") %>%
    mutate(rate_overall = tidyr::replace_na(rate_overall, 0))

  combined <- pi_deaths %>%
    inner_join(flu, by = "date") %>%
    arrange(date)

  if (!dir.exists("data")) dir.create("data")
  saveRDS(combined, cache_file)
}

plot_df <- combined %>%
  filter(date >= as.Date("2012-07-01"), date <= as.Date("2019-06-30"))

# Long-form data so each series gets its own facet with an independent y axis
panel_df <- plot_df %>%
  transmute(
    date,
    `Pneumonia deaths`         = deaths_from_pneumonia,
    `Influenza hospitalizations`    = rate_overall
  ) %>%
  pivot_longer(-date, names_to = "series", values_to = "value") %>%
  mutate(series = factor(series, levels = c(
    "Pneumonia deaths",
    "Influenza hospitalizations"
  )))

# Flu-season peaks: use July–June seasons so winter peaks aren't split across years
peak_dates <- plot_df %>%
  mutate(season_yr = if_else(month(date) >= 7, year(date), year(date) - 1L)) %>%
  group_by(season_yr) %>%
  slice_max(rate_overall, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  filter(rate_overall > 0) %>%
  pull(date)

panel_plot <- ggplot(panel_df, aes(x = date, y = value, colour = series)) +
  geom_vline(xintercept = peak_dates,
             colour = "grey60", linetype = "dashed", linewidth = 0.3) +
  geom_line(linewidth = 0.6) +
  facet_wrap(~ series, ncol = 1, scales = "free_y", strip.position = "left") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y",
               limits = as.Date(c("2012-07-01", "2019-06-30")),
               expand = c(0, 0)) +
  scale_colour_manual(values = c(
    "Pneumonia deaths"      = "#1f4e79",
    "Influenza hospitalizations" = "#c0392b"
  ), guide = "none") +
  labs(
    title    = "Weekly pneumonia deaths and influenza hospitalization",
    subtitle = "July 2012 – June 2019 (dashed lines mark each season's flu peak)",
    x        = NULL,
    y        = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor    = element_blank(),
    panel.grid.major    = element_blank(),
    panel.spacing.y     = unit(24, "pt"),
    plot.title          = element_text(face = "bold"),
    strip.placement     = "outside",
    strip.background    = element_blank(),
    strip.text.y.left   = element_text(angle = 90, face = "bold")
  )

panel_plot

if (!dir.exists("figures")) dir.create("figures")
ggsave(
  filename = "figures/pneumonia_flu_panels.png",
  plot     = panel_plot,
  width    = 10,
  height   = 6,
  units    = "in",
  dpi      = 600
)

# Pneumonia-only version: same aspect ratio, no peak guides
pneumonia_only_plot <- ggplot(
    filter(panel_df, series == "Pneumonia deaths"),
    aes(x = date, y = value)
  ) +
  ylim(0,NA)+
  geom_line(colour = "#1f4e79", linewidth = 0.6) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y",
               limits = as.Date(c("2012-07-01", "2019-06-30")),
               expand = c(0, 0)) +
  labs(
    title    = "Weekly pneumonia deaths",
    subtitle = "July 2012 - June 2019",
    x        = NULL,
    y        = "Pneumonia deaths"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    plot.title       = element_text(face = "bold")
  )

ggsave(
  filename = "figures/pneumonia_only.png",
  plot     = pneumonia_only_plot,
  width    = 10,
  height   = 6,
  units    = "in",
  dpi      = 600
)
