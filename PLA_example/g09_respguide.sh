#!/bin/bash
echo "running antechamber and generating g09 input"
antechamber -i lig.mol2 -fi mol2 -o gcrt.com -fo gcrt -gv 1 -ge lig.gesp -at gaff2
sed -i 's/HF/B3LYP/g' gcrt.com # Using B3LYP for the single point energy calculation
sed -i '/Link1/D' gcrt.com
fit='iop(6/50=1)'
sed -i "s#opt#$fit#g" gcrt.com
sed -i '/# iop/D' gcrt.com && sed -i '/remark line/D' gcrt.com
sed -i '/lig.gesp/D' gcrt.com
echo > lig_g09inp.com
printf "%s\n" "%NProcShared=4" "%LindaWorkers=4" "%Mem=5GB" >> lig_g09inp.com # change NProcShared/LindaWorkers to your mpirun number
cat gcrt.com >> lig_g09inp.com
if [[ -f lig_g09inp.com ]]; then
    echo "gaussian input generate, running the program..."
    mpirun -np 4 g09 lig_g09inp.com # run gaussian with 4 multiprocessors - this can be removed if multiprocessors are not available, or increased

else
    echo "gaussian input wasn't created, exiting"
    exit 1
fi

if $(grep -q "Normal termination" lig_g09inp.log); then
    echo "gaussian run successfully"
    echo "generating the lig_resp"
    chg_prior_beg=$(grep -n "Charges from ESP fit," lig_g09inp.log | cut -d: -f1)
    chg_beg=$(($chg_prior_beg + 2))
    chg_prior_end=$(grep -n "Charges from ESP fit with" lig_g09inp.log | cut -d: -f1)
    chg_end=$(($chg_prior_end - 1 ))
    echo $chg_beg $chg_end

    awk -v start=$chg_beg -v end=$chg_end 'NR>=start && NR<=end {
        print $3}' lig_g09inp.log > charges.tmp

    start=$(grep -n "@<TRIPOS>ATOM" lig.mol2 | cut -d: -f1)
    echo $start
    end=$(grep -n "@<TRIPOS>BOND" lig.mol2 | cut -d: -f1)
    echo $end

    echo "the prints within the while print to the final output, not console"
    awk -v start=$start -v end=$end -v charges_file=charges.tmp '
    NR==FNR { charges[NR] = $1; next }
    FNR >= start && FNR < end {
        while ($0 ~/LIG/) {
            OLDNUM=$NF
            NEWNUM=charges[FNR-start+1]
            sub(OLDNUM, NEWNUM, $NF);
            printf "%7d %-4s %10.4f %10.4f %10.4f %-5s %3d %-5s %10.6f\n",
            $1, $2, $3, $4, $5, $6, $7, $8, $9;
            getline;
        }
        }
    1
    ' charges.tmp lig.mol2 > lig_resp.mol2

    sed -i 's/bcc/resp/g' lig_resp.mol2

    if [[ -f lig_resp.mol2 ]]; then
        echo "lig_resp molecule successfully made"
        echo "resp run completed successfully"
        grep "LIG" lig_resp.mol2
    else
        echo "can't find lig_resp file , perhaps an error occurred"
    fi
else
    echo "the gaussian run did not complete succesfully"
fi
