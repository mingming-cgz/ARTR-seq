#!/usr/bin/env bash

date
echo "Step 3 calling peaks with macs 3"
printf "\n"

######

peakdir="Your/directory/for/the/output/peak/file"
printf "Your directory for the output peak file %s\n" "${peakdir}"

# change genomeForMacs3 if data is not from human. Follow the macs3 manual
genomeForMacs3="hs"
printf "Your genome setting for macs3 -- %s\n" ${genomeForMacs3}

# Enter your IP fwd.bam, seperate by " "
fwdIPbams=("stardir1/IP.fwd.bam")
# fwdIPbams=("stardir1/IP.fwd.bam" "stardir2/IP.fwd.bam" "stardir3/IP.fwd.bam")
# Enter your input fwd.bam, seperate by " "
fwdinputbams=("stardir4/input.fwd.bam" "stardir5/input.fwd.bam" "stardir6/input.fwd.bam" "stardir7/input.fwd.bam")

revIPbams=()
for (( i=0; i<${#fwdIPbams[@]}; i++ )); do
	revIPbams[$i]=${fwdIPbams[$i]/.fwd.bam/.rev.bam}
done

revinputbams=()
for (( i=0; i<${#fwdinputbams[@]}; i++ )); do
	revinputbams[$i]=${fwdinputbams[$i]/.fwd.bam/.rev.bam}
done


#######
outdir="$(awk -F/ '{print $(NF-1)}' <<< ${fwdIPbams[0]})"

printf "Forward strand -- \nIP bams -- %s\ninput bams -- %s\nodir -- %s\n\n" "${fwdIPbams[*]}" "${fwdinputbams[*]}" ${outdir}
macs3 callpeak --treatment ${fwdIPbams[@]}\
       	--control ${fwdinputbams[@]} \
	-f BAM -n $outdir.fwd -g ${genomeForMacs3} -B \
	--keep-dup all \
	--outdir $peakdir/$outdir \
	--tempdir $peakdir/$outdir \
	--nomodel --extsize 30

printf "Reverse strand -- \nIP bams -- %s\ninput bams -- %s\nodir -- %s\n" "${revIPbams[*]}" "${revinputbams[*]}" ${outdir}
macs3 callpeak --treatment ${revIPbams[@]}\
       	--control ${revinputbams[@]} \
	-f BAM -n $outdir.rev -g ${genomeForMacs3} -B \
	--keep-dup all \
	--outdir $peakdir/$outdir \
	--tempdir $peakdir/$outdir \
	--nomodel --extsize 30

#####
outpeak=$peakdir/peak."${outdir}".narrowpeak.bed
cat $peakdir/$outdir/*peaks.narrowPeak | awk 'BEGIN{FS="\t";OFS="\t"} {if ($4 ~ /fwd/) {$6 = "+"} else {$6 = "-"}; print $0 }' > $o;

printf "Call peaks for %s\n" ${fwdIPbams[*]}
date
echo "Finished!"
###








