# Polynya_EGU_TC
Codes to reproduce the results of Heuzé and Lemos (subm 2020), under revision for The Cryosphere 

To reproduce appendix A (cloud mask validation), use in this order:
1- readmodis.py then cloud_from_MYD35.m on already downloaded MYD35_L2 data;
2- cloud_from_APP.m on already downloaded APP data;
3- comparecloudmasks.m on the output generated by steps 1 and 2.
