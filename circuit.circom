pragma circom 2.0.0;
include "./node_modules/circomlib/circuits/comparators.circom";

/*
*   We assume that the given graph only has 1 and 0 values
*/
template Traveling(N,K) {

    /*
    *   The input and output connections defined as signals
    */

    signal input connections[N][N];
    signal connectionsArrat[N*N];
    signal input path[K];



    /*
    *   We check that the path contains at least N cities
    *   This is important because the path must contain all the cities
    *   16 represents the number of bits of the number of cities
    */
    component VerifySize= GreaterThan(16);
    VerifySize.in[0] <== K;
    VerifySize.in[1] <== N-1;
    VerifySize.out === 1;


    /*
    *   Check that all cities in the path exist
    */
    component VerifyLowerBound[K];
    component VerifyUpperBound[K];
    for(var i = 0; i<K;i++){
        VerifyLowerBound[i] = GreaterThan(16);
        VerifyLowerBound[i].in[0] <== path[i];
        VerifyLowerBound[i].in[1] <== -1;
        VerifyLowerBound[i].out === 1;

        VerifyUpperBound[i] = LessThan(16);
        VerifyUpperBound[i].in[0] <== path[i];
        VerifyUpperBound[i].in[1] <== N;
        VerifyUpperBound[i].out === 1;
    }


    for (var i = 0; i < N; i++) {
        for (var j = 0; j < N; j++) {
            connectionsArrat[i*N+j] <== connections[i][j];
        }
    }


    /*
    *   Check that all vertices implied by the path exist in the graph 
    */
    component eqs[K];
    component qs[K];
    for (var i = 0; i < K-1; i++) {
        eqs[i] = IsEqual();
        qs[i] = QuinSelector(N*N);
        qs[i].in <== connectionsArrat;
        qs[i].index <== (path[i]*N)+path[(i+1)];
        eqs[i].in[0] <== qs[i].out;
        eqs[i].in[1] <== 1;
        eqs[i].out === 1;
    }


    /*
    *   Check that all nodes are visited at least once
    */
    component visited[N];
    component eq2[N][K];
    component totalSums[N];
    signal hits[N][K];
    for (var i = 0; i < N; i++) {
        for (var j = 0; j < K; j++) {
            eq2[i][j] = IsEqual();
            eq2[i][j].in[0] <== path[j];
            eq2[i][j].in[1] <== i;
            hits[i][j] <== eq2[i][j].out;
        }
        totalSums[i] = CalculateTotal(K);
        totalSums[i].in <== hits[i];
        visited[i] = GreaterThan(16);
        visited[i].in[0] <== totalSums[i].out;
        visited[i].in[1] <== 0;
        visited[i].out === 1;

    }

    

}


/*
*   This function is able to return the element arr[index] when index is not known at compile time
*/

template QuinSelector(choices) {
    signal input in[choices];
    signal input index;
    signal output out;
    
    /*
    *   Make sure  that index is within range
    */ 
    component lessThan = LessThan(4);
    lessThan.in[0] <== index;
    lessThan.in[1] <== choices;
    lessThan.out === 1;


    /*
    *   Make use of this component to add all elements of form isEq(in[i], index)*in[i]
    */

    component calcTotal = CalculateTotal(choices);
    component eqs[choices];

    /*
    *   Createa the IsEqual components and add them to calcTotal
    */
    for (var i = 0; i < choices; i ++) {
        eqs[i] = IsEqual();
        eqs[i].in[0] <== i;
        eqs[i].in[1] <== index;


        calcTotal.in[i] <== eqs[i].out * in[i];
    }

    /*
    *   outputs the sum but because there can only be one element that satisfies the condition isEq(in[i], index) it will return the actaul value in[i]
    */
    out <== calcTotal.out;
}


/*
*   A really simple way of computing the sum of an array in Circom
*/

template CalculateTotal(n) {
    signal input in[n];
    signal output out;

    signal sums[n];

    sums[0] <== in[0];

    for (var i = 1; i < n; i++) {
        sums[i] <== sums[i-1] + in[i];
    }

    out <== sums[n-1];
}




component main { public [ connections ] }= Traveling(3,5);
