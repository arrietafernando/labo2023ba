#requiere de 64GB de memoria RAM y 8 vCPU, 35 minutos para correr
require("data.table")
require("lightgbm")
require("yaml")

#limpio la memoria
rm(list = ls())
gc()

# Parametros del script
MIS_SEMILLAS = c(591067, 157991, 689987, 136999, 366467)

PARAM <- list()
PARAM$experimento <- "SB0001"

#PARAM$home <- "~/buckets"
PARAM$home <- "~/buckets/b1"

PARAM$exp_folder  <- paste(PARAM$home, "exp",  PARAM$experimento, sep = "/")

PARAM$input$dataset <- paste(PARAM$home, "datasets", "competencia_2023.csv.gz", sep = "/")

PARAM$input$train  <- c( 202107, 202106, 202105, 202104, 202103, 202102, 
                        202101, 202012, 202011, 202010, 202009, 202008, 202002, 202001, 201912,
                        201911, 201910, 201909 )

PARAM$input$future <- c(202109) # meses donde se aplica el modelo

# Semillas propias
PARAM$lgb_semilla <- MIS_SEMILLAS[1]

# Hiperparametros FIJOS de  lightgbm
PARAM$lgb_basicos <- list(
  boosting = "gbdt", # puede ir  dart  , ni pruebe random_forest
  objective = "binary",
  metric = "custom",
  first_metric_only = TRUE,
  boost_from_average = TRUE,
  feature_pre_filter = FALSE,
  force_row_wise = TRUE, # para reducir warnings
  verbosity = -100,
  max_depth = -1L, # -1 significa no limitar,  por ahora lo dejo fijo
  min_gain_to_split = 0.0, # min_gain_to_split >= 0.0
  min_sum_hessian_in_leaf = 0.001, #  min_sum_hessian_in_leaf >= 0.0
  lambda_l1 = 0.0, # lambda_l1 >= 0.0
  lambda_l2 = 0.0, # lambda_l2 >= 0.0
  max_bin = 31L, # lo debo dejar fijo, no participa de la BO
  num_iterations = 9999, # un numero muy grande, lo limita early_stopping_rounds
  
  bagging_fraction = 1.0, # 0.0 < bagging_fraction <= 1.0
  pos_bagging_fraction = 1.0, # 0.0 < pos_bagging_fraction <= 1.0
  neg_bagging_fraction = 1.0, # 0.0 < neg_bagging_fraction <= 1.0
  is_unbalance = FALSE, #
  scale_pos_weight = 1.0, # scale_pos_weight > 0.0
  
  drop_rate = 0.1, # 0.0 < neg_bagging_fraction <= 1.0
  max_drop = 50, # <=0 means no limit
  skip_drop = 0.5, # 0.0 <= skip_drop <= 1.0
  
  extra_trees = TRUE, # Magic Sauce
  
  seed = PARAM$lgb_semilla
)

OUTPUT <- list()

#------------------------------------------------------------------------------

options(error = function() {
  traceback(20)
  options(error = NULL)
  stop("exiting after script error")
})
#------------------------------------------------------------------------------

GrabarOutput <- function() {
  write_yaml(OUTPUT, file = "output.yml") # grabo OUTPUT
}
#------------------------------------------------------------------------------

### Aqui comienza el programa ###
OUTPUT$PARAM <- PARAM
OUTPUT$time$start <- format(Sys.time(), "%Y%m%d %H%M%S")

# cargo el dataset donde voy a entrenar
# esta en la carpeta del exp_input y siempre se llama  dataset_training.csv.gz
dataset <- fread(PARAM$input$dataset)

# creo la carpeta donde va el experimento
dir.create(PARAM$exp_folder, showWarnings = FALSE)

# Establezco el Working Directory DEL EXPERIMENTO
setwd(PARAM$exp_folder)

GrabarOutput()
write_yaml(PARAM, file = "parametros.yml") # escribo parametros utilizados

# establezco donde entreno
dataset[, train := 0L]
dataset[foto_mes %in% PARAM$input$train, train := 1L]

# elimino mas de agosto ya que el future este en 202109
dataset <- dataset[foto_mes != 202108]

# Gernero la clase binaria
dataset[, clase01 := ifelse(clase_ternaria %in% c("BAJA+2", "BAJA+1"), 1L, 0L)]

campos_buenos <-  setdiff(colnames(dataset), c("clase_ternaria", "clase01", "train"))

#ordeno primero y luego creo los LAGS de un mes para cada variable
setorderv( dataset, c("numero_de_cliente","foto_mes") )

# Se enriquece el dataset con los lags de todos los atributos. ¿Qué es el lag1 de mcaja_ahorro para 201910?, 
# es el valor que tomó  mcaja_ahorro para el mes anterior  201909; en caso que no existiera el cliente el 
# mes anterior, se asigna el valor NA . 
dataset[ , paste0( campos_buenos, "_lag1") := shift(.SD, 1, NA, "lag"), 
         by=numero_de_cliente, 
         .SDcols= campos_buenos ]

