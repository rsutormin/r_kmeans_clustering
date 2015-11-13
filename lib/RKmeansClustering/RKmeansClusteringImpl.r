#BEGIN_HEADER
library(jsonlite)
library(fpc)
#END_HEADER

methods <- list()

#BEGIN_CONSTRUCTOR
source("./lib/Workspace/WorkspaceClient.r")

get_ws_client <- function(context) {
    token <- context[['token']]
    ws_url <- context[['config']][['workspace-url']]
    ret <- WorkspaceClient(ws_url, token=token, simplifyVector = TRUE, simplifyMatrix = TRUE)
    return(ret)
}

mean_m = function(vec){
    vec[as.vector(is.nan(vec))] <- NA
    n <- sum(!is.na(vec))
    summ <- sum(vec,na.rm=TRUE)
    summ/n
}

naToNaN = function(x) {
    x[is.na(x)] <- NaN
    return(x)
}

calc_cluster_props = function(logratios_median, cluster, ret) {
    ###mean pairwise correlation
    meancor <- c()
    for(i in 1:max(cluster)) {
        clust_ind <- which(cluster == i)
        if (length(clust_ind) == 1) {
            meancor <- c(meancor, NA)
        } else {
            cors <- cor(t(logratios_median[clust_ind,]), use="pairwise.complete.obs",method="pearson")
            AbCorC <- mean(cors[lower.tri(cors, diag=FALSE)])
            meancor <- c(meancor, AbCorC)
        }
    }
    #print(meancor)
    meancor <- naToNaN(meancor)

    ###MSEC
    MSECs <- c()
    for(i in 1:max(cluster)) {
        clust_ind <- which(cluster == i)
        if (length(clust_ind) == 1) {
            MSECs <- c(MSECs, NA)
        } else {
            curdata <- logratios_median[clust_ind,]
            MSEall <- mean_m((curdata-mean_m(curdata))^2)
            cmeans <- colMeans(curdata,na.rm=TRUE)
            csds <- apply(curdata,2,sd,na.rm=TRUE)
            MSEC <- mean_m((sweep(curdata,2,cmeans))^2/MSEall)
            MSECs <- c(MSECs, MSEC)
        }
    }
    #print(MSECs)
    MSECs <- naToNaN(MSECs)

    ret[["meancor"]] <- meancor
    ret[["msecs"]] <- MSECs
    return(ret)
}
#END_CONSTRUCTOR

methods[["RKmeansClustering.estimate_k"]] <- function(params, context) {
    #BEGIN estimate_k
    matrix_ref <- params[['input_matrix']]
    min_k <- params[['min_k']] 
    max_k <- params[['max_k']]
    crit <- params[['criterion']]
    usepam <- params[['usepam']]
    alpha <- params[['alpha']]
    diss <- params[['diss']]
    random_seed <- params[['random_seed']]
    out_workspace <- params[['out_workspace']]
    out_estimate_result <- params[['out_estimate_result']]
    object_identity <- list(ref=unbox(matrix_ref))
    ws_client <- get_ws_client(context)
    object_data <- ws_client$get_objects(list(object_identity))[[1]]
    expr_matrix_obj <- object_data[['data']]
    matrix <- expr_matrix_obj[['data']]
    if (!is.null(random_seed))
        set.seed(random_seed)
    if (is.null(min_k))
        min_k <- 2
    if (is.null(max_k))
        max_k <- 200
    if (is.null(crit))
        crit <- "asw"
    if (is.null(usepam))
        usepam <- FALSE
    values <- matrix[["values"]]
    #row_names <- matrix[["row_ids"]]
    row_names <- c(1:length(matrix[["row_ids"]]))-1
    row.names(values) <- row_names
    values <- data.matrix(values)
    max_clust_num = min(c(max_k,nrow(values)-1))
    pk<- pamk(values,krange=c(min_k:max_clust_num),criterion=crit,
        usepam=usepam,ns=10)
    ret_names <- c(min_k:max_clust_num)
    best_pos <- pk$nc
    cluster_count_qualities <- list()
    for (pos in 1:length(ret_names)) {
        cluster_count = unbox(ret_names[pos])
        quality <- unbox(pk$crit[cluster_count])
        cluster_count_qualities <- rbind(cluster_count_qualities, list(cluster_count, quality))
    }
    obj <- list(best_k=unbox(as.numeric(best_pos)), estimate_cluster_sizes=cluster_count_qualities)
    prov_act <- list(service=unbox("RKmeansClustering"),method=unbox("estimate_k"),
        service_ver=unbox("0.1"), input_ws_objects=list(unbox(matrix_ref)), 
        description=unbox("K estimation for K-Means clustering method"), method_params=list(params))
    prov <- list(prov_act)
    info <- ws_client$save_objects(list(workspace=unbox(out_workspace), objects=list(list(
        type=unbox('KBaseFeatureValues.EstimateKResult'), name=unbox(out_estimate_result),
        data=obj, provenance=prov))))[[1]]
    ret <- paste(info[[7]],info[[1]],info[[5]],sep="/")
    return(unbox(ret))
    #END estimate_k
}

