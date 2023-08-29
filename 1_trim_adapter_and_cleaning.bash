#!/usr/bin/env bash

date
echo "Step 1 trimming adapters and filtering reads mapped to rRNA"

###

##
# note of paired-end reads
# TRUE -- paired-end reads
# FALSE -- single-end reads
pair=FALSE

# the filename of your R1.fq.gz
inrawR1="YourInputRawFileR1.fq.gz"

if [ "${pair}" == FALSE ]; then
	echo "Single-end"
	inrawR2=""
else
	echo "Paired-end"
	inrawR2=${inrawR1/R1/R2}
fi
printf "Your Read 1 fq.gz -- %s, Read 2 fq.gz -- %s\n" $inrawR1 $inrawR2

rawfiledir="Your/RawFile/directory"
printf "Your directory containing the raw fq.gz -- %s\n" $rawfiledir

outfdir="Your/output/fq.gzfile/directory"
printf "Your directory containing the output files fq.gz -- %s\n" $outfdir

nc=16
printf "Your core number used for cutadapt and bowtie2 -- %s\n" $nc

bt2idx="your/bowtie2/index/directory"
printf "Your bowtie2 index directory -- %s\n" $bt2idx


###
startt="$(date +%s)"

###
echo "1 Trimming adapters with cutadapt"
if [ "${pair}" == FALSE ]; then
	#echo "Single-end"
	
	t1=${outfdir}/trim1.${inrawR1}
	log1=${t1/R1/}
	log1=${log1/.fq.gz/.log}
	
	t2=${t1/trim1/trim}
	log=${log1/trim1/trim}
	
	echo $inrawR1
	
	echo "1.1 trimming the adapter"
	echo $t1 $log1
	
	# trimming the 3'-adapter
	cutadapt -j ${nc} --nextseq-trim=20 --action=trim \
		-a AGATCGGAAGAGCACACGTCTGAACTCCAG \
		-o $t1 $rawfiledir/$inrawR1 > $log1
			
	echo "1.2 extracting the umi"
	echo $t2 $log
	
	cutadapt -j ${nc} -q 20 -m 20 --action=trim \
		-u 8 -u -4 \
		--rename='{id}_{cut_prefix} {comment}' \
		-o $t2 $t1 > $log

else
	#echo "Paired-end"
	
	t11=${outfdir}/trim1.${inrawR1}
	t12=${t11/R1/R2}
	
	log1=${t11/-R1/}
	log1=${log1/.fq.gz/.log}

	t21=${t11/trim1/trim}
	t22=${t12/trim1/trim}
	log=${log1/trim1/trim}
	
	echo $inrawR1 $inrawR2

	echo "1.1 trimming the adapter"
	echo $t11 $t12 $log1

	cutadapt -j ${nc} --nextseq-trim=20 --action=trim \
		-a AGATCGGAAGAGCACACGTCTGAACTCCAG \
		-A AGATCGGAAGAGCGTCGTGTAGGGAAAGAG \
		-o $t11 -p $t12 $rawfiledir/$inrawR1 $rawfiledir/$inrawR2 > $log1

                
	echo "1.2 extracting the umi"
	echo $t21 $t22 $log

	cutadapt -j ${nc} -q 20 -m 20 --action=trim \
		-u 8 -u -4 -U -8 -U 4 \
		--rename='{id}_{r1.cut_prefix} {comment}' \
		-o $t21 -p $t22 $t11 $t12 > $log
	
fi
endt="$(date +%s)"
printf "Trimming adapters for %s done, elapsed time -- %.0f s\n\n" $inrawR1 "$((( $endt - $startt)))"

#
echo "2 discarding reads mapped to rRNA with bowtie2"
startt2="$(date +%s)"
if [ "$pair" = FALSE ]; then
	#echo "Single-end";

	bw2o=${t2/trim./norRNA.}
	filetag=$t2
	
	echo $t2 $bw2o
	bowtie2 --threads ${nc} --seedlen=15 -x $bt2idx \
		-U $i --un-gz $bw2o > /dev/null
	

else
        #echo "Paired-end";

	bw2o=${t21/trim./norRNA.}
	bw2o=${o/R1/R%}
	filetag=$t21

	echo $t21 $t22 $bw2o
	bowtie2 --threads ${nc} --seedlen=15 -x $bt2idx \
		-1 $t21 -2 $t22 --un-conc-gz $bw2o > /dev/null

fi

endt="$(date +%s)"
printf "Filtering rRNA for %s done, elapsed time -- %.2f min \n\n" $filetag "$((($endt - $startt2) / 60))"



#
date
endt="$(date +%s)"
printf "Total elapsed time -- %.2f min \n\n" "$((($endt - $startt) / 60))"
echo "Finish!"

#####
