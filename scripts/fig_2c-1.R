########### fig_2c.R — Measured vs. modelled soil properties ###################
###
### Panel 1: soil pH          (WoSIS points vs. SoilGrids 1km phh2o)
### Panel 2: soil organic C   (WoSIS points vs. SoilGrids 1km soc)
### Panel 3: soil temperature (SoilTemp sensors vs. SBIO1 map, Lembrechts et al. 2022)
### Three delta-distribution insets
###
### Modelled layers are 0-5 cm; measured values are WoSIS layers from 0 to max.
### 10 cm depth and SoilTemp loggers between 0 and -5 cm.

## 1. Basics ------------------------------------------------------------------

# load packages
library(terra)
library(ggplot2)
library(patchwork)
library(data.table)


## 2. Prepare wosis data -------------------------------------------------------

# read files
ph   <- fread("data/fig_2c/wosis_202312_phaq.tsv")
orgc <- fread("data/fig_2c/wosis_202312_orgc.tsv")

# extract topsoil only
top <- function(d) {
  d <- d[organic_surface != "t"]                 # drop litter/O layers above mineral surface
  d <- d[upper_depth == 0 & lower_depth <= 10]   # topsoil, 0 to max. 10 cm
  d <- d[!is.na(value_avg) & !is.na(longitude)]
  # one value per profile (mean over qualifying layers)
  d[, .(value = mean(value_avg),
        x = longitude[1], y = latitude[1]), by = profile_id]
}

ph_top  <- top(ph);   setnames(ph_top,  "value", "ph_measured")
soc_top <- top(orgc); setnames(soc_top, "value", "soc_measured")

# merge
wosis <- merge(ph_top, soc_top[, .(profile_id, soc_measured)],
               by = "profile_id", all = TRUE)

# keep coordinates from soc side for profiles lacking pH
wosis <- merge(wosis, soc_top[, .(profile_id, x2 = x, y2 = y)],
               by = "profile_id", all.x = TRUE)
wosis[is.na(x), `:=`(x = x2, y = y2)]
wosis[, c("x2", "y2") := NULL]

# write results
fwrite(wosis, "data/fig_2c/wosis_topsoil.csv")
nrow(wosis); summary(wosis$ph_measured); summary(wosis$soc_measured)


## 3. Load modelled layers -----------------------------------------------------

# SoilGrids 1km aggregated layers
options(timeout = 600)
if (!file.exists("data/fig_2c/phh2o_1km.tif"))
  download.file("https://files.isric.org/soilgrids/latest/data_aggregated/1000m/phh2o/phh2o_0-5cm_mean_1000.tif",
                "data/fig_2c/phh2o_1km.tif", mode = "wb")
if (!file.exists("data/fig_2c/soc_1km.tif"))
  download.file("https://files.isric.org/soilgrids/latest/data_aggregated/1000m/soc/soc_0-5cm_mean_1000.tif",
                "data/fig_2c/soc_1km.tif", mode = "wb")
sg_ph  <- rast("data/fig_2c/phh2o_1km.tif")
sg_soc <- rast("data/fig_2c/soc_1km.tif")
sbio1  <- rast("data/fig_2c/SBIO1_Annual_Mean_Temperature_0_5cm.tif")


## 4. Measured soil pH and SOC -------------------------------------------------

# prepare data
chem <- read.csv("data/fig_2c/wosis_topsoil.csv")
chem <- chem[!is.na(chem$x) & !is.na(chem$y), ]

# pojection of points
pts_chem <- vect(chem, geom = c("x", "y"), crs = "EPSG:4326")
pts_chem <- project(pts_chem, crs(sg_ph))
chem$ph_sg  <- extract(sg_ph,  pts_chem)[, 2] / 10   # phh2o stored as pH x 10
chem$soc_sg <- extract(sg_soc, pts_chem)[, 2] / 10   # soc stored as dg/kg -> g/kg


## 5. Measured soil temperature ------------------------------------------------

