I. DESCRIPTION
--------------
This repository contains the scripts and data files relating to the numerical section of the paper "Economies of Scope for Electricity Storage and Variable Renewables" by Gonçalo Terça and David Wozabal.

COPYRIGHT: Gonçalo Terça and David Wozabal, 05/2020.

II. REQUIREMENTS
----------------
The case studies are coded in MATLAB and require a basic MATLAB installation and optimization toolbox (alternatively any other linear programming solver), and the YALMIP package to freely available at
https://yalmip.github.io/download/
The installation directory of YALMIP has to be added to the MATLAB path.


III. CONTENTS
-------------

CASE STUDY 1: Bidding on the spot market (in Folder ...)
 
The first cass study considers the optimal bidding of a storage unit on the German spot market for electricity as described in Section 5 of the paper. The main script for this exercise is the file "id_Exo1.m".

The results of the exercise are summarized in the file "id_Exo1_results.mat".

CASE STUDY 2: The second case study considers a suboptimal non-anticipative strategy of operating a storage unit on the German secondary control reserve (SCR) market as described in section 5 of the paper.
The main script for this exercise is the file "srl_Exo1.m", which can be run with no preceding additional actions.

Additionally, the computation of the SCR energy cut-off prices is performed in the file "moecp.m". This script also selects the 1% quantile of the energy price distribution of all auctions, which is used as the trading strqategy in "srl_Exo1.m".
