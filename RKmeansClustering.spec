/*
A KBase module: RKmeansClustering
*/

module RKmeansClustering {

    /*
        Indicates true or false values, false = 0, true = 1
        @range [0,1]
    */
    typedef int boolean;

    /*
        A workspace ID that references a Float2DMatrix wrapper data object.
        @id ws KBaseFeatureValues.ExpressionMatrix KBaseFeatureValues.SingleKnockoutFitnessMatrix
    */
    typedef string ws_matrix_id;

    /*
        The workspace ID of a FeatureClusters data object.
        @id ws KBaseFeatureValues.EstimateKResult
    */
    typedef string ws_estimatekresult_id;

    /*
        The workspace ID of a FeatureClusters data object.
        @id ws KBaseFeatureValues.FeatureClusters
    */
    typedef string ws_featureclusters_id;

    /*
        Output object will have type KBaseFeatureValues.EstimateKResult
    */
    typedef structure {
        ws_matrix_id input_matrix;
        int min_k;
        int max_k;
        string criterion;
        boolean usepam;
        float alpha;
        boolean diss;
        int random_seed;
        string out_workspace;
        string out_estimate_result;
    } EstimateKParams;

    /*
        Used as an analysis step before generating clusters using K-means clustering,
        this method provides an estimate of K by [...]
    */
    funcdef estimate_k(EstimateKParams params)
        returns (ws_estimatekresult_id output_ref) authentication required;

    /*
        Output object will have type KBaseFeatureValues.FeatureClusters
    */
    typedef structure {
        int k;
        ws_matrix_id input_data;
        int n_start;
        int max_iter;
        int random_seed;
        string algorithm;
        string out_workspace;
        string out_clusterset_id;
    } ClusterKMeansParams;

    /*
        Clusters features by K-means clustering.
    */
    funcdef cluster_k_means(ClusterKMeansParams params)
        returns (ws_featureclusters_id output_ref) authentication required;

};