methods[["RKmeansClustering.cluster_k_means"]] <- function(params, context) {
    #BEGIN cluster_k_means
    k <- params$k
    matrix_ref <- params$input_data
    n_start <- params$n_start
    max_iter <- params$max_iter
    random_seed <- params$random_seed
    algorithm_name <- params$algorithm
    out_workspace <- params$out_workspace
    out_clusterset_id <- params$out_clusterset_id
    object_identity <- list(ref=unbox(matrix_ref))
    ws_client <- get_ws_client(context)
    object_data <- ws_client$get_objects(list(object_identity))[[1]]
    expr_matrix_obj <- object_data[['data']]
    matrix <- expr_matrix_obj[['data']]
    if (is.null(n_start))
        n_start <- 1000
    if (is.null(max_iter))
        max_iter <- 1000
    if (is.null(algorithm_name))
        algorithm_name <- "Lloyd"
    values <- matrix[["values"]]
    row_ids <- matrix[["row_ids"]]
    row_names <- c(1:length(row_ids))-1
    row.names(values) <- row_names
    values <- data.matrix(values)
    #col_ids <- matrix[["col_ids"]]
    if (!is.null(random_seed))
        set.seed(random_seed)
    km <- kmeans(values, k, iter.max = max_iter, nstart=n_start, algorithm=algorithm_name)
    clusters <- calc_cluster_props(values, km[["cluster"]], list(cluster_labels=km[["cluster"]]))
    out_list <- list()
    for (i in 1:max(clusters$cluster_labels)) {
        clust_ind <- which(clusters$cluster_labels == i)
        id_to_pos <- list()
        for (j in clust_ind) {
            row_id <- row_ids[j]
            id_to_pos[[row_id]] <- unbox(j - 1)
        }
        out_clust <- list(id_to_pos=id_to_pos)
        out_clust[['meancor']] <- unbox(clusters$meancor[[i]])
        out_clust[['msec']] <- unbox(clusters$msecs[[i]])
        out_list[[i]] <- out_clust
    }
    obj <- list(original_data=unbox(matrix_ref), feature_clusters=out_list)
    prov_act <- list(service=unbox("RKmeansClustering"),method=unbox("cluster_k_means"),
        service_ver=unbox("0.1"), input_ws_objects=list(unbox(matrix_ref)), 
        description=unbox("K-Means clustering method"), method_params=list(params))
    prov <- list(prov_act)
    info <- ws_client$save_objects(list(workspace=unbox(out_workspace), objects=list(list(
        type=unbox('KBaseFeatureValues.FeatureClusters'), name=unbox(out_clusterset_id), 
        data=obj, provenance=prov))))[[1]]
    ret <- paste(info[[7]],info[[1]],info[[5]],sep="/")
    return(unbox(ret))
    #END cluster_k_means
}
