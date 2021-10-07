# README for [Alvarez, Benguria, Engbom, and Moser (2018)](https://www.aeaweb.org/articles?id=10.1257/mac.20150355)


## Guide to Files

The RAIS and PIA datasets are confidential and therefore not uploaded as part of the files. The code to replicate all results has been included in the following files:

1. **[0_MASTER.do](0_MASTER.do)**: This is the master file. All other files should be executed from this file with the appropriate switches (currently set).
2. **[MINCER.do](MINCER.do)**: Runs mincer regressions.
3. **[AKM.do](AKM.do)**: This file prepares the data, and calls MATLAB to perform the main AKM estimation.
4. **[AKM.m](AKM.m)**: Performs the AKM estimation.
5. **[AKM2.m](AKM2.m)**: Outsheets all estimated firm and worker fixed effects for subsequent analysis.
6. **[POSTESTIMATION.do](POSTESTIMATION.do)**: Computes variance decompositions of AKM results.
7. **[SUMMARYSTATS.do](SUMMARYSTATS.do)**: Reports summary stats for all workers in the sample, the connected set, and workers in PIA.
8. **[SECONDSTAGE_FIRMS.do](SECONDSTAGE_FIRMS.do)**: Runs second stage regressions of firm effects on firm characteristics.
9. **[SECONDSTAGE_WORKER.do](SECONDSTAGE_WORKER.do)**: Runs second stage regressions of worker effects on worker characteristics.
10. **[WAGEGAINS_SWITCHERS.do](WAGEGAINS_SWITCHERS.do)**: Computes wage gains from workers who switch firms by firm effect quartile.
11. **[GRAPHS_ABEM2016_residualplot.m](GRAPHS_ABEM2016_residualplot.m)**: Produces 3d graph of residuals.


## References

[Alvarez, Jorge and Felipe Benguria and Niklas Engbom and Christian Moser. 2018. "Firms and the Decline in Earnings Inequality in Brazil." American Economic Journal: Macroeconomics, 2018, 10(1): 149-189.](https://www.aeaweb.org/articles?id=10.1257/mac.20150355)
