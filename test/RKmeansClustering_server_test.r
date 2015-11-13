library(raster)
library(jsonlite)
library(testthat)

token <- NULL
config <- NULL
ws_client <- NULL
ws_name <- NULL
context <- NULL

get_token <- function() {
    if (is.null(token)) {
        token <<- Sys.getenv("KB_AUTH_TOKEN")
    }
    return(token)
}

get_config <- function() {
    if (is.null(config)) {
        config_file <- Sys.getenv("KB_DEPLOYMENT_CONFIG")
        config <<- readIniFile(config_file, aslist=TRUE)[['RKmeansClustering']]
    }
    return(config)
}

get_context <- function() {
    if (is.null(context)) {
        context <<- list(token=get_token(), config=get_config())
    }
    return(context)
}

get_test_ws_client <- function() {
    if (is.null(ws_client)) {
        ws_url <- get_config()[['workspace-url']]
        ws_client <<- WorkspaceClient(ws_url, token=get_token())
    }
    return(ws_client)
}

get_ws_name <- function() {
    if (is.null(ws_name)) {
        suffix <- round(as.numeric(Sys.time()) * 1000)
        ws_name_loc <- paste("test_RKmeansClustering_",as.character(suffix),sep="")
        tryCatch({
            get_test_ws_client()[['create_workspace']](list(workspace=unbox(ws_name_loc)))
        }, error = function(err) {
            print(paste("WARNING: ", err))
        })
        ws_name <<- ws_name_loc
    }
    return(ws_name)
}

cleanup <- function() {
    if (!is.null(ws_name)) {
        tryCatch({
            get_test_ws_client()[['delete_workspace']](list(workspace=unbox(ws_name)))
            ws_name <<- NULL
            print("Test workspace was deleted")
        }, warning = function(war) {
            print(paste("WARNING: ", war))
        }, error = function(err) {
            print(paste("ERROR: ", err))
        }, finally = {
        })
    }
}

source("./lib/RKmeansClustering/RKmeansClusteringImpl.r")
tryCatch({
    ws <- get_test_ws_client()
    obj_name <- "expr_matrix.1"
    row_ids <- c("g1", "g2", "g3", "g4", "g5", "g6", "g7")
    values <- list(
        c(13.0, 2.0, 3.0),
        c(10.9, 1.95, 2.9),
        c(2.45, 13.4, 4.4),
        c(2.5, 11.5, 3.55),
        c(-1.05, -2.0, -14.0),
        c(-1.2, -2.25, -13.2),
        c(-1.1, -2.1, -15.15)
    )
    two_dim_matrix <- list(values=values, row_ids=row_ids, col_ids=c("c1", "c2", "c3"))
    obj <- list(data=two_dim_matrix, type=unbox("log-ration"), scale=unbox("1.0"))
    ws$save_objects(list(workspace=unbox(get_ws_name()), objects=list(list(
                type=unbox('KBaseFeatureValues.ExpressionMatrix'), name=unbox(obj_name), data=obj))))
    input_ref <- paste(get_ws_name(),obj_name,sep="/")
    estimate_obj_name <- "estimate.1"
    estimate_params <- list(random_seed=unbox(123), input_matrix=unbox(input_ref),
            out_workspace=unbox(get_ws_name()), out_estimate_result=unbox(estimate_obj_name))
    estimate_ref <- methods$RKmeansClustering.estimate_k(estimate_params, get_context())
    estimate_obj <- ws$get_objects(list(list(ref=estimate_ref)))[[1]][['data']]
    expect_equal(as.numeric(estimate_obj$best_k), 3)
    clusters_obj_name <- "clisters.1"
    kmeans_params <- list(k=unbox(3), input_data=unbox(input_ref),
            out_workspace=unbox(get_ws_name()), out_clusterset_id=unbox(clusters_obj_name))
    clust_ref <- methods$RKmeansClustering.cluster_k_means(kmeans_params, get_context())
    clusters <- ws$get_objects(list(list(ref=clust_ref)))[[1]][['data']][['feature_clusters']]
    expect_equal(length(clusters), 3)
}, finally = {
    cleanup()
})
