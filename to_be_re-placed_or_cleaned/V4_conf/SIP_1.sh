source activate /data/tools/miniconda3/envs/ncov-qc/
for run in /data/encrypted/inbox/22*/
do

	# setup directory structure to avoid duplicate reads in intermediate folder as artic needs a 2 directory distance for reads of the same name
	runname=`echo $run | rev| cut -d'/' -f2 | rev`
	ggcname=`grep "RunName" $run/*.csv | cut -d',' -f2 | sed "s/ /_/g"`
	mv $run/Analysis/1/Data/fastq /data/encrypted/workingdir/scratch/
	workingdir="/data/encrypted/workingdir/scratch/fastq/"
	outdir=`echo "/data/encrypted/results/"$runname"/"`
	mkdir $outdir
	cd $workingdir

	# artic profile for our protocol (previously known as profile 6) /data/tools/ncov2019-artic-nf/conf/illumina.config
	# activate nextflow environment using source
	# run artic pipeline
	conda activate /data/tools/miniconda3/envs/nextflow/
	/usr/bin/time -o $runname.stats.txt nextflow run /data/tools/ncov2019-artic-nf/  --illumina --directory $workingdir --prefix "$runname" -profile conda --cache /data/encrypted/scratch/ --ref /data/tools/primer-schemes/nCoV-2019/V4/SARS-CoV-2.reference.fasta --bed /data/tools/primer-schemes/nCoV-2019/V4/SARS-CoV-2.primer.bed
	
	# move outputs and reset input folder structure
	mv $workingdir/results/* $outdir
	mv $workingdir/work /data/encrypted/scratch/$runname
	mv $workingdir $run/Analysis/1/Data/fastq

	# activate ncov-qc environment using conda as it was initiated when source activated previously
	conda activate /data/tools/miniconda3/envs/ncov-qc/
	workingdir="/data/encrypted/workingdir/scratch/qc/"
	mkdir $workingdir
	cd $workingdir
	inputdir=`echo $workingdir"inputs"`
	mkdir $inputdir

	# move and prep files for ncov-qc
	cp $outdir/ncovIllumina_sequenceAnalysis_makeConsensus/* $inputdir
	cp $outdir/ncovIllumina_sequenceAnalysis_callVariants/* $inputdir
	cp $outdir/ncovIllumina_sequenceAnalysis_trimPrimerSequences/* $inputdir

	# get list of negatives
	for sample in $inputdir/*consensus*
	do
		if echo "$sample" | grep -a "neg" > /dev/null
		then
			new=`echo $sample | rev | cut -d'/' -f1 | rev | cut -d'.' -f1`
			echo "\""$new"\""
		elif echo "$sample" | grep -a "Neg" > /dev/null
		then
			new=`echo $sample | rev | cut -d'/' -f1 | rev | cut -d'.' -f1`
			echo "\""$new"\""
		elif echo "$sample" | grep -a "NEG" > /dev/null
		then
			new=`echo $sample | rev | cut -d'/' -f1 | rev | cut -d'.' -f1`
			echo "\""$new"\""
		fi
	done | sort | uniq > temp.txt
	negatives=`tr '\n' ',' < temp.txt | sed "s/,$/ \]/g" | sed "s/^/negative_control_samples\: \[ /g"`
	rm ./temp.txt

	# prepping config file
	sed "s/GGC_Validation/$runname/g" /data/tools/config.illumina | sed "s/inputs/\/data\/encrypted\/workingdir\/scratch\/qc\/inputs/g" | sed "s/\#negatives/$negatives/g"> $workingdir/config.yaml
	
	# determining number of samples and assigning core and RAM count
	count=`ls -lh $inputdir/*.fa | wc -l`
	if [ $count == "384" ]
	then
		cores="60"
		sed -i "s/2G/2G/g" /data/tools/ncov-tools/workflow/rules/sequencing.smk
	elif [ $count == "96" ]
	then
		cores="8"
		sed -i "s/2G/15G/g" /data/tools/ncov-tools/workflow/rules/sequencing.smk		
	elif [ $count == "192" ]
	then
		cores="16"
		sed -i "s/2G/7G/g" /data/tools/ncov-tools/workflow/rules/sequencing.smk
	else
		cores="8"
		sed -i "s/2G/15G/g" /data/tools/ncov-tools/workflow/rules/sequencing.smk				
	fi				

	# run ncov-qc
	snakemake -s /data/tools/ncov-tools/workflow/Snakefile all_qc_reports --cores $cores

	# clean up
	mv $inputdir /data/encrypted/scratch/$runname/qc_inputs
	sed -i "s/15G/2G/g" /data/tools/ncov-tools/workflow/rules/sequencing.smk	
	sed -i "s/7G/2G/g" /data/tools/ncov-tools/workflow/rules/sequencing.smk

	# create Output directory with all files for Lab (full files are in result)
	fullname=`echo $ggcname"_"$runname`
	output=`echo "/data/encrypted/outputs/"$fullname`
	mkdir $output
	mv $workingdir/qc_reports/* $output
	mkdir $output/all_fasta
	cp /data/encrypted/scratch/$runname/qc_inputs/*.fa $output/all_fasta/
	mv $workingdir $outdir

	# when all done mv input folder and send file to ssftp where NAS box will pull from periodically
	mv $run /data/encrypted/completed/

done

#curl -X POST \
#        -H "Content-Type: application/json" \
#        -d '{ "secret": "xE6qCqHPlgBVrwnpiztEhY1XRFxlNrFc6rUdQXdhKJMVNIAkrXaQ2iO0MZfa6iLY" }' \
#        'https://prod-18.uksouth.logic.azure.com:443/workflows/1d0b47e4719a42e4a107020dbb89bc1a/triggers/request/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Frequest%2Frun&sv=1.0&sig=FqKulgmoo_mYfz5R3tSVTrUQz24TRzuK9TEAKm5pEWM'
