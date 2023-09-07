#'
#' Prueba
#'

# limpio la memoria
rm(list = ls()) # remove all objects
gc() # garbage collection

require("data.table")
require("lightgbm")

MIS_SEMILLAS = c(591067, 157991, 689987, 136999, 366467)

# defino los parametros de la corrida, en una lista, la variable global  PARAM
#  muy pronto esto se leera desde un archivo formato .yaml
PARAM <- list()
PARAM$experimento    <- "KA4240_3"

PARAM$input$dataset  <- "./datasets/dataset_pequeno.csv"
PARAM$input$training <- c(202107) # meses donde se entrena el modelo
PARAM$input$future   <- c(202109) # meses donde se aplica el modelo

#' Resultados script: 423_lightgbm_binaria_BO_001.r
PARAM$finalmodel$semilla          <- 157991 # segunda semilla usada para BO de hyperparametros
PARAM$finalmodel$num_iterations   <- 1476
PARAM$finalmodel$learning_rate    <- 0.0101517246779403
PARAM$finalmodel$feature_fraction <- 0.995021922590851
PARAM$finalmodel$min_data_in_leaf <- 1982
PARAM$finalmodel$num_leaves       <- 269
PARAM$finalmodel$max_bin          <- 31

#-------------------------------------------------------------------------------

# Aqui empieza el programa
setwd("~/buckets/b1")

# cargo el dataset donde voy a entrenar
dataset <- fread(PARAM$input$dataset, stringsAsFactors = TRUE)

#-------------------------------------------------------------------------------

# paso la clase a binaria que tome valores {0,1}  enteros
# set trabaja con la clase  POS = { BAJA+1, BAJA+2 }
# esta estrategia es MUY importante
dataset[, clase01 := ifelse(clase_ternaria %in% c("BAJA+2", "BAJA+1"), 1L, 0L)]

#-------------------------------------------------------------------------------

# los campos que se van a utilizar
campos_buenos <- setdiff(colnames(dataset), c("clase_ternaria", "clase01"))

#-------------------------------------------------------------------------------

# establezco donde entreno
dataset[, train := 0L]
dataset[foto_mes %in% PARAM$input$training, train := 1L]

#-------------------------------------------------------------------------------

# creo las carpetas donde van los resultados
# creo la carpeta donde va el experimento
dir.create("./exp/", showWarnings = FALSE)
dir.create(paste0("./exp/", PARAM$experimento, "/"), showWarnings = FALSE)

# Establezco el Working Directory DEL EXPERIMENTO
setwd(paste0("./exp/", PARAM$experimento, "/"))

#-------------------------------------------------------------------------------

# dejo los datos en el formato que necesita LightGBM
dtrain <- lgb.Dataset(
  data = data.matrix(dataset[train == 1L, campos_buenos, with = FALSE]),
  label = dataset[train == 1L, clase01]
)

# genero el modelo
# estos hiperparametros  salieron de una laaarga Optmizacion Bayesiana
modelo <- lgb.train(
  data = dtrain,
  param = list(
    objective        = "binary",
    max_bin          = PARAM$finalmodel$max_bin,
    learning_rate    = PARAM$finalmodel$learning_rate,
    num_iterations   = PARAM$finalmodel$num_iterations,
    num_leaves       = PARAM$finalmodel$num_leaves,
    min_data_in_leaf = PARAM$finalmodel$min_data_in_leaf,
    feature_fraction = PARAM$finalmodel$feature_fraction,
    seed             = PARAM$finalmodel$semilla
  )
)

#-------------------------------------------------------------------------------

# ahora imprimo la importancia de variables
tb_importancia <- as.data.table(lgb.importance(modelo))
archivo_importancia <- "impo.txt"

fwrite(tb_importancia,
       file = archivo_importancia,
       sep = "\t"
)

#-------------------------------------------------------------------------------

# aplico el modelo a los datos sin clase
dapply <- dataset[foto_mes == PARAM$input$future]

# aplico el modelo a los datos nuevos
prediccion <- predict(
  modelo,
  data.matrix(dapply[, campos_buenos, with = FALSE])
)

# genero la tabla de entrega
tb_entrega <- dapply[, list(numero_de_cliente, foto_mes)]
tb_entrega[, prob := prediccion]

# grabo las probabilidad del modelo
fwrite(tb_entrega,
       file = "prediccion.txt",
       sep = "\t"
)

#-------------------------------------------------------------------------------

# Evaluacion del modelo en training

# aplico el modelo a los datos de train
dapply_training <- dataset[foto_mes == PARAM$input$training]

prediccion <- predict(
  modelo,
  data.matrix(dapply_training[, campos_buenos, with = FALSE])
)

# genero la tabla de entrega
tb_entrega <- dapply_training[, list(numero_de_cliente, foto_mes)]
tb_entrega[, prob := prediccion]

# grabo las probabilidad del modelo
fwrite(tb_entrega,
       file = "prediccion_train.txt",
       sep = "\t"
)

#-------------------------------------------------------------------------------

lares::mplot_density(tag = dataset[train == 1, clase01], score = tb_entrega$prob)

lares::mplot_roc(tag = dataset[train == 1, clase01], score = tb_entrega$prob)

lares::mplot_cuts(score = tb_entrega$prob, splits = 25)

lares::mplot_splits(tag = dataset[train == 1, clase01], score = tb_entrega$prob)

lares::mplot_full(tag = dataset[train == 1, clase01], score = tb_entrega$prob)