# prepare data
csv_file <- list.files("data/fig_2c", pattern = "SoilTemp.*\\.csv$", full.names = TRUE)[1]
sensors  <- read.csv(csv_file)
names(sensors)[names(sensors) == "Longitude"] <- "x"
names(sensors)[names(sensors) == "Latitude"]  <- "y"
sensors <- sensors[!is.na(sensors$x) & !is.na(sensors$AnnualTs), ]
sensors <- sensors[sensors$Completeness > 0.95, ]
sensors <- sensors[sensors$Height <= 0 & sensors$Height >= -5, ]   # 0-5 cm layer

# projection of points
pts_temp <- vect(sensors, geom = c("x", "y"), crs = "EPSG:4326")
sensors$Ts_map <- extract(sbio1, pts_temp)[, 2]


## 6. Analysis data sets -------------------------------------------------------

# pH
d_ph <- chem[!is.na(chem$ph_sg) & !is.na(chem$ph_measured), ]
d_ph$delta <- d_ph$ph_sg - d_ph$ph_measured
r2_ph   <- cor(d_ph$ph_sg, d_ph$ph_measured)^2

# soil organic carbon
d_soc <- chem[!is.na(chem$soc_sg) & !is.na(chem$soc_measured), ]
d_soc <- d_soc[d_soc$soc_measured > 0 & d_soc$soc_sg > 0, ]
d_soc$delta <- log10(d_soc$soc_sg) - log10(d_soc$soc_measured)
r2_soc   <- cor(log10(d_soc$soc_sg), log10(d_soc$soc_measured))^2

# temperature
d_temp <- sensors[!is.na(sensors$Ts_map), ]
# average across years -> one value per sensor
d_temp <- aggregate(cbind(AnnualTs, Ts_map) ~ Plotcode, data = d_temp, FUN = mean)
d_temp$delta <- d_temp$Ts_map - d_temp$AnnualTs
r2_temp   <- cor(d_temp$Ts_map, d_temp$AnnualTs)^2


## 7. Style --------------------------------------------------------------------

# define style
col_magenta <- "#B93B7F"

theme_biorender <- theme_classic(base_family = "Helvetica") +
  theme(plot.title  = element_text(face = "bold", size = 13, hjust = 0),
        axis.title  = element_text(size = 11),
        axis.text   = element_text(size = 10, color = "black"),
        axis.line   = element_line(linewidth = 0.4),
        axis.ticks  = element_line(linewidth = 0.4, color = "black"),
        plot.margin = margin(6, 10, 6, 6))


## 8. Left panel: soil pH ------------------------------------------------------

# plot soil pH
p1 <- ggplot(d_ph, aes(ph_measured, ph_sg)) +
  geom_point(size = 0.5, alpha = 0.15, color = "grey55") +
  geom_abline(aes(intercept = 0, slope = 1),
              linetype = "dashed", color = "black", linewidth = 0.4) +
  geom_smooth(method = "lm", formula = y ~ x,
              color = col_magenta, se = FALSE, linewidth = 1.6) +
  coord_equal(xlim = c(3, 10), ylim = c(3, 10), expand = FALSE) +
  theme_biorender +
  xlab("Measured soil pH") + ylab("Modelled soil pH") +
  ggtitle("Soil pH") +
  annotate("text", x = 9.35, y = 9.75, label = "1:1", size = 3,
           family = "Helvetica", angle = 45) +
  annotate("text", x = 3.3, y = 9.6, hjust = 0, vjust = 1, size = 3.5,
           family = "Helvetica",
           label = sprintf("R² = %.2f", r2_ph))


## 9. Middle panel: soil organic carbon (log scales) ---------------------------

# plot soil organic carbon (range set with coord_equal, so the fit uses all data)
p2 <- ggplot(d_soc, aes(soc_measured, soc_sg)) +
  geom_point(size = 0.5, alpha = 0.15, color = "grey55") +
  geom_abline(aes(intercept = 0, slope = 1),
              linetype = "dashed", color = "black", linewidth = 0.4) +
  geom_smooth(method = "lm", formula = y ~ x,
              color = col_magenta, se = FALSE, linewidth = 1.6) +
  scale_x_log10() +
  scale_y_log10() +
  coord_equal(xlim = c(1, 600), ylim = c(1, 600), expand = FALSE) +
  theme_biorender +
  xlab("Measured SOC (g/kg)") + ylab("Modelled SOC (g/kg)") +
  ggtitle("Soil organic carbon") +
  annotate("text", x = 420, y = 520, label = "1:1", size = 3,
           family = "Helvetica", angle = 45) +
  annotate("text", x = 1.3, y = 450, hjust = 0, vjust = 1, size = 3.5,
           family = "Helvetica",
           label = sprintf("R² = %.2f", r2_soc))


