# RESP Charge Generation for Ligand in Gaussian 09 Rev B.01

The failure of Gaussion 09 B.01 for generating RESP/partial charges for ligands following MD simulation ligand parameterization with Amber is
well documented. There exists several online scripts that purport to overcome this issue; however, these solutions failed to work in my testing.
In addition, I wanted to create an automatic and modular script with implementation into MD workflows. 

Here, I have automated the process of RESP charge generation that involves only a .mol2 file as input (lig.mol2). It requires Amber/AmberTools installed, 
as antechamber is first run to generate a Gaussian input file. The charge fields in the initial .mol2 file are not important for the process to
complete; the input is used for ligand structure input into Gaussian, as well as providing a template for the scripts latter functions: extracting
the generated charges and writing them into a new .mol2 file in the charge fields (lig_resp.mol2). 

This work is a branch of my larger autmoated simulation protocol which can be found in the Auto_Amber repository; this script ought to function
with adequate response on its own and work on a variety of ligands. One may wish to modify the specific Gaussian parameterization for ligand charges, 
if necessary. By default, a B3LYP/6-31G* single point energy run is performed. As we are only concerned with the specific charges, this shoud be sufficient. 
Finally, the script utilizes mpi with mpirun and creates a Gaussian input file with processor specifications. If mpirun is not wished to be performed, 
changing these values to 1 should overwrite any calls to multiprocessing. 
