#!/usr/bin/env bash

date
echo "Getting the motif using Homer2"

#####
oripeak="Your/narrowpeak.bed/file"
printf "Your narrowpeak.bed file -- %s\n" $oripeak

motifdir="Your/motif/directory"
printf "Your directory for the homer2 output files"

annoforHomer2="Your/annotation/bed12"
printf "Your annotation bed12 file for Homer2 %s \n" ${annoforHomer2}

# set this variable if your data is not from human
genomeHomer2="hg38"
printf "Your homer2 genome tag -- %s\n" ${genomeHomer2}

nc=16
printf "Core number for homer2 -- %s\n" ${nc}
######

extpeak="$(awk -F/ '{print $NF}' <<< ${oripeak})"
odir=${extpeak}

extpeak="${extpeak/peak./ext.}"

awk -v wid=20 'BEGIN{FS="\t"; OFS="\t"}; {$2=$2-wid; $3=$3+wid; print $0}' $oripeak > $motifdir/$extpeak
odir=${odir/.narrowpeak*/}

cd $motifdir
pwd

if [ ! -d "${odir}" ]; then
	echo "NO, mkdir" ${odir}
	mkdir ${odir};
else
	echo "YES"
fi

findMotifsGenome.pl $extpeak ${genomeHomer2} $odir/ -p ${nc} -rna -S 10 -len 5,6,7,8,9 \
	-bg ${annoforHomer2}
#####
date
echo "Finish!'