## 10. Right Panel: soil temperature -------------------------------------------

# plot soil temperature
p3 <- ggplot(d_temp, aes(AnnualTs, Ts_map)) +
  geom_point(size = 0.5, alpha = 0.15, color = "grey55") +
  geom_abline(aes(intercept = 0, slope = 1),
              linetype = "dashed", color = "black", linewidth = 0.4) +
  geom_smooth(method = "lm", formula = y ~ x,
              color = col_magenta, se = FALSE, linewidth = 1.6) +
  coord_equal(xlim = c(-15, 35), ylim = c(-15, 35), expand = FALSE) +
  theme_biorender +
  xlab("Measured soil temperature (°C)") +
  ylab("Modelled soil temperature (°C)") +
  ggtitle("Soil temperature") +
  annotate("text", x = 30.5, y = 33, label = "1:1", size = 3,
           family = "Helvetica", angle = 45) +
  annotate("text", x = -13, y = 32, hjust = 0, vjust = 1, size = 3.5,
           family = "Helvetica",
           label = sprintf("R² = %.2f", r2_temp))

p_all <- p1 + p2 + p3 + plot_layout(ncol = 3)
ggsave("results/fig_2c/fig_2c.pdf", p_all, device = cairo_pdf,
       width = 330, height = 115, units = "mm")


## 11. Delta-distribution insets (modelled - measured, median line) ------------

# define style
theme_inset <- theme_classic(base_family = "Helvetica") +
  theme(axis.title    = element_text(size = 8),
        axis.text     = element_text(size = 7, color = "black"),
        axis.line     = element_line(linewidth = 0.3),
        axis.ticks    = element_line(linewidth = 0.3, color = "black"),
        axis.title.y  = element_blank(),
        axis.text.y   = element_blank(),
        axis.ticks.y  = element_blank(),
        axis.line.y   = element_blank(),
        panel.background = element_rect(fill = "transparent", color = NA),
        plot.background  = element_rect(fill = "transparent", color = NA),
        plot.margin   = margin(2, 4, 2, 2))

# plot pH delta
i1 <- ggplot(d_ph, aes(delta)) +
  geom_density(fill = "grey80", color = "grey40", linewidth = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.3) +
  geom_vline(xintercept = median(d_ph$delta),
             color = col_magenta, linewidth = 0.8) +
  coord_cartesian(xlim = c(-2.5, 2.5)) +
  theme_inset +
  xlab("Δ pH (modelled - measured)") +
  theme(axis.title.x = element_text(size = 6)) +
  theme(axis.text.x = element_text(size = 6))

# plot soil organic carbon delta
i2 <- ggplot(d_soc, aes(delta)) +
  geom_density(fill = "grey80", color = "grey40", linewidth = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.3) +
  geom_vline(xintercept = median(d_soc$delta),
             color = col_magenta, linewidth = 0.8) +
  coord_cartesian(xlim = c(-1.5, 1.5)) +
  theme_inset +
  xlab("Δ log10 SOC (modelled - measured)") +
  theme(axis.title.x = element_text(size = 6)) +
  theme(axis.text.x = element_text(size = 6))

# plot temperature delta
i3 <- ggplot(d_temp, aes(delta)) +
  geom_density(fill = "grey80", color = "grey40", linewidth = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.3) +
  geom_vline(xintercept = median(d_temp$delta),
             color = col_magenta, linewidth = 0.8) +
  coord_cartesian(xlim = c(-8, 8)) +
  theme_inset +
  xlab("Δ temperature (°C, modelled - measured)") +
  theme(axis.title.x = element_text(size = 6)) +
  theme(axis.text.x = element_text(size = 6))

# save plots
ggsave("results/fig_2c/fig_2c_inset_pH.pdf",   i1, device = cairo_pdf,
       width = 45, height = 32, units = "mm", bg = "transparent")
