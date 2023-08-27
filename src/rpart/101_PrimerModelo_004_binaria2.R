################################################################################
################################################################################

#ENV = "GCP"
ENV = "MAC"

LABO_PROJ_WD   = setwd("..")
if(ENV == "MAC") {
  LABO_BUCKET_WD = paste0(LABO_PROJ_WD, "/buckets")
} else {
  LABO_BUCKET_WD = paste0("~/buckets/b1/")
}
LABO_DATA_WD   = paste0(LABO_BUCKET_WD, "/datasets")
LABO_EXP_WD    = paste0(LABO_BUCKET_WD, "/exp")

MIS_SEMILLAS = c(591067, 157991, 689987, 136999, 366467)

################################################################################
################################################################################


# Arbol elemental con libreria  rpart
# Debe tener instaladas las librerias  data.table  ,  rpart  y  rpart.plot

# cargo las librerias que necesito
require("data.table")
require("rpart")
require("rpart.plot")

# Aqui se debe poner la carpeta de la materia de SU computadora local
#setwd("~/buckets/b1/") # Establezco el Working Directory
setwd(LABO_PROJ_WD) # Establezco el Working Directory

# cargo el dataset
#dataset <- fread("./datasets/dataset_pequeno.csv")
dataset <- fread( paste0(LABO_DATA_WD, "/dataset_pequeno.csv") )

dtrain <- dataset[foto_mes == 202107] # defino donde voy a entrenar
dapply <- dataset[foto_mes == 202109] # defino donde voy a aplicar el modelo

# genero el modelo,  aqui se construye el arbol
# quiero predecir clase_ternaria a partir de el resto de las variables
modelo <- rpart(
        formula = "clase_ternaria ~ .",
        data = dtrain, # los datos donde voy a entrenar
        xval = 0,
        cp = -0.005, # esto significa no limitar la complejidad de los splits
        minsplit = 50, # minima cantidad de registros para que se haga el split
        minbucket = 8, # tamaño minimo de una hoja
        maxdepth = 8
) # profundidad maxima del arbol


# grafico el arbol
prp(modelo,
        extra = 101, digits = -5,
        branch = 1, type = 4, varlen = 0, faclen = 0
)


# aplico el modelo a los datos nuevos
prediccion <- predict(
        object = modelo,
        newdata = dapply,
        type = "prob"
)

# prediccion es una matriz con TRES columnas,
# llamadas "BAJA+1", "BAJA+2"  y "CONTINUA"
# cada columna es el vector de probabilidades

# agrego a dapply una columna nueva que es la probabilidad de BAJA+2
dapply[, prob_baja2 := prediccion[, "BAJA+2"]]

# solo le envio estimulo a los registros
#  con probabilidad de BAJA+2 mayor  a  1/40
dapply[, Predicted := as.numeric(prob_baja2 > 1 / 40)]

# genero el archivo para Kaggle
# primero creo la carpeta donde va el experimento
#dir.create("./exp/")
#dir.create("./exp/KA2001")
dir.create(paste0(LABO_EXP_WD, "/KA2001"))

# solo los campos para Kaggle
fwrite(dapply[, list(numero_de_cliente, Predicted)],
        #file = "./exp/KA2001/K101_002.csv",
        file = paste0(LABO_EXP_WD, "/KA2001/K101_003_GS_1.csv"),
        sep = ","
)

