library(jsonlite)
library(httr)

RKmeansClusteringClient <- function(url, token = NULL) {
    ret_client_object_ref <- list(url = url, token = token)

    ret_client_object_ref[['json_rpc_call']] <- function(method_name, param_list) {
        body_text = toJSON(
            list(
                id=1,version=unbox("1.1"),
                method=unbox(method_name),
                params=param_list
            )
        )
        resp <- POST(ret_client_object_ref[['url']],
            accept_json(),
            add_headers("Content-Type" = "application/json",
                "Authorization" = unbox(ret_client_object_ref[['token']])),
            body = body_text
        )
        parsed <- content(resp, "parsed", "application/json")
        if (resp[['status_code']] != 200) {
            error <- parsed[['error']]
            if (is.null(error)) {
                stop_for_status(resp)
            }
            message <- error[['error']]
            if (is.null(message)) {
                message <- error[['data']]
            }
            if (is.null(message)) {
                message <- error[['message']]
            }
            stop(message)
        }
        return(parsed[['result']])
    }

    ret_client_object_ref[['estimate_k']] <- function(params) {
        ret <- ret_client_object_ref[['json_rpc_call']]("RKmeansClustering.estimate_k", list(
                params
        ))
        return(ret[[1]])
    }

    ret_client_object_ref[['cluster_k_means']] <- function(params) {
        ret <- ret_client_object_ref[['json_rpc_call']]("RKmeansClustering.cluster_k_means", list(
                params
        ))
        return(ret[[1]])
    }

    class(ret_client_object_ref) <- 'RKmeansClusteringClient'
    return(ret_client_object_ref)
}