ggsave("results/fig_2c/fig_2c_inset_SOC.pdf",  i2, device = cairo_pdf,
       width = 45, height = 32, units = "mm", bg = "transparent")
ggsave("results/fig_2c/fig_2c_inset_temp.pdf", i3, device = cairo_pdf,
       width = 45, height = 32, units = "mm", bg = "transparent")


## 12. Summary statistics text file --------------------------------------------

# mean delta values
bias_ph   <- mean(d_ph$delta)
bias_soc  <- mean(d_soc$delta)
bias_temp <- mean(d_temp$delta)

# typical deviation at a site (median absolute delta)
mad_ph   <- median(abs(d_ph$delta))
mad_soc  <- median(abs(d_soc$delta))
mad_temp <- median(abs(d_temp$delta))
fold_mad_soc <- 10^mad_soc                     # log10 units -> fold difference

# root mean square deviation
rmsd_ph   <- sqrt(mean(d_ph$delta^2))
rmsd_soc  <- sqrt(mean(d_soc$delta^2))
rmsd_temp <- sqrt(mean(d_temp$delta^2))
fold_rmsd_soc <- 10^rmsd_soc

# bias per class of the measured value (shows distortion along the gradient)
soc_bins  <- tapply(d_soc$delta,
                    cut(d_soc$soc_measured, c(0, 10, 50, 150, Inf)), mean)
temp_bins <- tapply(d_temp$delta,
                    cut(d_temp$AnnualTs, c(-Inf, 5, 15, 25, Inf)), mean)

# write stats
stats_out <- c(
  "Fig. 2 C: measured vs. modelled soil properties",
  "measured: WoSIS layers 0 cm to max. 10 cm depth; SoilTemp loggers 0 to -5 cm",
  "modelled: SoilGrids and SBIO1 layers for 0-5 cm",
  paste0("generated: ", format(Sys.time(), "%Y-%m-%d %H:%M")),
  "",
  "--- Soil pH (WoSIS vs. SoilGrids 1km phh2o) ---",
  sprintf("n            = %d profiles", nrow(d_ph)),
  sprintf("R2           = %.3f", r2_ph),
  sprintf("mean bias    = %+.3f pH units", bias_ph),
  sprintf("median delta = %+.3f pH units", median(d_ph$delta)),
  sprintf("median |delta| = %.3f pH units (typical deviation at a site)", mad_ph),
  sprintf("RMSD         = %.3f pH units", rmsd_ph),
  "",
  "--- Soil organic carbon (WoSIS vs. SoilGrids 1km soc; log10 g/kg) ---",
  sprintf("n            = %d profiles", nrow(d_soc)),
  sprintf("R2           = %.3f", r2_soc),
  sprintf("mean bias    = %+.3f log10 units", bias_soc),
  sprintf("median delta = %+.3f log10 units", median(d_soc$delta)),
  sprintf("median |delta| = %.3f log10 units = %.2f-fold (typical deviation at a site)",
          mad_soc, fold_mad_soc),
  sprintf("RMSD         = %.3f log10 units = %.2f-fold", rmsd_soc, fold_rmsd_soc),
  "bias by class of measured SOC (g/kg):",
  paste(sprintf("  %-10s %+.3f", names(soc_bins), soc_bins), collapse = "\n"),
  "",
  "--- Soil temperature (SoilTemp sensors vs. SBIO1; sensor means across years) ---",
  sprintf("n            = %d sensors", nrow(d_temp)),
  sprintf("R2           = %.3f", r2_temp),
  sprintf("mean bias    = %+.3f degC", bias_temp),
  sprintf("median delta = %+.3f degC", median(d_temp$delta)),
  sprintf("median |delta| = %.3f degC (typical deviation at a site)", mad_temp),
  sprintf("RMSD         = %.3f degC", rmsd_temp),
  "bias by class of measured temperature (degC):",
  paste(sprintf("  %-12s %+.3f", names(temp_bins), temp_bins), collapse = "\n"),
  "",
  "Note: WoSIS profiles and SoilTemp sensors contributed to training of the",
  "respective products; values represent map-observation agreement, not",
  "independent validation."
)

# save stats to .txt file
writeLines(stats_out, "results/fig_2c/fig_2c_stats.txt")
cat(stats_out, sep = "\n")
