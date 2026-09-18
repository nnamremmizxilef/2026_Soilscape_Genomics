# **2026_Soilscape_Genomics**

## This is the git repository for the publication:

**[MANUSCRIPT TITLE]**

*The manuscript is not submitted yet. Title, authors, abstract and DOI will be added once it is.*


## Abstract

[ABSTRACT]


## Authors & Affiliations:

**Felix Zimmermann** (Swiss Federal Research Institute WSL, Birmensdorf, Switzerland; felix.zimmermann@wsl.ch; ORCID: 0009-0002-0762-2454)

**Benjamin Dauphin** (Swiss Federal Research Institute WSL, Birmensdorf, Switzerland; benjamin.dauphin@wsl.ch; ORCID: 0000-0003-0982-4252)


## Content:

This repository contains the code for **Figure 2 C**, which illustrates how well global soil
databases reproduce local measurements. Measured topsoil values are compared with the
corresponding predictions of global soil maps for 0-5 cm depth, for three properties:

* Soil pH and soil organic carbon: measured values from the WoSIS profile database
  (Batjes et al. 2024; n = 39,767 and 36,529 profiles), compared with SoilGrids 2.0
  (Poggio et al. 2021).
* Soil temperature: measured mean annual values from the SoilTemp sensor network, averaged
  across years per sensor (n = 1,432), compared with the global soil temperature maps of
  Lembrechts et al. (2022).

On the measurement side, all WoSIS layers starting at 0 cm and reaching no deeper than 10 cm
are used and averaged per profile, litter and organic surface layers are excluded, and of the
SoilTemp records only loggers between 0 and -5 cm with a completeness above 0.95 are kept.
Modelled values are extracted at each measurement location from the 1 km layers. The script
produces the three scatter panels, the three insets showing the distribution of the
deviations (modelled - measured), and a text file with the sample sizes, R², the mean and
median bias, the typical deviation at a site (median absolute delta), the root mean square
deviation and the bias binned along each gradient.


### Data:

The input data are **not** part of this repository. They are third-party datasets with
their own licences and citation requirements, and together they amount to roughly 1 GB.
The folder "data/fig_2c" is therefore empty after cloning and has to be filled before the
script can be run. Please keep the file names listed below, as the script expects them.

* Measured soil pH and SOC: "wosis_202312_phaq.tsv" (253 MB) and "wosis_202312_orgc.tsv"
  (190 MB). Both are contained in the [WoSIS snapshot December 2023](https://files.isric.org/public/wosis_snapshot/WoSIS_2023_December.zip)
  (ISRIC); download the zip archive and extract the two files.
* Modelled soil pH and SOC: "phh2o_1km.tif" (79 MB) and "soc_1km.tif" (225 MB), the 1 km
  aggregated [SoilGrids](https://files.isric.org/soilgrids/latest/data_aggregated/1000m/)
  layers for 0-5 cm (ISRIC). These two are downloaded by the script itself on the first
  run, so they do not have to be obtained manually.
* Modelled soil temperature: "SBIO1_Annual_Mean_Temperature_0_5cm.tif" (188 MB), from the
  [global soil bioclimatic variables](https://doi.org/10.5281/zenodo.7134169) of Lembrechts
  et al. (2022). The file is called "SBIO1_0_5cm_Annual_Mean_Temperature.tif" there and has
  to be renamed after downloading.
* Measured soil temperature: "SoilTemp_yearly_cleaned_corrected.csv" (66 MB), the yearly
  aggregated and corrected sensor records of the SoilTemp network, from
  ["Global Soil Temperature code and data", version 2](https://doi.org/10.5281/zenodo.7970893)
  on Zenodo. Note that the corrected file is only in version 2 of that record, not in the
  first one.
* "wosis_topsoil.csv" is written by the script itself from the two WoSIS files and does not
  have to be supplied.

If you use any of these layers, please cite the original data providers as well.


### Scripts:

* Here you can find the script for the [comparison of measured and modelled soil properties](scripts/fig_2c.R).


### Results:

* Here you can find the [three-panel figure](results/fig_2c/fig_2c.pdf) (soil pH, SOC,
  soil temperature).
* Here you can find the delta-distribution insets for
  [pH](results/fig_2c/fig_2c_inset_pH.pdf), [SOC](results/fig_2c/fig_2c_inset_SOC.pdf) and
  [soil temperature](results/fig_2c/fig_2c_inset_temp.pdf).
* Here you can find the [summary statistics](results/fig_2c/fig_2c_stats.txt) (sample sizes,
  R², bias, typical and root mean square deviation, and biases binned along each gradient).

The panels and insets are assembled into the final figure layout externally.


## To use our code:

1. Download/clone repository.

2. Open the "soilscape_genomics.Rproj" file with RStudio.

3. Download the input data listed above and place them in "data/fig_2c". The script does
   not run without them.

4. Run the script (you can find "Scripts" under "Files" in the "Files/Plots/Packages etc."
   window). The two SoilGrids layers are downloaded on the first run, which takes a while;
   the timeout is set to 600 s in the script. All outputs are written to "results/fig_2c".

The script was run with R [VERSION] and needs the packages "terra", "ggplot2", "patchwork"
and "data.table". The figures are exported with cairo_pdf in Helvetica; if that font is not
available, another sans-serif family can be set in "theme_biorender" and "theme_inset".


## Note on the comparison:

The measurement networks contributed to the training of the products they are compared with
here. The comparison therefore shows how well the maps agree with the observations that went
into them; agreement at independent sites will be lower.


## References of the data sources:

Batjes, N.H., Calisto, L. and de Sousa, L.M. (2024), Providing quality-assessed and
standardised soil data to support global mapping and modelling (WoSIS snapshot 2023). Earth
Syst. Sci. Data, 16: 4735-4765. [https://doi.org/10.5194/essd-16-4735-2024](https://doi.org/10.5194/essd-16-4735-2024)

Poggio, L., de Sousa, L.M., Batjes, N.H., Heuvelink, G.B.M., Kempen, B., Ribeiro, E. and
Rossiter, D. (2021), SoilGrids 2.0: producing soil information for the globe with quantified
spatial uncertainty. SOIL, 7: 217-240. [https://doi.org/10.5194/soil-7-217-2021](https://doi.org/10.5194/soil-7-217-2021)

Lembrechts, J.J., van den Hoogen, J., Aalto, J. et al. (2022), Global maps of soil
temperature. Glob. Change Biol., 28: 3110-3144. [https://doi.org/10.1111/gcb.16060](https://doi.org/10.1111/gcb.16060)


## Citation:

[AUTHORS] ([YEAR]), [TITLE]. *[JOURNAL]*, [VOLUME]: [ARTICLE]. [DOI]


## Link to publication:

[DOI]


## License:

The code in this repository is published under [CC0 1.0 Universal](LICENSE). The input
datasets are not part of this repository and remain under the licences and citation
requirements of their original providers.
