#!/usr/bin/env bash
date
echo "Step 2 mapping reads to a genome, and deduplicate with umi-tools, and spliting bams by strand"

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

indir="Your/input/fq.gzfile/directory"
printf "Your directory containing the fq.gz after step1 -- %s\n" $indir

stardir="Your/output/bamfile/directory"
printf "Your directory containing the output bam -- %s\n" $outfdir

staridx="Your/STAR/index/directory"
printf "Your STAR index directory -- %s\n" $staridx

nc=16
printf "Your core number used for STAR -- %s\n" $nc
##

##
startt="$(date +%s)"
echo "3 mapping reads to a genome with STAR"

odir=${inrawR1/.*norRNA./}
odir=${odir/.fq*/}
odir=${odir/R1/}
odir=${stardir}/${odir}

        
if [ ! -d $odir ];then
	echo "NO, mkdir" $odir
	mkdir $odir
else
	echo "YES"
fi
echo $inrawR1 $odir

if [ "$pair" == FALSE ]; then
	inf=${$inrawR1}
else
	inf="${$inrawR1} ${$inrawR2}"
fi

STAR --runMode alignReads --runThreadN ${nc} \
	--readFilesCommand zcat \
	--genomeDir $staridx \
	--alignEndsType EndToEnd \
	--genomeLoad NoSharedMemory \
	--quantMode TranscriptomeSAM \
	--alignMatesGapMax 15000 \
	--readFilesIn ${inf} \
	--outFileNamePrefix $odir/ \
	--outFilterMultimapNmax 1 \
	--outSAMattributes All \
	--outSAMtype BAM SortedByCoordinate \
	--outFilterType BySJout \
	--outReadsUnmapped Fastx \
	--outFilterScoreMin 10 \
	--outFilterMatchNmin 24

samtools index -@ ${nc} ./$odir/Aligned.sortedByCoord.out.bam
endt="$(date +%s)"
printf "Mapping reads to a genome for %s done, elapsed time -- %.0f s\n\n" $inrawR1 "$((( $endt - $startt)))"
printf "\n"

##
startt2="$(date +%s)"
echo "4 deduplicating reads with umi-tools"
umi_tools dedup --method unique\
	-I ./$odir/Aligned.sortedByCoord.out.bam \
	--output-stats=./$odir/dedup \
	-L ./$odir/umitools.log --temp-dir=./$odir \
	-S ./$odir/dedup.bam

samtools index -@ ${nc} ./$odir/dedup.bam
endt="$(date +%s)"
printf "Deduplicating for %s done, elapsed time -- %.0f s\n\n" $inrawR1 "$((( $endt - $startt2)))"

##
startt3="$(date +%s)"
echo "5 splitting reads by strand"
ofwd=./$odir/dedup.fwd.bam
orev=${ofwd/.fwd.bam/rev.bam}
curinbam=./$odir/dedup.bam
echo ${curinbam}

echo $ofwd
samtools view -@ ${nc} -F 16 ${curinbam} -b -o $ofwd &&
	samtools index -@ ${nc} $ofwd;

echo $orev
samtools view -@ ${nc} -f 16 ${curinbam} -b -o $orev &&
	samtools index -@ ${nc} $orev
endt="$(date +%s)"
printf "Splitting reads for %s done, elapsed time -- %.0f s\n\n" $curinbam "$((( $endt - $startt2)))"

##
date
endt="$(date +%s)"
printf "Total elapsed time -- %.2f min \n\n" "$((($endt - $startt) / 60))"
echo "Finish!"
######
