# FER v2 start
# Escalo en percentiles valores montos ya que estan afectados por meses raros (aguinaldo en diciembre por ejemplo)
camposMonto <- colnames(dataset)[like(colnames(dataset), "^m|^Visa_m|^Master_m")]

# Las creo en nuevas variables para mantener las originales para otras transformaciones
camposMonto_new <- paste0("new_cm_", camposMonto)

dataset[, (camposMonto_new) := lapply(.SD, frankv,  na.last = "keep", ties.method = "dense"), 
        by = foto_mes, .SDcols = camposMonto] # primero lo rankea

fdividir_maximo  <- function(pvector) { maximo <-  max(pvector, na.rm = TRUE); return(pvector / maximo) }

dataset[, (camposMonto_new) := lapply(.SD, fdividir_maximo), by = foto_mes, .SDcols = camposMonto_new] # segundo lo escala de 0 a 1
# FER v2 end

#a la olla todo el dataset de 34 meses, sin corregir nada
#aun con los campos rotos en algunos meses, el calor matara todos los bichos
tic()
dtrain  <- lgb.Dataset( data = data.matrix(dataset[train == 1L, campos_buenos, with = FALSE]),
                        label = dataset[train == 1L, clase01],
                        free_raw_data= TRUE )

#genero el modelo
modelo  <- lgb.train(data= dtrain,
                     objective= "binary",
                     learning_rate=     0.01, #fuego muuuy lento
                     num_iterations=    4500,
                     min_data_in_leaf=  8500,    #hojas monstruosamente grandes
                     min_gain_to_split= 0.16, #detengo el crecimiento
                     num_leaves=        4096 )   #soy muy generoso con la cantidad de hojas posibles

train_time <- toc()

COMENZO A CORRER ACA
#aplico el modelo a los datos sin clase, 201912
#para crear los lags en diciembre, necesito cargar  noviembre
#d201911  <- fread("~/buckets/b1/datasetsOri/paquete_premium_201911.txt")
#d201912  <- fread("~/buckets/b1/datasetsOri/paquete_premium_201912.txt")
#dapply   <- rbind( d201911, d201912)
d201911 <- fread(paste(kbuckets_WD, "datasets/paquete_premium_201911.txt", sep = "/"))
d201912 <- fread(paste(kbuckets_WD, "datasets/paquete_premium_201912.txt", sep = "/"))
dapply   <- rbind( d201911, d201912)

#primero ordeno
setorderv( dapply, c("numero_de_cliente","foto_mes") )
#creo el lag para diciembre
dapply[ , paste0( campos_buenos, "_lag1") := shift(.SD, 1, NA, "lag"), 
        by=numero_de_cliente, 
        .SDcols= campos_buenos ]

# FER v2 start
# Escalo en percentiles valores montos ya que estan afectados por meses raros (aguinaldo en diciembre por ejemplo)
camposMonto <- colnames(dapply)[like(colnames(dapply), "^m|^Visa_m|^Master_m")]

# Las creo en nuevas variables para mantener las originales para otras transformaciones
camposMonto_new <- paste0("new_cm_", camposMonto)
dapply[, (camposMonto_new) := lapply(.SD, frankv,  na.last = "keep", ties.method = "dense"), 
        by = foto_mes, .SDcols = camposMonto] # primero lo rankea

fdividir_maximo  <- function(pvector) { maximo <-  max(pvector, na.rm = TRUE); return(pvector / maximo) }

dapply[, (camposMonto_new) := lapply(.SD, fdividir_maximo), by = foto_mes, .SDcols = camposMonto_new] # segundo lo escala de 0 a 1
# FER v2 end

#finalmente, aplico el modelo a los datos de diciembre
prediccion_201912  <- predict( modelo,  data.matrix( dapply[ foto_mes == 201912 , -c("clase_ternaria")]))

#genero el dataset de entrega probabilidad de corte 
entrega  <- as.data.table( list( "Id"=         dapply[ foto_mes == 201912, numero_de_cliente],  
                                 "Predicted"=  (prediccion_201912 > 0.0212) ) )

#genero el archivo de salida
#fwrite( entrega, logical01=TRUE, sep=",",  file="~/buckets/b1/work/simple_lag_is_beautiful.csv")
write.csv(entrega,
          paste0(kdir_salida, kprograma, "-", kmodelo, "_salida_", "v2", ".csv"),
          row.names = FALSE)

###
# conversion de seconds to "days hh:mm:ss"
dhms = function(t) {
  paste(t %/% (60*60*24), "days",
        paste(formatC(t %/% (60*60) %% 24, width = 2, format = "d", flag = "0"),
              formatC(t %/% 60 %% 60, width = 2, format = "d", flag = "0"),
              formatC(t %% 60, width = 2, format = "d", flag = "0"),
              sep = ":"
        )
  )
}

cat("Tiempo empleado: ", dhms(train_time$toc - train_time$tic))

