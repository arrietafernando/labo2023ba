# Corrida general del workflow

options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})


# corrida de cada paso del workflow

# primeros pasos, relativamente rapidos
#/Users/fernando/Dropbox/MBA/UA - Catedra Labo I/labo_github/github/labo2023ba_RStudio/src/workflow-inicial/611_CA_reparar_dataset_001.r
source("/Users/fernando/Dropbox/MBA/UA - Catedra Labo I/labo_github/github/labo2023ba_RStudio/src/workflow-inicial/611_CA_reparar_dataset_001.r")
source("/Users/fernando/Dropbox/MBA/UA - Catedra Labo I/labo_github/github/labo2023ba_RStudio/src/workflow-inicial/621_DR_corregir_drifting_001.r")
source("/Users/fernando/Dropbox/MBA/UA - Catedra Labo I/labo_github/github/labo2023ba_RStudio/src/workflow-inicial/631_FE_historia_001.r")
source("/Users/fernando/Dropbox/MBA/UA - Catedra Labo I/labo_github/github/labo2023ba_RStudio/src/workflow-inicial/641_TS_training_strategy_001.r")

# ultimos pasos, muy lentos
source("/Users/fernando/Dropbox/MBA/UA - Catedra Labo I/labo_github/github/labo2023ba_RStudio/src/workflow-inicial/651_HT_lightgbm_001.r")
source("/Users/fernando/Dropbox/MBA/UA - Catedra Labo I/labo_github/github/labo2023ba_RStudio/src/workflow-inicial/661_ZZ_final_001.r")
